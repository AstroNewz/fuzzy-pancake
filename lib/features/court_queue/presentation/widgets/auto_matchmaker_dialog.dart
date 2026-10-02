import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/court_session_model.dart';

class AutoMatchmakerDialog extends StatelessWidget {
  const AutoMatchmakerDialog(
      {super.key, required this.teamA, required this.teamB});
  final List<QueuePlayer> teamA, teamB;
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('A fair match. Ready?'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final team in [teamA, teamB]) ...[
              Text(team.map((p) => p.player.name).join(' + '),
                  style: AppTheme.headlineMd, textAlign: TextAlign.center),
              Text(
                  '${team.fold<int>(0, (n, p) => n + p.player.ovr)} combined OVR',
                  style: AppTheme.bodySm.copyWith(color: AppTheme.limeNeon)),
              const SizedBox(height: 16),
            ],
            const Text(
                'Players come from the front of the queue. Doubles teams minimize the OVR difference.'),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ASSIGN COURT'))
          ]);
}
