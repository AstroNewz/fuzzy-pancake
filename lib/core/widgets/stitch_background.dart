import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/appearance_preferences.dart';
import 'film_grain.dart';
import '../theme/app_theme.dart';

/// A slow-moving courtside atmosphere, painted independently of the UI.
class StitchAppBackground extends ConsumerStatefulWidget {
  const StitchAppBackground(
      {super.key, required this.child, this.showCourtGrid = true});
  final Widget child;
  final bool showCourtGrid;
  @override
  ConsumerState<StitchAppBackground> createState() =>
      _StitchAppBackgroundState();
}

class _StitchAppBackgroundState extends ConsumerState<StitchAppBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 18));
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  void _updateMotion() {
    final enabled = _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !_drift.isAnimating) {
      _drift.repeat(reverse: true);
    } else if (!enabled) {
      _drift.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _updateMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
              Color(0xFF070D20),
              AppTheme.bgDark,
              Color(0xFF050D1B)
            ]))),
        Positioned.fill(
            child: IgnorePointer(
                child: RepaintBoundary(
                    child: CustomPaint(
          painter: _CourtAtmosphere(_drift, showCourt: widget.showCourtGrid),
        )))),
        Positioned.fill(
            child: FilmGrain(intensity: ref.watch(appearanceProvider).grain)),
        widget.child,
      ]);
}

class _CourtAtmosphere extends CustomPainter {
  _CourtAtmosphere(this.animation, {required this.showCourt})
      : super(repaint: animation);
  final Animation<double> animation;
  final bool showCourt;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final w = size.width;
    final h = size.height;
    void bloom(Offset center, double radius, Color color, double alpha) {
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: alpha),
                color.withValues(alpha: 0)
              ],
            ).createShader(Rect.fromCircle(center: center, radius: radius)));
    }

    bloom(Offset(w * (.95 - t * .24), h * (.08 + t * .15)),
        math.max(w * .65, 280), AppTheme.limeNeon, .105);
    bloom(Offset(w * (.05 + t * .20), h * (.8 - t * .15)),
        math.max(w * .52, 240), AppTheme.mintTeal, .085);

    if (!showCourt) return;
    final line = Paint()
      ..color = AppTheme.textWhite.withValues(alpha: .025)
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    final courtTop = h * .49;
    final courtBottom = h * 1.16;
    final court = Path()
      ..moveTo(w * .22, courtTop)
      ..lineTo(w * .78, courtTop)
      ..lineTo(w * 1.25, courtBottom)
      ..lineTo(-w * .25, courtBottom)
      ..close();
    canvas.drawPath(court, line);
    canvas.drawLine(
        Offset(w * .5, courtTop), Offset(w * .5, courtBottom), line);
    for (final f in [.22, .48, .76]) {
      final y = courtTop + (courtBottom - courtTop) * f;
      canvas.drawLine(
          Offset(w * (.22 - .47 * f), y), Offset(w * (.78 + .47 * f), y), line);
    }
    // A small traveling highlight suggests light catching the court boundary.
    final start = Offset(w * .22, courtTop);
    final end = Offset(-w * .25, courtBottom);
    final p = Offset.lerp(start, end, .15 + t * .55)!;
    final q = Offset.lerp(start, end, .25 + t * .55)!;
    canvas.drawLine(
        p,
        q,
        Paint()
          ..strokeWidth = 1.4
          ..color = AppTheme.limeNeon.withValues(alpha: .14));
    for (var i = 0; i < 7; i++) {
      final x = w * ((i * .173 + .11 + t * .035) % 1);
      final y = h * ((i * .137 + .19 - t * .05) % 1);
      canvas.drawCircle(Offset(x, y), i.isEven ? 1.1 : .65,
          Paint()..color = AppTheme.mintTeal.withValues(alpha: .12));
    }
  }

  @override
  bool shouldRepaint(covariant _CourtAtmosphere oldDelegate) =>
      oldDelegate.showCourt != showCourt || oldDelegate.animation != animation;
}
