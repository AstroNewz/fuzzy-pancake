import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar(
      {super.key,
      required this.name,
      this.url,
      this.size = 42,
      this.color = AppTheme.limeNeon});
  final String name;
  final String? url;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s.characters.first)
        .join()
        .toUpperCase();
    final fallback = Center(
        child: Text(initials.isEmpty ? '?' : initials,
            style: AppTheme.chivo(
                size: size * .3, color: color, weight: FontWeight.w800)));
    final source = url;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .08),
          border: Border.all(color: color.withValues(alpha: .3))),
      clipBehavior: Clip.antiAlias,
      child: source == null || source.isEmpty
          ? fallback
          : source.startsWith('assets/')
              ? Image.asset(source,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
              : Image.network(source,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
    );
  }
}
