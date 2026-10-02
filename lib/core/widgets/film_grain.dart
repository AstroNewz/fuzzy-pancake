import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// Deterministic, static film grain. The cached tile is recorded once and its
/// repaint boundary is independent of all of the app's animated lighting.
class FilmGrain extends StatelessWidget {
  const FilmGrain({super.key, this.intensity = .65});
  final double intensity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: Opacity(
              opacity: intensity.clamp(0, 1),
              child: const CustomPaint(painter: _GrainPainter()),
            ),
          ),
        ),
      );
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();
  static const _tileSize = 192.0;
  static final ui.Picture _tile = _recordTile();

  static ui.Picture _recordTile() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final random = Random(94);
    for (var layer = 0; layer < 4; layer++) {
      final points = Float32List(10000);
      for (var i = 0; i < points.length; i++) {
        points[i] = random.nextDouble() * _tileSize;
      }
      canvas.drawRawPoints(
          ui.PointMode.points,
          points,
          Paint()
            ..color =
                layer.isEven ? const Color(0x10FFFFFF) : const Color(0x20000000)
            ..strokeWidth = layer < 2 ? .65 : 1.05
            ..isAntiAlias = false);
    }
    return recorder.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    for (double y = 0; y < size.height; y += _tileSize) {
      for (double x = 0; x < size.width; x += _tileSize) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPicture(_tile);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) => false;
}
