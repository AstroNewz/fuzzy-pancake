import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashdeck/core/services/telegram_notification_service.dart';
import 'package:smashdeck/features/gear_tracker/gear_model.dart';
import 'package:smashdeck/features/ladder/ladder_challenge_repository.dart';

void main() {
  // CRITICAL FIX: Initialize Flutter binding before any plugin (SharedPreferences) usage.
  // This prevents "MissingPluginException" and "ServicesBinding not initialized" errors
  // that occur when platform channels are invoked outside of a widget test environment.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset SharedPreferences to a clean in-memory state before each test.
    // This ensures Telegram broadcast history does not bleed between tests.
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 4 - Ladder Challenge Eligibility Tests', () {
    test('Player at Rank 5 can challenge Rank 4 and Rank 3 (+1 and +2 ranks)',
        () {
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 5, defenderRank: 4),
        isTrue,
      );
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 5, defenderRank: 3),
        isTrue,
      );
    });

    test(
        'Player at Rank 5 CANNOT challenge Rank 2 or Rank 1 (+3 or +4 ranks above)',
        () {
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 5, defenderRank: 2),
        isFalse,
      );
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 5, defenderRank: 1),
        isFalse,
      );
    });

    test('Player CANNOT challenge themselves or players ranked below them', () {
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 5, defenderRank: 5),
        isFalse,
      );
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 5, defenderRank: 6),
        isFalse,
      );
    });

    test('Rank 1 (King of the Court) cannot challenge anyone', () {
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 1, defenderRank: 0),
        isFalse,
      );
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 1, defenderRank: 1),
        isFalse,
      );
      expect(
        LadderChallengeEngine.canChallenge(challengerRank: 1, defenderRank: 2),
        isFalse,
      );
    });
  });

  group('Phase 4 - Ladder Auto-Swap Algorithm Tests', () {
    test('Challenger at Rank 5 beating Rank 3 displaces 3 and 4 down by 1', () {
      final initialRanks = [
        {'id': 'p1', 'name': 'Player 1', 'rank': 1},
        {'id': 'p2', 'name': 'Player 2', 'rank': 2},
        {'id': 'p3', 'name': 'Player 3', 'rank': 3},
        {'id': 'p4', 'name': 'Player 4', 'rank': 4},
        {'id': 'p5', 'name': 'Player 5', 'rank': 5},
      ];

      final swapped =
          LadderChallengeEngine.computeLadderSwap<Map<String, dynamic>>(
        currentLadder: initialRanks,
        challengerRank: 5,
        defenderRank: 3,
        getRank: (item) => item['rank'] as int,
        copyWithRank: (item, newRank) => {
          ...item,
          'rank': newRank,
        },
      );

      // Verify new order
      expect(swapped[0]['id'], equals('p1'));
      expect(swapped[0]['rank'], equals(1));

      expect(swapped[1]['id'], equals('p2'));
      expect(swapped[1]['rank'], equals(2));

      // Challenger (p5) takes Rank 3!
      expect(swapped[2]['id'], equals('p5'));
      expect(swapped[2]['rank'], equals(3));

      // Defender (p3) pushed down to Rank 4!
      expect(swapped[3]['id'], equals('p3'));
      expect(swapped[3]['rank'], equals(4));

      // Intermediate (p4) pushed down to Rank 5!
      expect(swapped[4]['id'], equals('p4'));
      expect(swapped[4]['rank'], equals(5));

      // Check unique ranks from 1 to 5
      final rankSet = swapped.map((e) => e['rank'] as int).toSet();
      expect(rankSet, equals({1, 2, 3, 4, 5}));
    });

    test(
        'Adjacent challenge (Rank 4 beats Rank 3) performs clean 2-player swap',
        () {
      final initialRanks = [
        {'id': 'p1', 'name': 'Player 1', 'rank': 1},
        {'id': 'p2', 'name': 'Player 2', 'rank': 2},
        {'id': 'p3', 'name': 'Player 3', 'rank': 3},
        {'id': 'p4', 'name': 'Player 4', 'rank': 4},
      ];

      final swapped =
          LadderChallengeEngine.computeLadderSwap<Map<String, dynamic>>(
        currentLadder: initialRanks,
        challengerRank: 4,
        defenderRank: 3,
        getRank: (item) => item['rank'] as int,
        copyWithRank: (item, newRank) => {
          ...item,
          'rank': newRank,
        },
      );

      expect(swapped[2]['id'], equals('p4'));
      expect(swapped[2]['rank'], equals(3));

      expect(swapped[3]['id'], equals('p3'));
      expect(swapped[3]['rank'], equals(4));
    });
  });

  group('Phase 4 - Equipment Tracker & Tension Loss Tests', () {
    test('Freshly strung racket (day 0) has ~8% initial stretch drop', () {
      final fresh = GearLog(
        id: 'g-test-fresh',
        playerId: 'p-test',
        racketBrandModel: 'Yonex Astrox 99 Pro',
        stringModel: 'BG66 Ultimax',
        tensionLbs: 28.0,
        stringingDate: DateTime.now(),
      );

      expect(fresh.daysSinceStringing, equals(0));
      expect(fresh.estimatedCurrentTensionLbs, equals(25.8));
      expect(fresh.tensionDropPct, equals(7.9));
      expect(fresh.needsRestringing, isFalse);
      expect(fresh.statusLabel, equals('Optimal Tension'));
    });

    test('Racket strung 45 days ago flags urgent restringing', () {
      final oldRacket = GearLog(
        id: 'g-test-old',
        playerId: 'p-test',
        racketBrandModel: 'Yonex Arcsaber 11 Pro',
        stringModel: 'Exbolt 65',
        tensionLbs: 27.0,
        stringingDate: DateTime.now().subtract(const Duration(days: 45)),
      );

      expect(oldRacket.daysSinceStringing, equals(45));
      expect(oldRacket.needsRestringing, isTrue);
      expect(oldRacket.statusLabel, equals('Needs Restringing'));
      expect(oldRacket.tensionDropPct, greaterThanOrEqualTo(20.0));
      expect(oldRacket.tensionHealthPct, lessThan(0.5));
    });
  });

  group('Phase 4 - Telegram Bot Webhook Integration Tests', () {
    test('Match result broadcast dispatches and records in local history',
        () async {
      final success = await TelegramNotificationService.broadcastMatchResult(
        winnerName: 'Vikram Malhotra',
        loserName: 'Rohan Verma',
        scoreSummary: '21-18, 19-21, 21-17',
        eloDelta: 16,
        ladderUpdate: 'Vikram takes Rank #1! 👑',
      );

      expect(success, isTrue);

      final history = await TelegramNotificationService.getBroadcastHistory();
      expect(history.isNotEmpty, isTrue);
      expect(history.first.contains('Vikram Malhotra'), isTrue);
      expect(history.first.contains('+16 / -16 PTS'), isTrue);
    });

    test('Ladder challenge broadcast formats properly with ranks and stakes',
        () async {
      final success =
          await TelegramNotificationService.broadcastLadderChallenge(
        challengerName: 'Aarav Sharma',
        challengerRank: 4,
        defenderName: 'Kavya Patel',
        defenderRank: 2,
      );

      expect(success, isTrue);

      final history = await TelegramNotificationService.getBroadcastHistory();
      expect(history.first.contains('Aarav Sharma (Rank #4)'), isTrue);
      expect(history.first.contains('Kavya Patel (Rank #2)'), isTrue);
    });
  });
}
