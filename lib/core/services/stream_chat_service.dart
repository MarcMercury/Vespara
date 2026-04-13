import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../config/env.dart';

/// Stream Chat Service - Manages the Stream Chat client connection
/// Used for 1:1 messaging, group chats, media sharing, reactions, etc.
class StreamChatService {
  StreamChatService._();

  static StreamChatClient? _client;

  /// Get the Stream Chat client (lazy singleton)
  static StreamChatClient get client {
    _client ??= StreamChatClient(
      Env.streamChatApiKey,
      logLevel: Level.WARNING,
    );
    return _client!;
  }

  /// Connect the current user to Stream Chat
  /// Call this after Supabase auth succeeds and MFA is verified
  /// The [token] must be generated server-side via Supabase Edge Function
  static Future<void> connectUser({
    required String userId,
    required String displayName,
    String? avatarUrl,
    required String token,
  }) async {
    await client.connectUser(
      User(
        id: userId,
        extraData: {
          'name': displayName,
          if (avatarUrl != null) 'image': avatarUrl,
        },
      ),
      token,
    );
  }

  /// Disconnect the user (call on sign out)
  static Future<void> disconnectUser() async {
    await _client?.disconnectUser();
  }

  /// Create a 1:1 channel between two users
  static Channel createDirectChannel({
    required String currentUserId,
    required String otherUserId,
  }) {
    return client.channel(
      'messaging',
      extraData: {
        'members': [currentUserId, otherUserId],
      },
    );
  }

  /// Create a group channel
  static Channel createGroupChannel({
    required String name,
    required List<String> memberIds,
    String? imageUrl,
    String? description,
  }) {
    return client.channel(
      'messaging',
      extraData: {
        'name': name,
        'members': memberIds,
        if (imageUrl != null) 'image': imageUrl,
        if (description != null) 'description': description,
      },
    );
  }

  /// Dispose the client (app shutdown)
  static void dispose() {
    _client?.dispose();
    _client = null;
  }
}
