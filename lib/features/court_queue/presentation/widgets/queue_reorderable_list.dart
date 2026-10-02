import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../models/court_session_model.dart';

class QueueReorderableList extends StatelessWidget {
  const QueueReorderableList(
      {super.key,
      required this.players,
      required this.onReorder,
      required this.enabled});
  final List<QueuePlayer> players;
  final ValueChanged<List<String>> onReorder;
  final bool enabled;
  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: players.length,
      onReorderItem: (from, to) {
        if (!enabled) return;
        final ids = players.map((p) => p.player.id).toList();
        ids.insert(to, ids.removeAt(from));
        onReorder(ids);
      },
      itemBuilder: (context, i) {
        final p = players[i];
        return ListTile(
            key: ValueKey(p.player.id),
            contentPadding: EdgeInsets.zero,
            leading: PlayerAvatar(
                name: p.player.name, url: p.player.avatar, size: 36),
            title: Text(p.player.name, style: AppTheme.bodyLg),
            subtitle: Text(
                '${p.played} played · waiting ${DateTime.now().difference(p.waitingSince).inMinutes.clamp(0, 1440)} min'),
            trailing: enabled
                ? ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.drag_handle)))
                : Text('${p.player.ovr}', style: AppTheme.statBadge));
      });
}
