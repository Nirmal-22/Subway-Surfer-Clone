import 'dart:ui';

import '../projection.dart';
import '../themes.dart';
import 'paint_utils.dart';

/// Track bed, rails, sleepers and the platform warning lines. The sleeper
/// scroll is what sells the sense of speed.
void paintTrack(
    Canvas canvas, Projection p, WorldTheme theme, double distance) {
  const far = Projection.maxDepth;

  // Track bed: trapezoid from horizon to the bottom of the screen.
  final bedHalfLn = 1.75; // lane units to the edge of the ballast
  final bed = quad(
    Offset(p.screenX(-4.5, -bedHalfLn), p.screenY(-4.5)),
    Offset(p.screenX(far, -bedHalfLn), p.screenY(far)),
    Offset(p.screenX(far, bedHalfLn), p.screenY(far)),
    Offset(p.screenX(-4.5, bedHalfLn), p.screenY(-4.5)),
  );
  canvas.drawPath(bed, Paint()..color = theme.track);

  // Sleepers (railroad ties) scrolling toward the camera.
  const tieSpacing = 2.4;
  final offset = distance % tieSpacing;
  final tiePaint = Paint()..color = theme.tie;
  for (var d = -offset - 2; d < far; d += tieSpacing) {
    if (d < -4) continue;
    final y = p.screenY(d);
    final f = p.f(d);
    final x1 = p.screenX(d, -1.6);
    final x2 = p.screenX(d, 1.6);
    tiePaint.color = fog(theme.tie, theme.skyBottom, f);
    canvas.drawRect(
      Rect.fromLTRB(x1, y - 1.6 * f, x2, y + 1.6 * f),
      tiePaint,
    );
  }

  // Rails: two per lane, at ±0.32 lane units around each lane center.
  final railPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (final lane in const [-1.0, 0.0, 1.0]) {
    for (final off in const [-0.32, 0.32]) {
      final ln = lane + off;
      final path = Path()
        ..moveTo(p.screenX(-4.5, ln), p.screenY(-4.5))
        ..lineTo(p.screenX(far, ln), p.screenY(far));
      railPaint
        ..color = theme.rail
        ..strokeWidth = 2.6;
      canvas.drawPath(path, railPaint);
      // Specular top edge of the rail.
      railPaint
        ..color = shade(theme.rail, 0.55)
        ..strokeWidth = 1.0;
      canvas.drawPath(path, railPaint);
    }
  }

  // Yellow platform warning strips at both edges of the bed.
  for (final side in const [-1, 1]) {
    final ln = side * 1.62;
    final stripe = Path()
      ..moveTo(p.screenX(-4.5, ln), p.screenY(-4.5))
      ..lineTo(p.screenX(far, ln), p.screenY(far));
    canvas.drawPath(
      stripe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = const Color(0xFFD9B23A)
            .withValues(alpha: 0.8 - theme.nightness * 0.25),
    );
  }
}
