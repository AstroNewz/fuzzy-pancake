import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_umpire_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/module_widgets.dart';

class UmpirePreferencesSheet extends ConsumerWidget {
  const UmpirePreferencesSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(umpirePreferencesProvider),
        controller = ref.read(umpirePreferencesProvider.notifier);
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Umpire preferences', style: AppTheme.headlineLg),
              const SizedBox(height: 12),
              SwitchListTile(
                  title: const Text('Voice announcements'),
                  subtitle:
                      const Text('Use the device’s installed English voice.'),
                  value: p.voice,
                  onChanged: (v) => runClubAction(
                      context, () => controller.update(voice: v))),
              Text('Speech rate · ${(p.speechRate * 100).round()}%',
                  style: AppTheme.bodyMd),
              Slider(
                  value: p.speechRate,
                  min: .2,
                  max: 1,
                  divisions: 8,
                  label: '${(p.speechRate * 100).round()}%',
                  onChanged: (v) =>
                      runClubAction(context, () => controller.update(rate: v))),
              SwitchListTile(
                  title: const Text('Enable Physical Button Scoring'),
                  subtitle: Text(AudioUmpireService.physicalKeysSupported
                      ? 'Volume up: server. Volume down: receiver. Hold volume down to undo.'
                      : 'Volume-key interception is available on Android.'),
                  value: p.buttons,
                  onChanged: AudioUmpireService.physicalKeysSupported
                      ? (v) => runClubAction(
                          context, () => controller.update(buttons: v))
                      : null),
              SwitchListTile(
                  title: const Text('Big gesture mode'),
                  subtitle: const Text(
                      'Swipe up on either half to score. Double-tap the center to undo.'),
                  value: p.gestures,
                  onChanged: (v) => runClubAction(
                      context, () => controller.update(gestures: v))),
              SwitchListTile(
                  title: const Text('Court chimes'),
                  subtitle:
                      const Text('Sound at intervals and set completion.'),
                  value: p.sounds,
                  onChanged: (v) => runClubAction(
                      context, () => controller.update(sounds: v))),
              const SizedBox(height: 10),
              Text(
                  'The screen stays awake during play. Physical keys return to normal when this screen is covered, paused or closed.',
                  style: AppTheme.bodySm.copyWith(color: AppTheme.textMuted)),
            ]));
  }
}
