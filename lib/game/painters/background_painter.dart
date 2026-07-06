import 'dart:math';
import 'dart:ui';

import '../projection.dart';
import '../themes.dart';
import 'paint_utils.dart';

/// Sky, sun/moon, stars, clouds and the buildings flanking the track.
void paintBackground(Canvas canvas, Projection p, WorldTheme theme,
    double distance, double time) {
  final w = p.screenW, h = p.screenH;

  // Sky gradient down to the horizon (ground fills the rest).
  final sky = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      Offset(0, p.horizonY * 1.35),
      [theme.skyTop, theme.skyBottom],
    );
  canvas.drawRect(Rect.fromLTWH(0, 0, w, p.horizonY + 2), sky);

  // Ground plane.
  canvas.drawRect(
    Rect.fromLTWH(0, p.horizonY, w, h - p.horizonY),
    Paint()..color = theme.ground,
  );

  // Atmospheric haze where the ground meets the sky, softening the seam.
  final hazeH = h * 0.10;
  canvas.drawRect(
    Rect.fromLTWH(0, p.horizonY - 1, w, hazeH),
    Paint()
      ..shader = Gradient.linear(
        Offset(0, p.horizonY - 1),
        Offset(0, p.horizonY + hazeH),
        [theme.skyBottom.withValues(alpha: 0.55), const Color(0x00000000)],
      ),
  );

  // Stars at night.
  if (theme.nightness > 0.25) {
    final starPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
          .withValues(alpha: 0.85 * ((theme.nightness - 0.25) / 0.75));
    for (var i = 0; i < 40; i++) {
      final sx = hash1(i * 7 + 1) * w;
      final sy = hash1(i * 13 + 5) * p.horizonY * 0.85;
      final tw = 0.6 + 0.9 * hash1(i * 3);
      final blink = 0.6 + 0.4 * sin(time * (1 + hash1(i)) * 2 + i);
      canvas.drawCircle(Offset(sx, sy), tw * blink, starPaint);
    }
  }

  // Sun / moon.
  final sunPos = Offset(w * 0.78, p.horizonY * 0.42);
  canvas.drawCircle(
    sunPos,
    w * 0.055,
    Paint()
      ..color = theme.sun.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
  );
  canvas.drawCircle(sunPos, w * 0.035, Paint()..color = theme.sun);

  // Clouds: soft ellipse pairs drifting slowly.
  final cloudPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
        .withValues(alpha: 0.5 - 0.35 * theme.nightness);
  for (var i = 0; i < 4; i++) {
    final speed = 8.0 + hash1(i * 11) * 6;
    final cx = (hash1(i * 5 + 2) * (w + 260) + time * speed) % (w + 260) - 130;
    final cy = p.horizonY * (0.2 + 0.5 * hash1(i * 17 + 3));
    final s = 0.7 + hash1(i * 23) * 0.7;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy), width: 110 * s, height: 30 * s),
        cloudPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + 35 * s, cy - 12 * s),
            width: 70 * s,
            height: 26 * s),
        cloudPaint);
  }

  _paintBuildings(canvas, p, theme, distance);
}

/// Buildings on both sides, spaced along depth; they scroll with distance
/// and converge to the vanishing point like everything else.
void _paintBuildings(
    Canvas canvas, Projection p, WorldTheme theme, double distance) {
  const spacing = 9.0; // meters between building slots
  final count = (Projection.maxDepth / spacing).ceil() + 1;
  final offset = distance % spacing;

  // Far to near so closer buildings overlap distant ones.
  for (var i = count; i >= 0; i--) {
    final d = i * spacing - offset;
    if (d < -2 || d > Projection.maxDepth) continue;
    // A stable identity for this slot so its look doesn't flicker as it
    // scrolls: index in absolute track space.
    final slot = ((distance + d) / spacing).round();

    for (final side in const [-1, 1]) {
      final rnd = hash1(slot * 31 + side * 7);
      if (rnd < 0.18) continue; // occasional gap in the skyline

      final lane = side * (2.9 + 0.9 * hash1(slot * 13 + side));
      final widthLn = 1.1 + 0.8 * hash1(slot * 17 + side * 3);
      final hMeters = 6 + 14 * hash1(slot * 23 + side * 5);

      final fNear = p.f(d);
      final fFar = p.f(d + spacing * 0.85);
      final baseY = p.screenY(d);
      final baseYFar = p.screenY(d + spacing * 0.85);
      final topY = p.screenY(d, h: hMeters);
      final topYFar = p.screenY(d + spacing * 0.85, h: hMeters);

      final xNearIn = p.screenX(d, lane);
      final xNearOut = p.screenX(d, lane + side * widthLn);
      final xFarIn = p.screenX(d + spacing * 0.85, lane);

      final tint = hash1(slot * 41 + side) * 0.25 - 0.1;
      final wall = fog(shade(theme.building, tint), theme.skyBottom, fNear);
      final wallSide = fog(
          shade(theme.building, tint - 0.18), theme.skyBottom, (fNear + fFar) / 2);

      // Inward-facing side wall (visible face along the track).
      canvas.drawPath(
        quad(Offset(xNearIn, baseY), Offset(xNearIn, topY),
            Offset(xFarIn, topYFar), Offset(xFarIn, baseYFar)),
        Paint()..color = wallSide,
      );
      // Front face.
      canvas.drawPath(
        quad(Offset(xNearIn, baseY), Offset(xNearOut, baseY),
            Offset(xNearOut, topY), Offset(xNearIn, topY)),
        Paint()..color = wall,
      );

      // Windows on the front face; lit at night.
      final litAlpha = theme.nightness * 0.9;
      final winPaint = Paint()
        ..color = litAlpha > 0.1
            ? Color(0xFFFFE082).withValues(alpha: litAlpha)
            : shade(wall, -0.25);
      final rows = (hMeters / 2.6).floor();
      final faceW = (xNearOut - xNearIn).abs();
      if (faceW > 6) {
        for (var r = 0; r < rows; r++) {
          for (var c = 0; c < 3; c++) {
            if (hash1(slot * 101 + r * 7 + c * 3 + side) < 0.35) continue;
            final wx = xNearIn +
                (xNearOut - xNearIn) * (0.18 + 0.3 * c) ;
            final wy = baseY + (topY - baseY) * ((r + 0.55) / rows);
            canvas.drawRect(
              Rect.fromCenter(
                  center: Offset(wx, wy),
                  width: faceW * 0.14,
                  height: (baseY - topY).abs() / rows * 0.34),
              winPaint,
            );
          }
        }
      }
    }
  }
}
