import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/wire_models.dart';

// ============================================================================
// WIRE STATE
// ============================================================================

class WireState {
  const WireState({
    this.conversations = const [],
    this.messagesByConversation = const {},
    this.participantsByConversation = const {},
    this.activeConversationId,
    this.isLoading = false,
    this.error,
    this.typingByConversation = const {},
  });
  final List<WireConversation> conversations;
  final Map<String, List<WireMessage>> messagesByConversation;
  final Map<String, List<ConversationParticipant>> participantsByConversation;
  final String? activeConversationId;
  final bool isLoading;
  final String? error;
  final Map<String, List<TypingUser>> typingByConversation;

  /// Get all non-archived conversations sorted by last message time
  List<WireConversation> get activeConversations {
    final active = conversations.where((c) => !c.isArchived).toList();
    active.sort((a, b) {
      // Pinned first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Then by pin order
      if (a.isPinned && b.isPinned) {
        return a.pinOrder.compareTo(b.pinOrder);
      }
      // Then by last message time
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return active;
  }

  /// Get archived conversations
  List<WireConversation> get archivedConversations =>
      conversations.where((c) => c.isArchived).toList();

  /// Get group conversations only
  List<WireConversation> get groupConversations =>
      activeConversations.where((c) => c.isGroup).toList();

  /// Get direct conversations only
  List<WireConversation> get directConversations =>
      activeConversations.where((c) => !c.isGroup).toList();

  /// Get total unread count
  int get totalUnreadCount =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  /// Get messages for current active conversation
  List<WireMessage> get activeMessages {
    if (activeConversationId == null) return [];
    return messagesByConversation[activeConversationId] ?? [];
  }

  /// Get participants for current active conversation
  List<ConversationParticipant> get activeParticipants {
    if (activeConversationId == null) return [];
    return participantsByConversation[activeConversationId] ?? [];
  }

  /// Get typing users for current active conversation
  List<TypingUser> get activeTypingUsers {
    if (activeConversationId == null) return [];
    return typingByConversation[activeConversationId] ?? [];
  }

  WireState copyWith({
    List<WireConversation>? conversations,
    Map<String, List<WireMessage>>? messagesByConversation,
    Map<String, List<ConversationParticipant>>? participantsByConversation,
    String? activeConversationId,
    bool clearActiveConversation = false,
    bool? isLoading,
    String? error,
    Map<String, List<TypingUser>>? typingByConversation,
  }) =>
      WireState(
        conversations: conversations ?? this.conversations,
        messagesByConversation:
            messagesByConversation ?? this.messagesByConversation,
        participantsByConversation:
            participantsByConversation ?? this.participantsByConversation,
        activeConversationId: clearActiveConversation 
            ? null 
            : (activeConversationId ?? this.activeConversationId),
        isLoading: isLoading ?? this.isLoading,
        error: error,
        typingByConversation: typingByConversation ?? this.typingByConversation,
      );
}

// ============================================================================
// WIRE NOTIFIER
// ============================================================================

class WireNotifier extends StateNotifier<WireState> {
  WireNotifier(this._supabase, this._currentUserId) : super(const WireState()) {
    _initialize();
  }
  final SupabaseClient _supabase;
  final String _currentUserId;

  /// Get the current user's ID
  String get currentUserId => _currentUserId;

  // Realtime subscriptions
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _typingChannel;
  Timer? _typingTimer;

  Future<void> _initialize() async {
    await loadConversations();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _typingTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Load all conversations for current user
  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);

    try {
      // Get conversations where user is a participant
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            conversation_participants!inner(
              user_id,
              role,
              unread_count,
              last_read_at,
              is_muted,
              is_active
            )
          ''')
          .eq('conversation_participants.user_id', _currentUserId)
          .eq('conversation_participants.is_active', true)
          .order('last_message_at', ascending: false);

      final conversations = (response as List<dynamic>)
          .map(
              (json) => WireConversation.fromJson(json as Map<String, dynamic>),)
          .toList();

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversations',
      );
    }
  }

  /// Create a new group conversation
  Future<String?> createGroup({
    required String groupName,
    required List<String> participantIds,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final result = await _supabase.rpc(
        'create_group_conversation',
        params: {
          'p_creator_id': _currentUserId,
          'p_group_name': groupName,
          'p_participant_ids': participantIds,
          'p_group_avatar_url': avatarUrl,
          'p_group_description': description,
        },
      );

      final conversationId = result as String;
      await loadConversations();
      return conversationId;
    } catch (e) {
      debugPrint('Error creating group: $e');
      state = state.copyWith(error: 'Failed to create group');
      return null;
    }
  }

  /// Create or get direct conversation with another user
  Future<String?> getOrCreateDirectConversation(String otherUserId) async {
    // Validate user is authenticated
    if (_currentUserId.isEmpty) {
      debugPrint('Error: Cannot create conversation - user not authenticated');
      return null;
    }
    
    // Validate other user ID
    if (otherUserId.isEmpty) {
      debugPrint('Error: Cannot create conversation - invalid other user ID');
      return null;
    }

    try {
      // Check if conversation already exists in local state
      final existing = state.conversations.firstWhere(
        (c) => !c.isGroup && c.matchId == otherUserId,
        orElse: () => WireConversation(
          id: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existing.id.isNotEmpty) {
        return existing.id;
      }

      // Check if conversation exists in database (might not be loaded yet)
      final existingInDb = await _supabase
          .from('conversations')
          .select('id')
          .eq('user_id', _currentUserId)
          .eq('match_id', otherUserId)
          .eq('conversation_type', 'direct')
          .maybeSingle();
      
      if (existingInDb != null && existingInDb['id'] != null) {
        final existingId = existingInDb['id'] as String;
        await loadConversations(); // Refresh local state
        return existingId;
      }

      // Create new direct conversation
      final response = await _supabase
          .from('conversations')
          .insert({
            'user_id': _currentUserId,
            'conversation_type': 'direct',
            'match_id': otherUserId,
          })
          .select()
          .single();

      final conversationId = response['id'] as String;

      // Add both participants
      await _supabase.from('conversation_participants').insert([
        {
          'conversation_id': conversationId,
          'user_id': _currentUserId,
          'role': 'member',
        },
        {
          'conversation_id': conversationId,
          'user_id': otherUserId,
          'role': 'member',
        },
      ]);

      await loadConversations();
      return conversationId;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      state = state.copyWith(error: 'Failed to create conversation: $e');
      return null;
    }
  }

  /// Set the active conversation and load its messages
  Future<void> openConversation(String conversationId) async {
    state = state.copyWith(activeConversationId: conversationId);

    await Future.wait([
      loadMessages(conversationId),
      loadParticipants(conversationId),
      markAsRead(conversationId),
    ]);
  }

  /// Close the active conversation
  void closeConversation() {
    state = state.copyWith(clearActiveConversation: true);
  }

  /// Archive a conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      await _supabase.from('conversations').update({
        'is_archived': true,
        'archived_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      final updated = state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(isArchived: true, archivedAt: DateTime.now());
        }
        return c;
      }).toList();

      state = state.copyWith(conversations: updated);
    } catch (e) {
      debugPrint('Error archiving conversation: $e');
    }
  }

  /// Unarchive a conversation
  Future<void> unarchiveConversation(String conversationId) async {
    try {
      await _supabase.from('conversations').update({
        'is_archived': false,
        'archived_at': null,
      }).eq('id', conversationId);

      final updated = state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(isArchived: false);
        }
        return c;
      }).toList();

      state = state.copyWith(conversations: updated);
    } catch (e) {
      debugPrint('Error unarchiving conversation: $e');
    }
  }

  /// Delete a conversation permanently
  Future<void> deleteConversation(String conversationId) async {
    // Remove from local state first (optimistic)
    final updated = state.conversations
        .where((c) => c.id != conversationId)
        .toList();
    state = state.copyWith(conversations: updated);

    try {
      // Delete messages first (cascade should handle this, but be explicit)
      await _supabase
          .from('messages')
          .delete()
          .eq('conversation_id', conversationId);

      // Delete participants
      await _supabase
          .from('conversation_participants')
          .delete()
          .eq('conversation_id', conversationId);

      // Delete the conversation
      await _supabase
          .from('conversations')
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      // Restore on failure
      await loadConversations();
      rethrow;
    }
  }

  /// Block a user and delete/hide conversation
  Future<void> blockUser(String userId, String conversationId) async {
    if (userId.isEmpty) {
      debugPrint('Cannot block: empty user ID');
      return;
    }

    try {
      // Add to blocked_users table
      await _supabase.from('blocked_users').insert({
        'blocker_id': _currentUserId,
        'blocked_id': userId,
        'blocked_at': DateTime.now().toIso8601String(),
      });

      // Archive/hide the conversation
      await archiveConversation(conversationId);

      // Remove from local state
      final updated = state.conversations
          .where((c) => c.id != conversationId)
          .toList();
      state = state.copyWith(conversations: updated);
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  /// Pin/unpin a conversation
  Future<void> togglePin(String conversationId) async {
    final conversation =
        state.conversations.firstWhere((c) => c.id == conversationId);
    final newPinned = !conversation.isPinned;

    try {
      await _supabase
          .from('conversations')
          .update({'is_pinned': newPinned}).eq('id', conversationId);

      final updated = state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(isPinned: newPinned);
        }
        return c;
      }).toList();

      state = state.copyWith(conversations: updated);
    } catch (e) {
      debugPrint('Error toggling pin: $e');
    }
  }

  /// Mute/unmute a conversation
  Future<void> toggleMute(String conversationId, {Duration? duration}) async {
    final participant = await _supabase
        .from('conversation_participants')
        .select()
        .eq('conversation_id', conversationId)
        .eq('user_id', _currentUserId)
        .single();

    final currentlyMuted = participant['is_muted'] as bool? ?? false;
    final newMuted = !currentlyMuted;

    try {
      await _supabase
          .from('conversation_participants')
          .update({
            'is_muted': newMuted,
            'muted_until': duration != null
                ? DateTime.now().add(duration).toIso8601String()
                : null,
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', _currentUserId);

      final updated = state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(
            isMuted: newMuted,
            mutedUntil: duration != null ? DateTime.now().add(duration) : null,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(conversations: updated);
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ══════════════════════════════════════════════════════════════════════════

  /// Load messages for a conversation
  Future<void> loadMessages(String conversationId,
      {int limit = 50, String? before,}) async {
    try {
      final baseQuery = _supabase.from('messages').select('''
            *,
            profiles:sender_id(display_name, avatar_url)
          ''').eq('conversation_id', conversationId);

      final filteredQuery =
          before != null ? baseQuery.lt('created_at', before) : baseQuery;

      final response = await filteredQuery
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = (response as List<dynamic>)
          .map((json) => WireMessage.fromJson(json as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();

      final existingMessages =
          state.messagesByConversation[conversationId] ?? [];
      final allMessages =
          before != null ? [...messages, ...existingMessages] : messages;

      state = state.copyWith(
        messagesByConversation: {
          ...state.messagesByConversation,
          conversationId: allMessages,
        },
      );
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /// Send a text message
  Future<WireMessage?> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    final clientMessageId = const Uuid().v4();
    final optimisticMessage = WireMessage(
      id: clientMessageId,
      conversationId: conversationId,
      senderId: _currentUserId,
      content: content,
      status: MessageStatus.sending,
      clientMessageId: clientMessageId,
      replyToId: replyToId,
      createdAt: DateTime.now(),
    );

    // Optimistic update
    _addOptimisticMessage(conversationId, optimisticMessage);

    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': _currentUserId,
            'content': content,
            'message_type': 'text',
            'reply_to_id': replyToId,
            'client_message_id': clientMessageId,
          })
          .select()
          .single();

      final message = WireMessage.fromJson(response);
      _replaceOptimisticMessage(conversationId, clientMessageId, message);
      return message;
    } catch (e) {
      debugPrint('Error sending message: $e');
      _markMessageFailed(conversationId, clientMessageId);
      return null;
    }
  }

  /// Send a media message (image, video, voice, file)
  Future<WireMessage?> sendMediaMessage({
    required String conversationId,
    required Uint8List fileBytes,
    required String filename,
    required MessageType type,
    String? caption,
    String? replyToId,
    List<double>? waveform, // For voice notes
  }) async {
    final clientMessageId = const Uuid().v4();

    // Create optimistic message
    final optimisticMessage = WireMessage(
      id: clientMessageId,
      conversationId: conversationId,
      senderId: _currentUserId,
      content: caption,
      type: type,
      status: MessageStatus.sending,
      mediaFilename: filename,
      clientMessageId: clientMessageId,
      replyToId: replyToId,
      createdAt: DateTime.now(),
    );

    _addOptimisticMessage(conversationId, optimisticMessage);

    try {
      // Upload file to storage
      final storagePath =
          '$_currentUserId/$conversationId/$clientMessageId-$filename';
      await _supabase.storage.from('chat-media').uploadBinary(storagePath, fileBytes);

      final mediaUrl =
          _supabase.storage.from('chat-media').getPublicUrl(storagePath);

      // Get file metadata
      final fileSizeBytes = fileBytes.length;

      // Create message
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': _currentUserId,
            'content': caption,
            'message_type': type.name,
            'media_url': mediaUrl,
            'media_filename': filename,
            'media_filesize_bytes': fileSizeBytes,
            'media_waveform': waveform,
            'reply_to_id': replyToId,
            'client_message_id': clientMessageId,
          })
          .select()
          .single();

      final message = WireMessage.fromJson(response);
      _replaceOptimisticMessage(conversationId, clientMessageId, message);
      return message;
    } catch (e) {
      debugPrint('Error sending media message: $e');
      _markMessageFailed(conversationId, clientMessageId);
      return null;
    }
  }

  /// Send a voice note
  Future<WireMessage?> sendVoiceNote({
    required String conversationId,
    required Uint8List audioBytes,
    required String filename,
    required int durationSeconds,
    List<double>? waveform,
    String? replyToId,
  }) async =>
      sendMediaMessage(
        conversationId: conversationId,
        fileBytes: audioBytes,
        filename: filename,
        type: MessageType.voice,
        replyToId: replyToId,
        waveform: waveform,
      );

  /// Send a location
  Future<WireMessage?> sendLocation({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? name,
    String? address,
    String? replyToId,
  }) async {
    final clientMessageId = const Uuid().v4();

    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': _currentUserId,
            'message_type': 'location',
            'location_lat': latitude,
            'location_lng': longitude,
            'location_name': name,
            'location_address': address,
            'reply_to_id': replyToId,
            'client_message_id': clientMessageId,
          })
          .select()
          .single();

      final message = WireMessage.fromJson(response);
      _addMessageToState(conversationId, message);
      return message;
    } catch (e) {
      debugPrint('Error sending location: $e');
      return null;
    }
  }

  /// Edit a message
  Future<bool> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', _currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage({
    required String messageId,
    required String conversationId,
    bool forEveryone = false,
  }) async {
    try {
      if (forEveryone) {
        await _supabase
            .from('messages')
            .update({
              'is_deleted': true,
              'deleted_at': DateTime.now().toIso8601String(),
              'deleted_for_everyone': true,
              'content': null,
              'media_url': null,
            })
            .eq('id', messageId)
            .eq('sender_id', _currentUserId);
      } else {
        // Just mark as deleted for self - store in metadata
        await _supabase.from('messages').update({
          'metadata': {
            'deleted_for': [_currentUserId],
          },
        }).eq('id', messageId);
      }

      // Remove from state
      final messages = state.messagesByConversation[conversationId] ?? [];
      final updated = messages.where((m) => m.id != messageId).toList();
      state = state.copyWith(
        messagesByConversation: {
          ...state.messagesByConversation,
          conversationId: updated,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// Add a reaction to a message
  Future<bool> addReaction({
    required String messageId,
    required String conversationId,
    required String emoji,
  }) async {
    try {
      // Get current reactions
      final response = await _supabase
          .from('messages')
          .select('reactions')
          .eq('id', messageId)
          .single();

      final reactions = (response['reactions'] as List<dynamic>? ?? [])
          .map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
          .toList();

      // Find existing reaction with this emoji
      final existingIndex = reactions.indexWhere((r) => r.emoji == emoji);

      if (existingIndex >= 0) {
        final existing = reactions[existingIndex];
        if (!existing.userIds.contains(_currentUserId)) {
          // Add user to existing reaction
          final updatedReaction = MessageReaction(
            emoji: emoji,
            userIds: [...existing.userIds, _currentUserId],
          );
          reactions[existingIndex] = updatedReaction;
        }
      } else {
        // Add new reaction
        reactions.add(
          MessageReaction(
            emoji: emoji,
            userIds: [_currentUserId],
          ),
        );
      }

      await _supabase.from('messages').update({
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'reaction_count': reactions.fold(0, (sum, r) => sum + r.count),
      }).eq('id', messageId);

      return true;
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      return false;
    }
  }

  /// Remove a reaction from a message
  Future<bool> removeReaction({
    required String messageId,
    required String conversationId,
    required String emoji,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('reactions')
          .eq('id', messageId)
          .single();

      final reactions = (response['reactions'] as List<dynamic>? ?? [])
          .map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
          .toList();

      final existingIndex = reactions.indexWhere((r) => r.emoji == emoji);

      if (existingIndex >= 0) {
        final existing = reactions[existingIndex];
        final updatedUserIds =
            existing.userIds.where((id) => id != _currentUserId).toList();

        if (updatedUserIds.isEmpty) {
          reactions.removeAt(existingIndex);
        } else {
          reactions[existingIndex] = MessageReaction(
            emoji: emoji,
            userIds: updatedUserIds,
          );
        }
      }

      await _supabase.from('messages').update({
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'reaction_count': reactions.fold(0, (sum, r) => sum + r.count),
      }).eq('id', messageId);

      return true;
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      return false;
    }
  }

  /// Star/unstar a message
  Future<void> toggleStarMessage(
      String messageId, String conversationId,) async {
    final messages = state.messagesByConversation[conversationId] ?? [];
    final message = messages.firstWhere((m) => m.id == messageId);
    final isStarred = message.starredBy.contains(_currentUserId);

    try {
      if (isStarred) {
        await _supabase
            .from('starred_messages')
            .delete()
            .eq('user_id', _currentUserId)
            .eq('message_id', messageId);
      } else {
        await _supabase.from('starred_messages').insert({
          'user_id': _currentUserId,
          'message_id': messageId,
        });
      }

      final updatedMessages = messages.map((m) {
        if (m.id == messageId) {
          final newStarredBy = isStarred
              ? m.starredBy.where((id) => id != _currentUserId).toList()
              : [...m.starredBy, _currentUserId];
          return m.copyWith(starredBy: newStarredBy);
        }
        return m;
      }).toList();

      state = state.copyWith(
        messagesByConversation: {
          ...state.messagesByConversation,
          conversationId: updatedMessages,
        },
      );
    } catch (e) {
      debugPrint('Error toggling star: $e');
    }
  }

  /// Forward a message to another conversation
  Future<WireMessage?> forwardMessage({
    required String messageId,
    required String toConversationId,
  }) async {
    try {
      // Get original message
      final original = await _supabase
          .from('messages')
          .select()
          .eq('id', messageId)
          .single();

      // Create forwarded message
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': toConversationId,
            'sender_id': _currentUserId,
            'content': original['content'],
            'message_type': original['message_type'],
            'media_url': original['media_url'],
            'media_filename': original['media_filename'],
            'forwarded_from_id': messageId,
          })
          .select()
          .single();

      // Update forward count on original
      await _supabase.rpc(
        'increment',
        params: {
          'row_id': messageId,
          'table_name': 'messages',
          'column_name': 'forward_count',
        },
      );

      return WireMessage.fromJson(response);
    } catch (e) {
      debugPrint('Error forwarding message: $e');
      return null;
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _supabase.rpc(
        'mark_messages_read',
        params: {
          'p_conversation_id': conversationId,
          'p_user_id': _currentUserId,
        },
      );

      final updated = state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(unreadCount: 0, lastReadAt: DateTime.now());
        }
        return c;
      }).toList();

      state = state.copyWith(conversations: updated);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PARTICIPANTS (Group management)
  // ══════════════════════════════════════════════════════════════════════════

  /// Load participants for a conversation
  Future<void> loadParticipants(String conversationId) async {
    try {
      final response =
          await _supabase.from('conversation_participants').select('''
            *,
            profiles:user_id(display_name, avatar_url)
          ''').eq('conversation_id', conversationId).eq('is_active', true);

      final participants = (response as List<dynamic>)
          .map((json) =>
              ConversationParticipant.fromJson(json as Map<String, dynamic>),)
          .toList();

      state = state.copyWith(
        participantsByConversation: {
          ...state.participantsByConversation,
          conversationId: participants,
        },
      );
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }
  }

  /// Add participants to a group
  Future<bool> addParticipants(
      String conversationId, List<String> userIds,) async {
    try {
      for (final userId in userIds) {
        await _supabase.rpc(
          'add_group_participant',
          params: {
            'p_conversation_id': conversationId,
            'p_new_user_id': userId,
            'p_added_by': _currentUserId,
          },
        );
      }

      await loadParticipants(conversationId);
      return true;
    } catch (e) {
      debugPrint('Error adding participants: $e');
      return false;
    }
  }

  /// Remove a participant from a group
  Future<bool> removeParticipant(String conversationId, String userId) async {
    try {
      await _supabase
          .from('conversation_participants')
          .update({
            'is_active': false,
            'left_at': DateTime.now().toIso8601String(),
            'removed_by': _currentUserId,
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);

      // Create system message
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _currentUserId,
        'message_type': 'system',
        'content': 'removed a participant',
      });

      await loadParticipants(conversationId);
      return true;
    } catch (e) {
      debugPrint('Error removing participant: $e');
      return false;
    }
  }

  /// Make a participant an admin
  Future<bool> makeAdmin(String conversationId, String userId) async {
    try {
      await _supabase
          .from('conversation_participants')
          .update({
            'role': 'admin',
            'can_add_members': true,
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);

      await loadParticipants(conversationId);
      return true;
    } catch (e) {
      debugPrint('Error making admin: $e');
      return false;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String conversationId) async {
    try {
      await _supabase
          .from('conversation_participants')
          .update({
            'is_active': false,
            'left_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', _currentUserId);

      await loadConversations();
      return true;
    } catch (e) {
      debugPrint('Error leaving group: $e');
      return false;
    }
  }

  /// Update group info (name, description, avatar)
  Future<bool> updateGroupInfo(
    String conversationId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['group_name'] = name;
      if (description != null) updates['group_description'] = description;
      if (avatarUrl != null) updates['group_avatar_url'] = avatarUrl;

      if (updates.isEmpty) return true;

      await _supabase
          .from('conversations')
          .update(updates)
          .eq('id', conversationId);

      await loadConversations();
      return true;
    } catch (e) {
      debugPrint('Error updating group info: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TYPING INDICATORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Start typing indicator
  void startTyping(String conversationId) {
    _typingTimer?.cancel();

    _supabase.from('typing_indicators').upsert({
      'conversation_id': conversationId,
      'user_id': _currentUserId,
      'started_at': DateTime.now().toIso8601String(),
    });

    // Auto-stop after 5 seconds
    _typingTimer = Timer(const Duration(seconds: 5), () {
      stopTyping(conversationId);
    });
  }

  /// Stop typing indicator
  void stopTyping(String conversationId) {
    _typingTimer?.cancel();

    _supabase
        .from('typing_indicators')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', _currentUserId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REALTIME SUBSCRIPTIONS
  // ══════════════════════════════════════════════════════════════════════════

  void _subscribeToRealtime() {
    // Subscribe to new messages for user's conversations
    _messagesChannel = _supabase
        .channel('wire-messages-$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMessage = WireMessage.fromJson(payload.newRecord);
            // Only process if this conversation belongs to user
            final isUserConversation = state.conversations
                .any((c) => c.id == newMessage.conversationId);
            if (isUserConversation) {
              _handleNewMessage(newMessage);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final updatedMessage = WireMessage.fromJson(payload.newRecord);
            // Only process if this conversation belongs to user
            final isUserConversation = state.conversations
                .any((c) => c.id == updatedMessage.conversationId);
            if (isUserConversation) {
              _handleUpdatedMessage(updatedMessage);
            }
          },
        )
        .subscribe();

    // Subscribe to typing indicators
    _typingChannel = _supabase
        .channel('wire-typing-$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'typing_indicators',
          callback: _handleTypingChange,
        )
        .subscribe();
  }

  void _handleNewMessage(WireMessage message) {
    // Skip if from self (already added optimistically)
    if (message.senderId == _currentUserId) return;

    _addMessageToState(message.conversationId, message);

    // Update conversation's last message
    final updated = state.conversations.map((c) {
      if (c.id == message.conversationId) {
        return c.copyWith(
          lastMessage: message.previewText,
          lastMessageAt: message.createdAt,
          lastMessageSenderId: message.senderId,
          lastMessageType: message.type,
          unreadCount:
              c.id == state.activeConversationId ? 0 : c.unreadCount + 1,
        );
      }
      return c;
    }).toList();

    state = state.copyWith(conversations: updated);
  }

  void _handleUpdatedMessage(WireMessage message) {
    final messages = state.messagesByConversation[message.conversationId] ?? [];
    final updatedMessages = messages.map((m) {
      if (m.id == message.id) return message;
      return m;
    }).toList();

    state = state.copyWith(
      messagesByConversation: {
        ...state.messagesByConversation,
        message.conversationId: updatedMessages,
      },
    );
  }

  void _handleTypingChange(PostgresChangePayload payload) {
    // Handle typing indicator changes
    if (payload.eventType == PostgresChangeEvent.delete) {
      // User stopped typing - remove from state
      final conversationId = payload.oldRecord['conversation_id'] as String?;
      final userId = payload.oldRecord['user_id'] as String?;
      if (conversationId == null || userId == null) return;
      
      // Only update if this is a conversation we're tracking
      final isUserConversation = state.conversations
          .any((c) => c.id == conversationId);
      if (!isUserConversation) return;
      
      final currentTyping = state.typingByConversation[conversationId] ?? [];
      final updated = currentTyping.where((t) => t.id != userId).toList();
      state = state.copyWith(
        typingByConversation: {
          ...state.typingByConversation,
          conversationId: updated,
        },
      );
    } else if (payload.eventType == PostgresChangeEvent.insert) {
      // User started typing - add to state
      final conversationId = payload.newRecord['conversation_id'] as String?;
      final userId = payload.newRecord['user_id'] as String?;
      if (conversationId == null || userId == null) return;
      
      // Don't show own typing indicator
      if (userId == _currentUserId) return;
      
      // Only update if this is a conversation we're tracking
      final isUserConversation = state.conversations
          .any((c) => c.id == conversationId);
      if (!isUserConversation) return;
      
      // Create typing user entry
      final typingUser = TypingUser(
        id: userId,
        name: 'Someone', // Would need to fetch actual name
        startedAt: DateTime.now(),
      );
      
      final currentTyping = state.typingByConversation[conversationId] ?? [];
      // Avoid duplicates
      if (currentTyping.any((t) => t.id == userId)) return;
      
      state = state.copyWith(
        typingByConversation: {
          ...state.typingByConversation,
          conversationId: [...currentTyping, typingUser],
        },
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════

  void _addOptimisticMessage(String conversationId, WireMessage message) {
    final messages = state.messagesByConversation[conversationId] ?? [];
    state = state.copyWith(
      messagesByConversation: {
        ...state.messagesByConversation,
        conversationId: [...messages, message],
      },
    );
  }

  void _replaceOptimisticMessage(
    String conversationId,
    String clientMessageId,
    WireMessage realMessage,
  ) {
    final messages = state.messagesByConversation[conversationId] ?? [];
    final updated = messages.map((m) {
      if (m.clientMessageId == clientMessageId) return realMessage;
      return m;
    }).toList();

    state = state.copyWith(
      messagesByConversation: {
        ...state.messagesByConversation,
        conversationId: updated,
      },
    );
  }

  void _markMessageFailed(String conversationId, String clientMessageId) {
    final messages = state.messagesByConversation[conversationId] ?? [];
    final updated = messages.map((m) {
      if (m.clientMessageId == clientMessageId) {
        return m.copyWith(status: MessageStatus.failed);
      }
      return m;
    }).toList();

    state = state.copyWith(
      messagesByConversation: {
        ...state.messagesByConversation,
        conversationId: updated,
      },
    );
  }

  void _addMessageToState(String conversationId, WireMessage message) {
    final messages = state.messagesByConversation[conversationId] ?? [];

    // Check if message already exists
    if (messages.any((m) => m.id == message.id)) return;

    state = state.copyWith(
      messagesByConversation: {
        ...state.messagesByConversation,
        conversationId: [...messages, message],
      },
    );
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final wireProvider = StateNotifierProvider<WireNotifier, WireState>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    // Return a notifier that won't load data until user is authenticated
    return WireNotifier(supabase, '');
  }
  return WireNotifier(supabase, userId);
});

/// Provider for active conversation messages
final activeMessagesProvider = Provider<List<WireMessage>>(
    (ref) => ref.watch(wireProvider).activeMessages,);

/// Provider for active conversation participants
final activeParticipantsProvider = Provider<List<ConversationParticipant>>(
    (ref) => ref.watch(wireProvider).activeParticipants,);

/// Provider for conversation list (Wire-specific)
final wireConversationsProvider = Provider<List<WireConversation>>(
    (ref) => ref.watch(wireProvider).activeConversations,);

/// Provider for group conversations only
final groupConversationsProvider = Provider<List<WireConversation>>(
    (ref) => ref.watch(wireProvider).groupConversations,);

/// Provider for total unread count
final totalUnreadProvider =
    Provider<int>((ref) => ref.watch(wireProvider).totalUnreadCount);
