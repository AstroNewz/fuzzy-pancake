import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Stylized Shuttlecock Logo Widget Matching the Stitch SmashDeck Asset & Mockups
class SmashDeckLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showTagline;

  const SmashDeckLogo({
    super.key,
    this.size = 56,
    this.showText = true,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing Logo Emblem Container
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            color: AppTheme.cardMid,
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.limeNeon.withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: AppTheme.limeNeon.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.sports_tennis,
              color: AppTheme.limeNeon,
              size: size * 0.6,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: AppTheme.chivo(
                size: 26,
                weight: FontWeight.w900,
                color: AppTheme.textWhite,
                letterSpacing: -0.5,
              ),
              children: const [
                TextSpan(text: 'SMASH'),
                TextSpan(
                  text: 'DECK',
                  style: TextStyle(color: AppTheme.limeNeon),
                ),
              ],
            ),
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'COLLEGIATE BADMINTON LADDER & RATINGS',
            style: AppTheme.jetBrainsMono(
              size: 9.5,
              weight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
