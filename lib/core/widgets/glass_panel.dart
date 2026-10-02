import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/appearance_preferences.dart';
import 'film_grain.dart';

class GlassPanel extends ConsumerWidget {
  const GlassPanel(
      {super.key,
      required this.child,
      this.radius = 18,
      this.padding = EdgeInsets.zero});
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.cardBright.withValues(alpha: .62),
                          AppTheme.bgDarker.withValues(alpha: .78)
                        ]),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .12)),
                    borderRadius: BorderRadius.circular(radius)),
                child: Stack(children: [
                  Positioned.fill(
                      child: FilmGrain(
                          intensity: ref.watch(appearanceProvider).grain * .6)),
                  Padding(padding: padding, child: child),
                ]))),
      );
}

class GlassTabs extends StatelessWidget {
  const GlassTabs(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onSelected});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => GlassPanel(
      padding: const EdgeInsets.all(5),
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                      label: Text(labels[i]),
                      selected: selected == i,
                      onSelected: (_) => onSelected(i))),
          ])));
}
