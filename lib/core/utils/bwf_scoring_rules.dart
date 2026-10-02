/// BWF (Badminton World Federation) Scoring Logic with Custom Target Points Support
class BwfScoringRules {
  static DoublesServicePositions rotateDoubles(
          DoublesServicePositions positions,
          {required String servingTeam,
          required String rallyWinner}) =>
      positions.afterRally(servingTeam: servingTeam, winner: rallyWinner);

  /// Check if a set has been won
  /// - First to targetPoints (default 21) with a 2-point clear lead wins.
  /// - If score reaches deuce (target - 1), side with a 2-point lead wins.
  /// - Ceiling is targetPoints + 9 (e.g. 30 for 21-pt, 20 for 11-pt) - sudden death.
  static bool isSetWon(int scoreA, int scoreB, {int targetPoints = 21}) {
    final ceiling = targetPoints + 9;
    if (targetPoints < 1 ||
        scoreA < 0 ||
        scoreB < 0 ||
        scoreA > ceiling ||
        scoreB > ceiling ||
        scoreA == scoreB) {
      return false;
    }
    final high = scoreA > scoreB ? scoreA : scoreB;
    final low = scoreA < scoreB ? scoreA : scoreB;
    // A completed score cannot contain rallies played after the winning rally.
    if (high > targetPoints && high < ceiling && high - low != 2) return false;
    if (high == ceiling && low < ceiling - 2) return false;

    // Normal win with 2-point lead
    if (scoreA >= targetPoints && (scoreA - scoreB) >= 2) {
      return true;
    }
    if (scoreB >= targetPoints && (scoreB - scoreA) >= 2) {
      return true;
    }

    // Sudden death ceiling
    if (scoreA >= ceiling || scoreB >= ceiling) {
      return true;
    }

    return false;
  }

  /// Get the winner of the set ('A', 'B', or null if in progress)
  static String? getSetWinner(int scoreA, int scoreB, {int targetPoints = 21}) {
    if (!isSetWon(scoreA, scoreB, targetPoints: targetPoints)) return null;
    return scoreA > scoreB ? 'A' : 'B';
  }

  /// Check if match reached the interval in a set (e.g. at point 11 in a 21-pt match, or half of targetPoints)
  static bool isAtInterval(int scoreA, int scoreB, {int targetPoints = 21}) {
    final interval = (targetPoints / 2).ceil();
    return (scoreA == interval && scoreB < interval) ||
        (scoreB == interval && scoreA < interval);
  }

  /// In singles: server serves from Right service court when their score is EVEN (0, 2, 4...)
  /// and from Left service court when their score is ODD (1, 3, 5...)
  static bool isRightServiceCourt(int serverScore) {
    return serverScore % 2 == 0;
  }

  /// Determine match winner given completed sets and best of N sets (1, 3, 5)
  static String? getMatchWinner(List<Map<String, int>> setScores,
      {int bestOfSets = 3, int targetPoints = 21}) {
    int setsWonA = 0;
    int setsWonB = 0;
    final setsNeeded = (bestOfSets / 2).ceil();

    for (final set in setScores) {
      final scoreA = set['a'] ?? 0;
      final scoreB = set['b'] ?? 0;
      final winner = getSetWinner(scoreA, scoreB, targetPoints: targetPoints);
      if (winner == 'A') setsWonA++;
      if (winner == 'B') setsWonB++;
    }

    if (setsWonA >= setsNeeded) return 'A';
    if (setsWonB >= setsNeeded) return 'B';
    return null;
  }
}

/// Players only swap service boxes after winning a rally on their own serve.
/// The receiving side stays put when it wins the right to serve.
class DoublesServicePositions {
  const DoublesServicePositions(
      {this.aFirstRight = true, this.bFirstRight = true});
  final bool aFirstRight, bFirstRight;
  int playerIndex(String team, int servingScore) {
    final firstRight = team == 'A' ? aFirstRight : bFirstRight;
    return firstRight == BwfScoringRules.isRightServiceCourt(servingScore)
        ? 0
        : 1;
  }

  DoublesServicePositions afterRally(
          {required String servingTeam, required String winner}) =>
      DoublesServicePositions(
        aFirstRight:
            servingTeam == 'A' && winner == 'A' ? !aFirstRight : aFirstRight,
        bFirstRight:
            servingTeam == 'B' && winner == 'B' ? !bFirstRight : bFirstRight,
      );
}
