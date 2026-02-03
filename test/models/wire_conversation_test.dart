import 'package:flutter_test/flutter_test.dart';
import 'package:vespara/core/domain/models/wire_conversation.dart';

void main() {
  group('WireConversation', () {
    test('fromJson creates valid conversation object', () {
      final json = {
        'id': 'conv-123',
        'user_id': 'user-123',
        'match_link_id': 'match-123',
        'conversation_type': 'direct',
        'last_message': 'Hello there!',
        'last_message_at': '2026-01-28T12:00:00.000Z',
        'last_message_by': 'user-456',
        'unread_count': 3,
        'is_muted': false,
        'is_pinned': true,
        'is_archived': false,
        'participant_count': 2,
        'created_at': '2026-01-27T10:00:00.000Z',
        'updated_at': '2026-01-28T12:00:00.000Z',
      };

      final conversation = WireConversation.fromJson(json);

      expect(conversation.id, 'conv-123');
      expect(conversation.userId, 'user-123');
      expect(conversation.conversationType, 'direct');
      expect(conversation.lastMessage, 'Hello there!');
      expect(conversation.unreadCount, 3);
      expect(conversation.isPinned, true);
      expect(conversation.isMuted, false);
      expect(conversation.isArchived, false);
    });

    test('isDirect returns true for direct conversations', () {
      final directConv = WireConversation(
        id: '1',
        userId: 'user-1',
        conversationType: 'direct',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(directConv.isDirect, true);
      expect(directConv.isGroup, false);
    });

    test('isGroup returns true for group conversations', () {
      final groupConv = WireConversation(
        id: '1',
        userId: 'user-1',
        conversationType: 'group',
        groupName: 'Test Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(groupConv.isGroup, true);
      expect(groupConv.isDirect, false);
    });

    test('hasUnread returns true when unread_count > 0', () {
      final unreadConv = WireConversation(
        id: '1',
        userId: 'user-1',
        conversationType: 'direct',
        unreadCount: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final readConv = WireConversation(
        id: '2',
        userId: 'user-1',
        conversationType: 'direct',
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(unreadConv.hasUnread, true);
      expect(readConv.hasUnread, false);
    });
  });
}
