import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;

import '../entities.dart';
import '../projection.dart';
import '../themes.dart';
import 'paint_utils.dart';

const _trainColors = [
  Color(0xFFC62828),
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFEF6C00),
  Color(0xFF00838F),
  Color(0xFF6A1B9A),
];

void paintObstacle(Canvas canvas, Projection p, WorldTheme theme,
    Obstacle o, double time) {
  switch (o.type) {
    case ObstacleType.train:
    case ObstacleType.movingTrain:
      _paintTrain(canvas, p, theme, o, time);
    case ObstacleType.hurdle:
      _paintHurdle(canvas, p, theme, o);
    case ObstacleType.gate:
      _paintGate(canvas, p, theme, o);
  }
}

void _paintTrain(Canvas canvas, Projection p, WorldTheme theme, Obstacle o,
    double time) {
  const halfW = 0.52; // lane units
  const height = 3.1; // meters
  final lane = o.lane.toDouble();

  final d0 = max(o.d, -3.5);
  final d1 = min(o.d + o.length, Projection.maxDepth);
  if (d1 <= d0) return;

  final fN = p.f(d0);
  final body = fog(
      shade(_trainColors[o.colorSeed % _trainColors.length],
          hash1(o.colorSeed) * 0.15 - 0.05),
      theme.skyBottom,
      fN);

  final xNL = p.screenX(d0, lane - halfW);
  final xNR = p.screenX(d0, lane + halfW);
  final yNB = p.screenY(d0);
  final yNT = p.screenY(d0, h: height);
  final xFL = p.screenX(d1, lane - halfW);
  final xFR = p.screenX(d1, lane + halfW);
  final yFB = p.screenY(d1);
  final yFT = p.screenY(d1, h: height);

  // Roof.
  canvas.drawPath(
    quad(Offset(xNL, yNT), Offset(xNR, yNT), Offset(xFR, yFT),
        Offset(xFL, yFT)),
    Paint()..color = shade(body, 0.28),
  );

  // Visible side wall (the one facing the track center).
  final centerX = p.centerX;
  final seesRight = p.screenX(d0, lane) < centerX;
  final sxN = seesRight ? xNR : xNL;
  final sxF = seesRight ? xFR : xFL;
  canvas.drawPath(
    quad(Offset(sxN, yNB), Offset(sxN, yNT), Offset(sxF, yFT),
        Offset(sxF, yFB)),
    Paint()..color = shade(body, -0.22),
  );

  // Side windows.
  final winPaint = Paint()
    ..color = theme.nightness > 0.4
        ? const Color(0xFFFFE082).withValues(alpha: 0.9)
        : const Color(0xFF90CAF9);
  const winSpacing = 3.2;
  for (var wd = d0 + 2.0; wd < d1 - 1.2; wd += winSpacing) {
    final ln = lane + (seesRight ? halfW : -halfW);
    final x1 = p.screenX(wd, ln);
    final x2 = p.screenX(wd + 1.7, ln);
    final y1 = p.screenY(wd, h: 2.35);
    final y2 = p.screenY(wd, h: 1.55);
    final y1b = p.screenY(wd + 1.7, h: 2.35);
    final y2b = p.screenY(wd + 1.7, h: 1.55);
    canvas.drawPath(
      quad(Offset(x1, y1), Offset(x2, y1b), Offset(x2, y2b), Offset(x1, y2)),
      winPaint,
    );
  }

  // Front face.
  final front = Rect.fromLTRB(xNL, yNT, xNR, yNB);
  final r = (xNR - xNL) * 0.08;
  canvas.drawRRect(
      RRect.fromRectAndCorners(front,
          topLeft: Radius.circular(r * 2), topRight: Radius.circular(r * 2)),
      Paint()..color = body);

  final fw = front.width;
  // Windshield.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(front.left + fw * 0.12, front.top + front.height * 0.10,
          fw * 0.76, front.height * 0.30),
      Radius.circular(r * 1.5),
    ),
    Paint()..color = const Color(0xFF263238).withValues(alpha: 0.92),
  );
  // Bumper stripe.
  canvas.drawRect(
    Rect.fromLTWH(front.left, front.top + front.height * 0.62, fw,
        front.height * 0.12),
    Paint()..color = shade(body, -0.35),
  );
  // Warning chevrons on moving trains.
  if (o.type == ObstacleType.movingTrain) {
    final stripe = Paint()..color = const Color(0xFFFFD600);
    final yTop = front.top + front.height * 0.62;
    final hS = front.height * 0.12;
    for (var i = 0; i < 4; i++) {
      final x = front.left + fw * (0.05 + i * 0.25);
      canvas.drawPath(
        quad(Offset(x, yTop + hS), Offset(x + fw * 0.08, yTop),
            Offset(x + fw * 0.16, yTop), Offset(x + fw * 0.08, yTop + hS)),
        stripe,
      );
    }
  }
  // Headlights (glowing at night or when moving).
  final lit = theme.nightness > 0.3 || o.type == ObstacleType.movingTrain;
  final lightColor = lit ? const Color(0xFFFFF59D) : const Color(0xFFE0E0E0);
  for (final sideX in [front.left + fw * 0.18, front.right - fw * 0.18]) {
    final c = Offset(sideX, front.bottom - front.height * 0.16);
    if (lit) {
      canvas.drawCircle(
          c,
          fw * 0.075,
          Paint()
            ..color = lightColor.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    canvas.drawCircle(c, fw * 0.045, Paint()..color = lightColor);
  }
}

void _paintHurdle(Canvas canvas, Projection p, WorldTheme theme, Obstacle o) {
  const halfW = 0.44;
  final lane = o.lane.toDouble();
  final d = o.d;
  if (d < -3 || d > Projection.maxDepth) return;

  final f = p.f(d);
  final xL = p.screenX(d, lane - halfW);
  final xR = p.screenX(d, lane + halfW);
  final yB = p.screenY(d);
  final yBarTop = p.screenY(d, h: 1.0);
  final yBarBot = p.screenY(d, h: 0.58);

  final legPaint = Paint()
    ..color = fog(const Color(0xFF78909C), theme.skyBottom, f)
    ..strokeWidth = 3 * f
    ..strokeCap = StrokeCap.round;
  for (final x in [xL + (xR - xL) * 0.08, xR - (xR - xL) * 0.08]) {
    canvas.drawLine(Offset(x, yB), Offset(x, yBarBot), legPaint);
  }

  // Striped bar.
  final bar = Rect.fromLTRB(xL, yBarTop, xR, yBarBot);
  canvas.drawRect(bar, Paint()..color = fog(const Color(0xFFEEEEEE), theme.skyBottom, f));
  canvas.save();
  canvas.clipRect(bar);
  final red = Paint()..color = fog(const Color(0xFFE53935), theme.skyBottom, f);
  final w = bar.width;
  for (var i = -1; i < 6; i++) {
    final x = bar.left + i * w / 3;
    canvas.drawPath(
      quad(
        Offset(x, bar.bottom),
        Offset(x + w / 6, bar.bottom),
        Offset(x + w / 6 + bar.height * 0.6, bar.top),
        Offset(x + bar.height * 0.6, bar.top),
      ),
      red,
    );
  }
  canvas.restore();
  canvas.drawRect(
      bar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * f
        ..color = shade(theme.rail, -0.1));
}

void _paintGate(Canvas canvas, Projection p, WorldTheme theme, Obstacle o) {
  const halfW = 0.5;
  final lane = o.lane.toDouble();
  final d = o.d;
  if (d < -3 || d > Projection.maxDepth) return;

  final f = p.f(d);
  final xL = p.screenX(d, lane - halfW);
  final xR = p.screenX(d, lane + halfW);
  final yB = p.screenY(d);
  final poleTop = p.screenY(d, h: 2.9);

  final polePaint = Paint()
    ..color = fog(const Color(0xFF546E7A), theme.skyBottom, f)
    ..strokeWidth = 4.5 * f
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(xL, yB), Offset(xL, poleTop), polePaint);
  canvas.drawLine(Offset(xR, yB), Offset(xR, poleTop), polePaint);

  // Sign panel — the player rolls under the gap below it.
  final panel = Rect.fromLTRB(
      xL, p.screenY(d, h: 2.75), xR, p.screenY(d, h: 1.15));
  canvas.drawRRect(
    RRect.fromRectAndRadius(panel, Radius.circular(3 * f)),
    Paint()..color = fog(const Color(0xFFF9A825), theme.skyBottom, f),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(panel.deflate(2.5 * f), Radius.circular(2 * f)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * f
      ..color = const Color(0xFF5D4037),
  );
  // Down chevron hinting "roll under".
  final cx = panel.center.dx;
  final chevW = panel.width * 0.22;
  final chev = Paint()
    ..color = const Color(0xFF5D4037)
    ..strokeWidth = 3.5 * f
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final cy = panel.center.dy - panel.height * 0.12;
  canvas.drawLine(Offset(cx - chevW, cy), Offset(cx, cy + panel.height * 0.28), chev);
  canvas.drawLine(Offset(cx + chevW, cy), Offset(cx, cy + panel.height * 0.28), chev);

  // Hazard stripe on the panel's bottom edge.
  canvas.drawRect(
    Rect.fromLTRB(panel.left, panel.bottom - 3.5 * f, panel.right, panel.bottom),
    Paint()..color = const Color(0xFF5D4037),
  );
}

void paintCoin(Canvas canvas, Projection p, Coin c, double time) {
  if (c.d < -2 || c.d > Projection.maxDepth) return;
  final f = p.f(c.d);
  final bob = 0.06 * sin(time * 3 + c.d * 0.7);
  final center = p.project(c.d, c.lane, h: c.h + bob);
  final r = 0.30 * p.pxPerMeter * f;
  if (r < 0.8) return;

  // Ground shadow.
  canvas.drawOval(
    Rect.fromCenter(
        center: Offset(center.dx, p.screenY(c.d)),
        width: r * 1.4,
        height: r * 0.4),
    Paint()..color = const Color(0x33000000),
  );

  // Spin by squashing horizontally.
  final spin = cos(time * 5 + c.d * 0.5).abs().clamp(0.15, 1.0);
  final rect = Rect.fromCenter(
      center: center, width: 2 * r * spin, height: 2 * r);
  canvas.drawOval(rect, Paint()..color = const Color(0xFFF9A825));
  canvas.drawOval(rect.deflate(r * 0.22), Paint()..color = const Color(0xFFFFD54F));
  canvas.drawRect(
    Rect.fromCenter(
        center: center, width: r * 0.28 * spin, height: r * 0.9),
    Paint()..color = const Color(0xFFF9A825),
  );
}

final _labelCache = <String, TextPainter>{};

TextPainter _label(String text, double size, Color color) {
  final key = '$text|${size.round()}|${color.toARGB32()}';
  return _labelCache.putIfAbsent(key, () {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  });
}

void paintPowerup(Canvas canvas, Projection p, Powerup pu, double time) {
  if (pu.d < -2 || pu.d > Projection.maxDepth) return;
  final f = p.f(pu.d);
  final bob = 0.12 * sin(time * 2.4 + pu.d);
  final center = p.project(pu.d, pu.lane.toDouble(), h: 1.05 + bob);
  final r = 0.5 * p.pxPerMeter * f;
  if (r < 1.5) return;

  final color = switch (pu.type) {
    PowerupType.magnet => const Color(0xFFE53935),
    PowerupType.multiplier => const Color(0xFF8E24AA),
    PowerupType.shield => const Color(0xFF039BE5),
  };

  // Glow + bubble.
  canvas.drawCircle(
      center,
      r * 1.25,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  canvas.drawCircle(
      center, r, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85));
  canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..color = color);

  switch (pu.type) {
    case PowerupType.magnet:
      // Horseshoe magnet.
      final mr = r * 0.52;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.3
        ..strokeCap = StrokeCap.butt
        ..color = color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: mr), pi, pi,
          false, stroke);
      final tip = Paint()..color = const Color(0xFFB0BEC5);
      for (final s in const [-1, 1]) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(center.dx + s * mr, center.dy + r * 0.28),
              width: r * 0.3,
              height: r * 0.22),
          tip,
        );
      }
    case PowerupType.multiplier:
      final tp = _label('2×', r * 1.05, color);
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    case PowerupType.shield:
      final path = Path()
        ..moveTo(center.dx, center.dy - r * 0.55)
        ..lineTo(center.dx + r * 0.45, center.dy - r * 0.3)
        ..lineTo(center.dx + r * 0.45, center.dy + r * 0.1)
        ..quadraticBezierTo(center.dx + r * 0.4, center.dy + r * 0.45,
            center.dx, center.dy + r * 0.62)
        ..quadraticBezierTo(center.dx - r * 0.4, center.dy + r * 0.45,
            center.dx - r * 0.45, center.dy + r * 0.1)
        ..lineTo(center.dx - r * 0.45, center.dy - r * 0.3)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
  }
}
