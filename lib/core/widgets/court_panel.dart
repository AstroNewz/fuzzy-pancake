import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A restrained court-line motif shared by the athletic feature panels.
class CourtPanel extends StatelessWidget {
  const CourtPanel(
      {super.key,
      required this.child,
      this.accent = AppTheme.limeNeon,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                      accent.withValues(alpha: .12), AppTheme.cardMid),
                  AppTheme.cardDark
                ]),
            border: Border.all(color: accent.withValues(alpha: .22)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: CustomPaint(
              painter: _CourtLines(accent),
              child: Padding(padding: padding, child: child)),
        ),
      );
}

class _CourtLines extends CustomPainter {
  const _CourtLines(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width * .76, size.height * .45);
    canvas.rotate(-.36);
    final paint = Paint()
      ..color = color.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final court = Rect.fromCenter(center: Offset.zero, width: 140, height: 270);
    canvas.drawRect(court, paint);
    canvas.drawRect(court.deflate(15), paint);
    canvas.drawLine(const Offset(-70, 0), const Offset(70, 0), paint);
    canvas.drawLine(const Offset(-70, -50), const Offset(70, -50), paint);
    canvas.drawLine(const Offset(-70, 50), const Offset(70, 50), paint);
    canvas.drawLine(const Offset(0, -135), const Offset(0, -50), paint);
    canvas.drawLine(const Offset(0, 50), const Offset(0, 135), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CourtLines oldDelegate) => color != oldDelegate.color;
}
