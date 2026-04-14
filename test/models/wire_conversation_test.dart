import 'package:flutter_test/flutter_test.dart';
import 'package:vespara/core/domain/models/wire_models.dart';

void main() {
  group('WireConversation', () {
    test('fromJson creates valid conversation object', () {
      final json = {
        'id': 'conv-123',
        'conversation_type': 'direct',
        'last_message': 'Hello there!',
        'last_message_at': '2026-01-28T12:00:00.000Z',
        'last_message_sender_id': 'user-456',
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
      expect(conversation.lastMessage, 'Hello there!');
      expect(conversation.unreadCount, 3);
      expect(conversation.isPinned, true);
      expect(conversation.isMuted, false);
      expect(conversation.isArchived, false);
    });

    test('isGroup returns true for group conversations', () {
      final groupConv = WireConversation(
        id: '1',
        type: ConversationType.group,
        groupName: 'Test Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(groupConv.isGroup, true);
    });

    test('isGroup returns false for direct conversations', () {
      final directConv = WireConversation(
        id: '1',
        type: ConversationType.direct,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(directConv.isGroup, false);
    });
  });
}
