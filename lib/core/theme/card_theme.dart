import 'package:flutter/material.dart';

/// Trump Card Tier Visual Styles (Bronze, Silver, Gold, Diamond)
enum CardTier {
  bronze,
  silver,
  gold,
  diamond;

  static CardTier fromString(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'diamond':
        return CardTier.diamond;
      case 'gold':
        return CardTier.gold;
      case 'silver':
        return CardTier.silver;
      default:
        return CardTier.bronze;
    }
  }

  String get displayName {
    switch (this) {
      case CardTier.diamond:
        return 'DIAMOND';
      case CardTier.gold:
        return 'GOLD';
      case CardTier.silver:
        return 'SILVER';
      case CardTier.bronze:
        return 'BRONZE';
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case CardTier.diamond:
        return const [
          Color(0xFF00F0FF), // Electric Cyan
          Color(0xFF7000FF), // Neon Purple
          Color(0xFF001F3F), // Deep Navy
        ];
      case CardTier.gold:
        return const [
          Color(0xFFFFD700), // Vibrant Gold
          Color(0xFFFFA500), // Amber
          Color(0xFF4A3500), // Dark Gold
        ];
      case CardTier.silver:
        return const [
          Color(0xFFE2E8F0), // Platinum Light
          Color(0xFF94A3B8), // Slate Silver
          Color(0xFF1E293B), // Dark Slate
        ];
      case CardTier.bronze:
        return const [
          Color(0xFFCD7F32), // Bronze
          Color(0xFF8B4513), // Saddle Brown
          Color(0xFF2C1608), // Dark Walnut
        ];
    }
  }

  Color get accentColor {
    switch (this) {
      case CardTier.diamond:
        return const Color(0xFF00F0FF);
      case CardTier.gold:
        return const Color(0xFFFFD700);
      case CardTier.silver:
        return const Color(0xFFE2E8F0);
      case CardTier.bronze:
        return const Color(0xFFCD7F32);
    }
  }

  Color get glowColor {
    switch (this) {
      case CardTier.diamond:
        return const Color(0x6600F0FF);
      case CardTier.gold:
        return const Color(0x66FFD700);
      case CardTier.silver:
        return const Color(0x44CBD5E1);
      case CardTier.bronze:
        return const Color(0x44CD7F32);
    }
  }
}
