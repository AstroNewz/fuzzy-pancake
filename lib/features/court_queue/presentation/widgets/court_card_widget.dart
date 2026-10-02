import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../models/court_session_model.dart';

class CourtCardWidget extends StatelessWidget {
  const CourtCardWidget(
      {super.key,
      required this.court,
      required this.session,
      required this.data,
      required this.now,
      required this.manage,
      required this.onAssign,
      required this.onStart,
      required this.onFinish,
      required this.onUmpire});
  final int court;
  final CourtSession? session;
  final CourtQueueData data;
  final DateTime now;
  final bool manage;
  final VoidCallback onAssign, onStart, onFinish, onUmpire;
  @override
  Widget build(BuildContext context) {
    final seconds = session?.remaining(now) ?? 900;
    final expired = session?.startedAt != null && seconds == 0;
    final color = expired ? AppTheme.errorRed : AppTheme.limeNeon;
    String names(List<String> ids) => ids
        .map((id) =>
            data.members.firstWhere((p) => p.player.id == id).player.name)
        .join(' + ');
    return GlassPanel(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('COURT $court', style: AppTheme.headlineMd)),
            AnimatedOpacity(
                opacity: expired &&
                        now.second.isEven &&
                        !MediaQuery.disableAnimationsOf(context)
                    ? .35
                    : 1,
                duration: const Duration(milliseconds: 400),
                child: Icon(Icons.circle, size: 8, color: color))
          ]),
          Text(
              expired
                  ? 'CHANGEOVER DUE'
                  : session?.status.toUpperCase() ?? 'EMPTY',
              style: AppTheme.labelCaps.copyWith(
                  color: session == null ? AppTheme.textMuted : color)),
          const SizedBox(height: 20),
          Row(children: [
            SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                    value: seconds / 900,
                    strokeWidth: 4,
                    color: color,
                    backgroundColor: AppTheme.borderDark)),
            const SizedBox(width: 18),
            Expanded(
                child: Text(
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                    style: AppTheme.jetBrainsMono(
                        size: 36,
                        weight: FontWeight.w800,
                        color: color,
                        letterSpacing: -2)))
          ]),
          const SizedBox(height: 18),
          if (session == null)
            Text('The next rally is yours.',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textMuted))
          else
            Text('${names(session!.teamA)}\nvs ${names(session!.teamB)}',
                style: AppTheme.bodyLg),
          const SizedBox(height: 16),
          if (manage)
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: session == null
                    ? [
                        FilledButton.icon(
                            onPressed: onAssign,
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text('FIND MATCH')),
                      ]
                    : [
                        if (session!.startedAt == null)
                          FilledButton(
                              onPressed: onStart,
                              child: const Text('START CLOCK')),
                        OutlinedButton(
                            onPressed: onUmpire, child: const Text('UMPIRE')),
                        TextButton(
                            onPressed: onFinish,
                            child: Text(session!.startedAt == null
                                ? 'CANCEL WARM-UP'
                                : 'ROTATE COURT')),
                      ]),
        ]));
  }
}
