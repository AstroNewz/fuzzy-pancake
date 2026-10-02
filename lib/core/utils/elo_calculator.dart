import 'dart:math';

/// Elo Rating Calculation Engine matching database procedure `fn_adjust_elo_after_match`
/// Implements standard BWF / FIDE Elo formula with K=32 (Issue-004)
class EloCalculator {
  static const double defaultKFactor = 32.0;

  /// Calculate expected outcome probability for Player A vs Player B
  /// E_A = 1 / (1 + 10 ^ ((R_B - R_A) / 400))
  static double calculateExpectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + pow(10.0, (ratingB - ratingA) / 400.0));
  }

  /// Calculates rating adjustment (delta) after a match
  /// delta = round(K * (actualScore - expectedScore))
  /// [won] true if player won (actualScore = 1.0), false if lost (actualScore = 0.0)
  static int calculateRatingDelta({
    required int playerRating,
    required int opponentRating,
    required bool won,
    double kFactor = defaultKFactor,
  }) {
    final expected = calculateExpectedScore(playerRating, opponentRating);
    final actual = won ? 1.0 : 0.0;
    return (kFactor * (actual - expected)).round();
  }

  /// Calculates updated ratings for both players after match
  static ({int newRatingA, int newRatingB, int deltaA, int deltaB})
      calculateMatchExchange({
    required int ratingA,
    required int ratingB,
    required bool teamAWon,
    double kFactor = defaultKFactor,
  }) {
    final deltaA = calculateRatingDelta(
      playerRating: ratingA,
      opponentRating: ratingB,
      won: teamAWon,
      kFactor: kFactor,
    );

    final deltaB = calculateRatingDelta(
      playerRating: ratingB,
      opponentRating: ratingA,
      won: !teamAWon,
      kFactor: kFactor,
    );

    return (
      newRatingA: max(100, ratingA + deltaA),
      newRatingB: max(100, ratingB + deltaB),
      deltaA: deltaA,
      deltaB: deltaB,
    );
  }

  /// Computes dynamic OVR rating based on attributes
  /// OVR = 0.30*Smash + 0.25*Agility + 0.25*Stamina + 0.20*Consistency
  static int calculateOvr({
    required int smash,
    required int agility,
    required int stamina,
    required int consistency,
  }) {
    final raw = (0.30 * smash) +
        (0.25 * agility) +
        (0.25 * stamina) +
        (0.20 * consistency);
    return raw.round().clamp(40, 99);
  }
}
