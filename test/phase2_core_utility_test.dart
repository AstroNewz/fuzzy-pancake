import 'package:flutter_test/flutter_test.dart';
import 'package:smashdeck/core/utils/bwf_scoring_rules.dart';
import 'package:smashdeck/features/attendance/attendance_repository.dart';
import 'package:smashdeck/features/match_engine/match_engine_state.dart';

void main() {
  group('BWF Badminton Scoring Rules (Phase 2)', () {
    test('Standard 21-point set win with 2-point clear lead', () {
      expect(BwfScoringRules.isSetWon(21, 19), isTrue);
      expect(BwfScoringRules.isSetWon(19, 21), isTrue);
      expect(BwfScoringRules.isSetWon(21, 20), isFalse); // Lead is only 1
      expect(BwfScoringRules.isSetWon(20, 20), isFalse);
    });

    test('Deuce win beyond 21 points requires 2-point lead', () {
      expect(BwfScoringRules.isSetWon(22, 20), isTrue);
      expect(BwfScoringRules.isSetWon(24, 22), isTrue);
      expect(BwfScoringRules.isSetWon(25, 24), isFalse);
      expect(BwfScoringRules.isSetWon(28, 27), isFalse);
    });

    test('Sudden death 30-point ceiling', () {
      // If score reaches 29-29, 30th point wins regardless of 2-point lead
      expect(BwfScoringRules.isSetWon(30, 29), isTrue);
      expect(BwfScoringRules.isSetWon(29, 30), isTrue);
      expect(BwfScoringRules.getSetWinner(30, 29), equals('A'));
      expect(BwfScoringRules.getSetWinner(29, 30), equals('B'));
    });

    test('11-point mid-game interval', () {
      expect(BwfScoringRules.isAtInterval(11, 7), isTrue);
      expect(BwfScoringRules.isAtInterval(8, 11), isTrue);
      expect(BwfScoringRules.isAtInterval(10, 9), isFalse);
      expect(BwfScoringRules.isAtInterval(11, 11), isFalse);
    });

    test('Service court parity rule (Right if even, Left if odd)', () {
      expect(BwfScoringRules.isRightServiceCourt(0), isTrue);
      expect(BwfScoringRules.isRightServiceCourt(2), isTrue);
      expect(BwfScoringRules.isRightServiceCourt(14), isTrue);
      expect(BwfScoringRules.isRightServiceCourt(1), isFalse);
      expect(BwfScoringRules.isRightServiceCourt(3), isFalse);
      expect(BwfScoringRules.isRightServiceCourt(21), isFalse);
    });

    test('Best of 3 sets match winner', () {
      final sets1 = [
        {'a': 21, 'b': 19},
        {'a': 21, 'b': 15},
      ];
      expect(BwfScoringRules.getMatchWinner(sets1), equals('A'));

      final sets2 = [
        {'a': 21, 'b': 18},
        {'a': 19, 'b': 21},
        {'a': 18, 'b': 21},
      ];
      expect(BwfScoringRules.getMatchWinner(sets2), equals('B'));
    });
  });

  group('Attendance Token Parsing (ISSUE-003 Mitigation)', () {
    test('Valid TOTP token payload parses correctly', () {
      const payload = 'SMASHDECK:2026-09-05:582914';
      final parsed = AttendanceRepository.parseQrPayload(payload);

      expect(parsed, isNotNull);
      expect(parsed!['prefix'], equals('SMASHDECK'));
      expect(parsed['date'], equals('2026-09-05'));
      expect(parsed['totp'], equals('582914'));
    });

    test('Invalid payload returns null', () {
      expect(AttendanceRepository.parseQrPayload('INVALID_QR_CODE'), isNull);
      expect(
          AttendanceRepository.parseQrPayload('FOO:2026-09-05:123456'), isNull);
      expect(AttendanceRepository.parseQrPayload('SMASHDECK:only_two_parts'),
          isNull);
    });
  });

  group('Live Match Notifier & Undo Stack', () {
    test('Point additions and robust undo restore previous scores', () {
      final notifier = LiveMatchNotifier();
      notifier.initMatch(
        teamA1Id: 'p-01',
        teamA1Name: 'Player A',
        teamB1Id: 'p-02',
        teamB1Name: 'Player B',
      );

      expect(notifier.state.teamAScore, equals(0));
      expect(notifier.state.teamBScore, equals(0));

      notifier.addPointTeamA();
      notifier.addPointTeamA();
      notifier.addPointTeamB();

      expect(notifier.state.teamAScore, equals(2));
      expect(notifier.state.teamBScore, equals(1));
      expect(notifier.state.servingTeam, equals('B'));
      expect(notifier.state.undoStack.length, equals(3));

      // Undo last point
      notifier.undoLastPoint();
      expect(notifier.state.teamAScore, equals(2));
      expect(notifier.state.teamBScore, equals(0));
      expect(notifier.state.servingTeam, equals('A'));

      // Undo again
      notifier.undoLastPoint();
      expect(notifier.state.teamAScore, equals(1));
      expect(notifier.state.teamBScore, equals(0));
    });
  });
}
