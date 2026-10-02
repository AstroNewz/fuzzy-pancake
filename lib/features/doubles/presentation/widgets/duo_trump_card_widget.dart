import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../models/doubles_pair_model.dart';

class DuoTrumpCardWidget extends StatefulWidget {
  const DuoTrumpCardWidget(
      {super.key, required this.pair, required this.repaintKey});
  final DoublesPair pair;
  final GlobalKey repaintKey;
  @override
  State<DuoTrumpCardWidget> createState() => _DuoTrumpCardWidgetState();
}

class _DuoTrumpCardWidgetState extends State<DuoTrumpCardWidget> {
  bool back = false;
  Offset tilt = Offset.zero;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context), pair = widget.pair;
    return Semantics(
        button: true,
        label: '${pair.teamName} duo card. Tap to flip.',
        child: MouseRegion(
            onHover: (event) {
              if (!reduced) {
                final box = context.findRenderObject() as RenderBox;
                setState(() => tilt = Offset(
                    (event.localPosition.dx / box.size.width - .5) * .18,
                    (event.localPosition.dy / box.size.height - .5) * .18));
              }
            },
            onExit: (_) => setState(() => tilt = Offset.zero),
            child: GestureDetector(
                onTap: () => setState(() => back = !back),
                onPanUpdate: (d) {
                  if (!reduced) {
                    setState(() => tilt = Offset(
                        (tilt.dx + d.delta.dx * .002).clamp(-.15, .15),
                        (tilt.dy + d.delta.dy * .002).clamp(-.15, .15)));
                  }
                },
                onPanEnd: (_) => setState(() => tilt = Offset.zero),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: back ? 1 : 0),
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 650),
                  curve: Curves.easeInOutCubic,
                  builder: (context, flip, _) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .001)
                        ..rotateX(-tilt.dy)
                        ..rotateY(tilt.dx + flip * pi),
                      child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(flip > .5 ? pi : 0),
                          child: RepaintBoundary(
                              key: widget.repaintKey,
                              child: GlassPanel(
                                  padding: const EdgeInsets.all(22),
                                  radius: 24,
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(children: [
                                          Text('DUO / CLUB EDITION',
                                              style: AppTheme.labelCaps
                                                  .copyWith(
                                                      color:
                                                          AppTheme.mintTeal)),
                                          const Spacer(),
                                          const Icon(Icons.bolt,
                                              color: AppTheme.limeNeon)
                                        ]),
                                        const SizedBox(height: 20),
                                        if (flip <= .5) ...[
                                          Row(children: [
                                            Expanded(
                                                child: Column(children: [
                                              PlayerAvatar(
                                                  name: pair.first.fullName,
                                                  url: pair.first.avatarUrl,
                                                  size: 72),
                                              const SizedBox(height: 8),
                                              Text(pair.first.fullName,
                                                  style: AppTheme.bodyMd,
                                                  textAlign: TextAlign.center)
                                            ])),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                child: Column(children: [
                                                  Text('${pair.ovr}',
                                                      style: AppTheme.displayOvr
                                                          .copyWith(
                                                              color: AppTheme
                                                                  .limeNeon)),
                                                  Text('DUO OVR',
                                                      style: AppTheme.labelCaps)
                                                ])),
                                            Expanded(
                                                child: Column(children: [
                                              PlayerAvatar(
                                                  name: pair.second.fullName,
                                                  url: pair.second.avatarUrl,
                                                  size: 72),
                                              const SizedBox(height: 8),
                                              Text(pair.second.fullName,
                                                  style: AppTheme.bodyMd,
                                                  textAlign: TextAlign.center)
                                            ]))
                                          ]),
                                          const SizedBox(height: 20),
                                          Text(pair.teamName,
                                              style: AppTheme.headlineLg,
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 8),
                                          Text(pair.badge.toUpperCase(),
                                              style: AppTheme.labelCaps
                                                  .copyWith(
                                                      color:
                                                          AppTheme.mintTeal)),
                                          const SizedBox(height: 20),
                                          LinearProgressIndicator(
                                              value: pair.chemistry / 100,
                                              minHeight: 4,
                                              backgroundColor:
                                                  AppTheme.borderDark),
                                          const SizedBox(height: 10),
                                          Text('${pair.chemistry}% CHEMISTRY',
                                              style: AppTheme.labelCaps
                                                  .copyWith(
                                                      color:
                                                          AppTheme.limeNeon)),
                                        ] else ...[
                                          Text('Stronger together.',
                                              style: AppTheme.headlineLg),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                              height: 150,
                                              width: 240,
                                              child: CustomPaint(
                                                  painter: _DuoRadar(
                                                      pair.attributes))),
                                          const SizedBox(height: 20),
                                          Wrap(
                                              spacing: 20,
                                              runSpacing: 8,
                                              children: [
                                                Text('${pair.matches} PLAYED',
                                                    style: AppTheme.labelCaps),
                                                Text('${pair.wins} WINS',
                                                    style: AppTheme.labelCaps),
                                                Text(
                                                    '${pair.consecutiveWins} STREAK',
                                                    style: AppTheme.labelCaps)
                                              ]),
                                        ],
                                        const SizedBox(height: 18),
                                        Text('TAP TO FLIP · DRAG TO TILT',
                                            style: AppTheme.labelCaps.copyWith(
                                                fontSize: 8,
                                                color: AppTheme.textMuted)),
                                      ]))))),
                ))));
  }
}

class _DuoRadar extends CustomPainter {
  _DuoRadar(this.stats);
  final List<double> stats;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        radius = size.height * .36;
    Offset point(int i, double fraction) =>
        center +
        Offset(cos(-pi / 2 + i * pi / 2), sin(-pi / 2 + i * pi / 2)) *
            radius *
            fraction;
    final line = Paint()
      ..color = AppTheme.borderDark
      ..style = PaintingStyle.stroke;
    for (final f in [.25, .5, .75, 1.0]) {
      final path = Path()..moveTo(point(0, f).dx, point(0, f).dy);
      for (var i = 1; i < 4; i++) {
        path.lineTo(point(i, f).dx, point(i, f).dy);
      }
      canvas.drawPath(path..close(), line);
    }
    final shape = Path()
      ..moveTo(point(0, stats[0] / 100).dx, point(0, stats[0] / 100).dy);
    for (var i = 1; i < 4; i++) {
      shape.lineTo(point(i, stats[i] / 100).dx, point(i, stats[i] / 100).dy);
    }
    shape.close();
    canvas.drawPath(
        shape, Paint()..color = AppTheme.limeNeon.withValues(alpha: .18));
    canvas.drawPath(
        shape,
        Paint()
          ..color = AppTheme.limeNeon
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < 4; i++) {
      final text = TextPainter(
          text: TextSpan(
              text: ['SMASH', 'AGILITY', 'STAMINA', 'CONTROL'][i],
              style:
                  AppTheme.jetBrainsMono(size: 8, color: AppTheme.textMuted)),
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(
          canvas, point(i, 1.28) - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(_DuoRadar oldDelegate) =>
      oldDelegate.stats.toString() != stats.toString();
}
