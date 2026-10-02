import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashdeck/core/theme/card_theme.dart';
import 'package:smashdeck/core/utils/elo_calculator.dart';
import 'package:smashdeck/features/trump_card/trump_card_model.dart';

void main() {
  group('Phase 3 - Elo Rating Engine Tests', () {
    test('Expected score for equally rated players is exactly 50%', () {
      final expected = EloCalculator.calculateExpectedScore(1200, 1200);
      expect(expected, closeTo(0.50, 0.001));
    });

    test('Higher rated player has higher expected win probability', () {
      final probHigher = EloCalculator.calculateExpectedScore(1400, 1200);
      final probLower = EloCalculator.calculateExpectedScore(1200, 1400);

      expect(probHigher, greaterThan(0.70));
      expect(probLower, lessThan(0.30));
      expect(probHigher + probLower, closeTo(1.0, 0.001));
    });

    test('Even match win yields +16 / -16 with K=32', () {
      final exchange = EloCalculator.calculateMatchExchange(
        ratingA: 1200,
        ratingB: 1200,
        teamAWon: true,
      );

      expect(exchange.deltaA, equals(16));
      expect(exchange.deltaB, equals(-16));
      expect(exchange.newRatingA, equals(1216));
      expect(exchange.newRatingB, equals(1184));
    });

    test('Major upset yields high Elo gain for underdog', () {
      // Underdog (1000) beats favorite (1400)
      final exchange = EloCalculator.calculateMatchExchange(
        ratingA: 1000,
        ratingB: 1400,
        teamAWon: true,
      );

      expect(exchange.deltaA, greaterThanOrEqualTo(28));
      expect(exchange.deltaB, lessThanOrEqualTo(-28));
      expect(exchange.newRatingA, equals(1000 + exchange.deltaA));
    });

    test('Expected victory yields small Elo gain', () {
      // Favorite (1400) beats underdog (1000)
      final exchange = EloCalculator.calculateMatchExchange(
        ratingA: 1400,
        ratingB: 1000,
        teamAWon: true,
      );

      expect(exchange.deltaA, lessThanOrEqualTo(4));
      expect(exchange.deltaB, greaterThanOrEqualTo(-4));
    });
  });

  group('Phase 3 - OVR Calculation & Tier Mapping Tests', () {
    test('Calculate OVR weighted sum correctly', () {
      // 0.30*90 + 0.25*80 + 0.25*80 + 0.20*70 = 27 + 20 + 20 + 14 = 81
      final ovr = EloCalculator.calculateOvr(
        smash: 90,
        agility: 80,
        stamina: 80,
        consistency: 70,
      );

      expect(ovr, equals(81));
    });

    test('OVR clamps between 40 and 99', () {
      final maxOvr = EloCalculator.calculateOvr(
        smash: 120,
        agility: 110,
        stamina: 105,
        consistency: 100,
      );
      final minOvr = EloCalculator.calculateOvr(
        smash: 20,
        agility: 15,
        stamina: 10,
        consistency: 5,
      );

      expect(maxOvr, equals(99));
      expect(minOvr, equals(40));
    });

    test('CardTier string parser parses all tiers correctly', () {
      expect(CardTier.fromString('Diamond'), equals(CardTier.diamond));
      expect(CardTier.fromString('GOLD'), equals(CardTier.gold));
      expect(CardTier.fromString('silver'), equals(CardTier.silver));
      expect(CardTier.fromString('Bronze'), equals(CardTier.bronze));
      expect(CardTier.fromString(null), equals(CardTier.bronze));
      expect(CardTier.fromString('unknown'), equals(CardTier.bronze));
    });

    test('CardTier styles have valid gradients and glowing accents', () {
      for (final tier in CardTier.values) {
        expect(tier.displayName.isNotEmpty, isTrue);
        expect(tier.gradientColors.length, greaterThanOrEqualTo(2));
        expect(tier.accentColor, isNotNull);
        expect(tier.glowColor, isNotNull);
      }
    });

    test('TrumpCardModel correctly instantiates from database map', () {
      final model = TrumpCardModel.fromMap({
        'player_id': 'p-test-01',
        'roll_number': '23CS101',
        'full_name': 'Test Ace',
        'avatar_url': null,
        'playstyle': 'Attacking Smasher',
        'dominant_hand': 'Right',
        'role': 'player',
        'elo_rating': 1350,
        'ladder_rank': 2,
        'smash': 88,
        'agility': 82,
        'stamina': 79,
        'consistency': 80,
        'ovr_rating': 83,
        'card_tier': 'Gold',
        'matches_played': 10,
        'matches_won': 8,
        'matches_lost': 2,
        'win_rate_pct': 80.0,
      });

      expect(model.playerId, equals('p-test-01'));
      expect(model.cardTier, equals(CardTier.gold));
      expect(model.ovrRating, equals(83));
      expect(model.winRatePct, equals(80.0));
      expect(model.ladderRank, equals(2));
    });
  });

  group('Phase 3 - 3D Matrix Perspective Checks', () {
    test('Perspective matrix applies 0.0015 depth on setEntry(3, 2)', () {
      final matrix = Matrix4.identity()..setEntry(3, 2, 0.0015);
      expect(matrix.storage[11], closeTo(0.0015, 0.0001));
    });
  });
}
