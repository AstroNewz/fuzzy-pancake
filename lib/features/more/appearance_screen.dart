import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/appearance_preferences.dart';
import '../../core/widgets/court_panel.dart';
import '../../core/widgets/stitch_background.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  Future<void> _save(BuildContext context, WidgetRef ref,
      {double? grain, bool? reduceMotion}) async {
    try {
      await ref
          .read(appearanceProvider.notifier)
          .update(grain: grain, reduceMotion: reduceMotion);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not save your preference. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    return StitchAppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          title: const Text('Look & feel'),
          backgroundColor: Colors.transparent),
      body: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          CourtPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('MAKE IT YOURS',
                    style:
                        AppTheme.labelCaps.copyWith(color: AppTheme.mintTeal)),
                const SizedBox(height: 14),
                Text('A little grit.\nA lot of game.',
                    style: AppTheme.headlineXl),
                const SizedBox(height: 12),
                Text(
                    'Your texture and motion preferences apply throughout SmashDeck.',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textMuted)),
              ])),
          const SizedBox(height: 32),
          Text('FILM GRAIN', style: AppTheme.labelCaps),
          const SizedBox(height: 10),
          Text('Choose the texture you like. Preview it right here.',
              style: AppTheme.bodyMd.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in [
              ('Clean', 0.0),
              ('Subtle', .3),
              ('Grainy', .65),
              ('Extra grit', 1.0)
            ])
              ChoiceChip(
                  label: Text(option.$1),
                  selected: appearance.grain == option.$2,
                  onSelected: (_) => _save(context, ref, grain: option.$2)),
          ]),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Reduce motion', style: AppTheme.headlineMd),
            subtitle: const Text(
                'Keep the atmosphere still and transitions instant.'),
            value: appearance.reduceMotion,
            onChanged: (value) => _save(context, ref, reduceMotion: value),
          ),
          const SizedBox(height: 12),
          Text('Your device’s reduced-motion setting is always respected.',
              style: AppTheme.bodySm.copyWith(color: AppTheme.textMuted)),
        ]),
      )),
    ));
  }
}
