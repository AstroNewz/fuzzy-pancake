import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../models/tournament_model.dart';

class BracketTreeView extends StatelessWidget {
  const BracketTreeView(
      {super.key, required this.tournament, required this.onMatchTap});
  final Tournament tournament;
  final ValueChanged<TournamentMatch> onMatchTap;
  @override
  Widget build(BuildContext context) {
    final rounds = tournament.rounds;
    final count = rounds.first.matches.length;
    const step = 146.0, width = 258.0, nodeWidth = 226.0;
    final height = max(230.0, count * step + 50);
    Offset position(int r, int i) {
      if (rounds[r].name == '3rd place') return Offset(r * width, 70);
      return Offset(r * width, 46 + ((i + .5) * (1 << r) * step) - 62);
    }

    final locations = <String, Offset>{};
    for (var r = 0; r < rounds.length; r++) {
      for (var i = 0; i < rounds[r].matches.length; i++) {
        locations[rounds[r].matches[i].id] = position(r, i);
      }
    }
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
            width: rounds.length * width,
            height: height,
            child: Stack(children: [
              Positioned.fill(
                  child: IgnorePointer(
                      child: CustomPaint(
                          painter: _BracketLines(
                              tournament, locations, nodeWidth)))),
              for (var r = 0; r < rounds.length; r++)
                Positioned(
                    left: r * width,
                    top: 0,
                    width: nodeWidth,
                    child: Text(rounds[r].name.toUpperCase(),
                        style: AppTheme.labelCaps
                            .copyWith(color: AppTheme.mintTeal))),
              for (final round in rounds)
                for (final match in round.matches)
                  Positioned(
                    left: locations[match.id]!.dx,
                    top: locations[match.id]!.dy,
                    width: nodeWidth,
                    height: 126,
                    child: Semantics(
                        button: true,
                        label:
                            '${round.name}, ${tournament.side(match.sideA)?.name ?? 'To be decided'} versus ${tournament.side(match.sideB)?.name ?? 'To be decided'}, ${match.status}',
                        child: GlassPanel(
                            padding: const EdgeInsets.all(12),
                            child: InkWell(
                                onTap: () => onMatchTap(match),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(match.status.toUpperCase(),
                                          style: AppTheme.labelCaps.copyWith(
                                              fontSize: 8,
                                              color: match.status == 'live'
                                                  ? AppTheme.mintTeal
                                                  : AppTheme.textMuted)),
                                      const SizedBox(height: 9),
                                      for (final sideId in [
                                        match.sideA,
                                        match.sideB
                                      ])
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(children: [
                                              PlayerAvatar(
                                                  name: tournament
                                                          .side(sideId)
                                                          ?.name ??
                                                      '?',
                                                  url: tournament
                                                      .side(sideId)
                                                      ?.players
                                                      .first
                                                      .avatar,
                                                  size: 24),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                  child: Text(
                                                      tournament.side(sideId) ==
                                                              null
                                                          ? 'Awaiting qualifier'
                                                          : '${tournament.side(sideId)!.seed}. ${tournament.side(sideId)!.name}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTheme.spaceGrotesk(
                                                          size: 11,
                                                          weight:
                                                              FontWeight.w700,
                                                          color: match.winnerId ==
                                                                      sideId &&
                                                                  sideId != null
                                                              ? AppTheme
                                                                  .limeNeon
                                                              : AppTheme
                                                                  .textWhite))),
                                              if (sideId != null)
                                                Text(
                                                    '${tournament.side(sideId)!.ovr}',
                                                    style:
                                                        AppTheme.jetBrainsMono(
                                                            size: 10,
                                                            color: AppTheme
                                                                .limeNeon)),
                                            ])),
                                      Text(
                                          match.sets.isEmpty
                                              ? 'OVR · BEST OF 3'
                                              : match.sets
                                                  .map((s) =>
                                                      "${s['a']}–${s['b']}")
                                                  .join('   '),
                                          style: AppTheme.jetBrainsMono(
                                              size: 9,
                                              color: AppTheme.textMuted)),
                                    ])))),
                  ),
            ])));
  }
}

class _BracketLines extends CustomPainter {
  _BracketLines(this.cup, this.positions, this.width);
  final Tournament cup;
  final Map<String, Offset> positions;
  final double width;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.mintTeal.withValues(alpha: .35)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (final match
        in cup.matches.where((m) => m.sourceA != null && !m.thirdPlace)) {
      final target = positions[match.id]! + const Offset(0, 63);
      for (final source in [match.sourceA, match.sourceB]) {
        final from = positions[source]! + Offset(width, 63);
        final mid = (from.dx + target.dx) / 2;
        canvas.drawPath(
            Path()
              ..moveTo(from.dx, from.dy)
              ..lineTo(mid, from.dy)
              ..lineTo(mid, target.dy)
              ..lineTo(target.dx, target.dy),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BracketLines oldDelegate) => true;
}
