import 'package:flutter_test/flutter_test.dart';
import 'package:vespara/core/domain/models/match.dart';

void main() {
  group('MatchPriority', () {
    test('fromString returns correct priority', () {
      expect(MatchPriority.fromString('priority'), MatchPriority.priority);
      expect(MatchPriority.fromString('inWaiting'), MatchPriority.inWaiting);
      expect(MatchPriority.fromString('onWayOut'), MatchPriority.onWayOut);
      expect(MatchPriority.fromString('legacy'), MatchPriority.legacy);
      expect(MatchPriority.fromString('unknown'), MatchPriority.new_);
      expect(MatchPriority.fromString(null), MatchPriority.new_);
    });

    test('value getter returns correct string', () {
      expect(MatchPriority.new_.value, 'new');
      expect(MatchPriority.priority.value, 'priority');
      expect(MatchPriority.inWaiting.value, 'inWaiting');
      expect(MatchPriority.onWayOut.value, 'onWayOut');
      expect(MatchPriority.legacy.value, 'legacy');
    });

    test('label getter returns correct display text', () {
      expect(MatchPriority.new_.label, 'New');
      expect(MatchPriority.priority.label, 'Priority');
      expect(MatchPriority.inWaiting.label, 'In Waiting');
      expect(MatchPriority.onWayOut.label, 'Head to Shred');
      expect(MatchPriority.legacy.label, 'Legacy');
    });

    test('emoji getter returns emoji string', () {
      expect(MatchPriority.new_.emoji, isNotEmpty);
      expect(MatchPriority.priority.emoji, isNotEmpty);
      expect(MatchPriority.inWaiting.emoji, isNotEmpty);
      expect(MatchPriority.onWayOut.emoji, isNotEmpty);
      expect(MatchPriority.legacy.emoji, isNotEmpty);
    });
  });

  group('Match', () {
    test('Match.fromJson creates valid Match object', () {
      final json = {
        'id': 'test-id-123',
        'user_a_id': 'user-a-id',
        'user_b_id': 'user-b-id',
        'matched_at': '2026-01-28T01:03:00.357294+00:00',
        'compatibility_score': 0.85,
        'is_super_match': true,
        'user_a_priority': 'priority',
        'user_b_priority': 'new',
      };

      final match = Match.fromJson(json, currentUserId: 'user-a-id');

      expect(match.id, 'test-id-123');
      expect(match.matchedUserId, 'user-b-id');
      expect(match.compatibilityScore, 0.85);
      expect(match.isSuperMatch, true);
      expect(match.priority, MatchPriority.priority);
    });

    test('Match correctly identifies matched user based on current user', () {
      final json = {
        'id': 'test-id-123',
        'user_a_id': 'user-a-id',
        'user_b_id': 'user-b-id',
        'matched_at': '2026-01-28T01:03:00.357294+00:00',
        'compatibility_score': 0.75,
        'is_super_match': false,
      };

      final matchAsUserA = Match.fromJson(json, currentUserId: 'user-a-id');
      expect(matchAsUserA.matchedUserId, 'user-b-id');

      final matchAsUserB = Match.fromJson(json, currentUserId: 'user-b-id');
      expect(matchAsUserB.matchedUserId, 'user-a-id');
    });
  });
}
