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
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.cardDark.withValues(alpha: .96),
                          AppTheme.cardDark.withValues(alpha: .90)
                        ]),
                    border: Border.all(color: AppTheme.borderDark),
                    borderRadius: BorderRadius.circular(radius)),
                child: Stack(children: [
                  Positioned.fill(
                      child: FilmGrain(
                          intensity:
                              ref.watch(appearanceProvider).grain * .18)),
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
