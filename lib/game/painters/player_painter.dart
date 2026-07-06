import 'dart:math';
import 'dart:ui';

import '../player.dart';
import '../projection.dart';
import '../themes.dart';
import 'paint_utils.dart';

/// Draws the runner at the player plane. Everything is derived from `u`
/// (pixels per meter) so the character scales with screen size.
void paintPlayer(
  Canvas canvas,
  Projection p,
  CharacterSkin skin,
  Player player,
  double time, {
  double shieldT = 0,
  double invulnT = 0,
  double crashT = 0,
}) {
  final u = p.pxPerMeter;
  final x = p.screenX(0, player.lanePos);
  final groundY = p.playerPlaneY;
  final feetY = groundY - player.airHeight * u;

  // Shadow stays on the ground and shrinks while airborne.
  final air = (player.airHeight / Player.jumpHeight).clamp(0.0, 1.0);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(x, groundY + u * 0.04),
      width: u * (0.95 - 0.3 * air),
      height: u * (0.22 - 0.07 * air),
    ),
    Paint()..color = Color(0x44000000 - ((air * 0x22).round() << 24)),
  );

  // Classic invulnerability flicker after a shield pop or revive.
  if (invulnT > 0 && crashT == 0 && sin(time * 18) < -0.2) return;

  canvas.save();
  canvas.translate(x, feetY);

  // Lean into lane changes; tip over while crashing.
  final laneVel = (player.lane - player.lanePos).clamp(-1.0, 1.0);
  canvas.rotate(laneVel * 0.18 + crashT * 1.25);

  if (player.isRolling && crashT == 0) {
    _paintRollingBall(canvas, skin, u, time);
    canvas.restore();
    _paintShield(canvas, x, feetY - u * 0.5, u, shieldT);
    return;
  }

  final s = sin(player.runPhase);
  final jumping = player.isJumping;
  final tuck = jumping ? sin(pi * player.actionT.clamp(0.0, 1.0)) : 0.0;

  final limb = Paint()
    ..strokeWidth = u * 0.14
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final hipY = -u * 0.78;
  final shoulderY = -u * 1.30;

  // Back leg / arm first so they layer behind the torso.
  limb.color = shade(skin.pants, -0.25);
  _leg(canvas, limb, u, hipY, -s, tuck, back: true);
  limb.color = shade(skin.hoodie, -0.3);
  _arm(canvas, limb, u, shoulderY, -s, jumping, back: true);

  // Torso.
  final torso = RRect.fromRectAndRadius(
    Rect.fromLTWH(-u * 0.24, shoulderY - u * 0.06, u * 0.48, u * 0.62),
    Radius.circular(u * 0.16),
  );
  canvas.drawRRect(torso, Paint()..color = skin.hoodie);
  // Hoodie pocket + zipper.
  canvas.drawLine(
    Offset(0, shoulderY + u * 0.02),
    Offset(0, hipY - u * 0.04),
    Paint()
      ..color = skin.hoodieDark
      ..strokeWidth = u * 0.035,
  );
  canvas.drawCircle(Offset(-u * 0.08, shoulderY + u * 0.08), u * 0.03,
      Paint()..color = skin.accent);
  canvas.drawCircle(Offset(u * 0.08, shoulderY + u * 0.08), u * 0.03,
      Paint()..color = skin.accent);

  // Front leg / arm.
  limb.color = skin.pants;
  _leg(canvas, limb, u, hipY, s, tuck, back: false);
  limb.color = skin.hoodie;
  _arm(canvas, limb, u, shoulderY, s, jumping, back: false);

  // Head.
  final headC = Offset(0, shoulderY - u * 0.26);
  canvas.drawCircle(headC, u * 0.20, Paint()..color = skin.skin);
  // Hair.
  canvas.drawArc(
    Rect.fromCircle(center: headC, radius: u * 0.21),
    pi * 0.95,
    pi * 1.1,
    true,
    Paint()..color = skin.hair,
  );
  // Cap peak (accent).
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-u * 0.26, headC.dy - u * 0.16, u * 0.30, u * 0.07),
      Radius.circular(u * 0.03),
    ),
    Paint()..color = skin.accent,
  );

  canvas.restore();
  _paintShield(canvas, x, feetY - u * 0.85, u, shieldT);
}

void _leg(Canvas canvas, Paint paint, double u, double hipY, double swing,
    double tuck, {required bool back}) {
  final hx = back ? -u * 0.07 : u * 0.07;
  final kneeX = hx + swing * u * 0.16;
  final kneeY = hipY + u * 0.38 - tuck * u * 0.18;
  final footX = hx + swing * u * 0.30;
  final footY = tuck > 0.2 ? kneeY + u * 0.18 : 0.0;
  final path = Path()
    ..moveTo(hx, hipY)
    ..lineTo(kneeX, kneeY)
    ..lineTo(footX, footY);
  canvas.drawPath(path, paint);
}

void _arm(Canvas canvas, Paint paint, double u, double shoulderY,
    double swing, bool jumping, {required bool back}) {
  final sx = back ? -u * 0.22 : u * 0.22;
  if (jumping) {
    // Arms thrown up.
    canvas.drawLine(Offset(sx, shoulderY + u * 0.05),
        Offset(sx * 1.9, shoulderY - u * 0.30), paint);
    return;
  }
  final ex = sx - swing * u * 0.20;
  final ey = shoulderY + u * 0.34;
  final hxx = sx - swing * u * 0.34;
  final path = Path()
    ..moveTo(sx, shoulderY + u * 0.05)
    ..lineTo(ex, ey)
    ..lineTo(hxx, ey + u * 0.1);
  canvas.drawPath(path, paint);
}

void _paintRollingBall(Canvas canvas, CharacterSkin skin, double u, double time) {
  final c = Offset(0, -u * 0.42);
  canvas.drawCircle(c, u * 0.44, Paint()..color = skin.hoodie);
  canvas.drawCircle(c, u * 0.44,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.05
        ..color = skin.hoodieDark);
  // Spin streaks.
  final arc = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = u * 0.08
    ..strokeCap = StrokeCap.round
    ..color = skin.pants;
  final a = time * 14;
  canvas.drawArc(Rect.fromCircle(center: c, radius: u * 0.26), a, 1.6, false, arc);
  canvas.drawArc(Rect.fromCircle(center: c, radius: u * 0.26), a + pi, 1.6,
      false, arc..color = skin.accent);
}

void _paintShield(Canvas canvas, double x, double y, double u, double shieldT) {
  if (shieldT <= 0) return;
  // Blink when about to expire.
  final blink = shieldT < 3 ? (sin(shieldT * 12) > -0.2 ? 1.0 : 0.25) : 1.0;
  final c = Offset(x, y);
  canvas.drawCircle(
      c,
      u * 1.05,
      Paint()
        ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.18 * blink));
  canvas.drawCircle(
      c,
      u * 1.05,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.05
        ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.6 * blink));
}

/// The inspector chasing the player. `chase` 0 = offscreen, 1 = right on
/// their heels. Drawn between the camera and the player, slightly oversized.
void paintGuard(Canvas canvas, Projection p, double guardLane, double chase,
    double time) {
  if (chase <= 0.01) return;
  final f = p.f(-1.8);
  final u = p.pxPerMeter * f;
  final x = p.screenX(-1.8, guardLane);
  // Slides up from below the screen as chase increases.
  final feetY = p.playerPlaneY + u * 0.5 + (1 - chase) * p.screenH * 0.30;

  canvas.save();
  canvas.translate(x, feetY);

  const navy = Color(0xFF283A5B);
  const navyDark = Color(0xFF1B2840);
  const skinC = Color(0xFFE0AC7E);

  final s = sin(time * 11);
  final limb = Paint()
    ..strokeWidth = u * 0.16
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final hipY = -u * 0.85;
  final shoulderY = -u * 1.45;

  limb.color = navyDark;
  canvas.drawLine(Offset(-u * 0.08, hipY),
      Offset(-u * 0.08 - s * u * 0.28, 0), limb);
  limb.color = navy;
  canvas.drawLine(Offset(u * 0.08, hipY),
      Offset(u * 0.08 + s * u * 0.28, 0), limb);

  // Torso, a bit burly.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-u * 0.30, shoulderY - u * 0.05, u * 0.60, u * 0.70),
      Radius.circular(u * 0.18),
    ),
    Paint()..color = navy,
  );
  // Badge.
  canvas.drawCircle(Offset(-u * 0.14, shoulderY + u * 0.16), u * 0.045,
      Paint()..color = const Color(0xFFFFD54F));

  // Arms: one pumping, one waving a baton.
  limb.color = navy;
  canvas.drawLine(Offset(-u * 0.26, shoulderY + u * 0.06),
      Offset(-u * 0.26 - s * u * 0.22, shoulderY + u * 0.40), limb);
  final batonHand = Offset(u * 0.30 + s * u * 0.06, shoulderY - u * 0.15);
  canvas.drawLine(Offset(u * 0.26, shoulderY + u * 0.06), batonHand, limb);
  canvas.drawLine(
    batonHand,
    batonHand + Offset(u * 0.22, -u * 0.18 - s * u * 0.06),
    Paint()
      ..strokeWidth = u * 0.07
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8D6E63),
  );

  // Head with cap.
  final headC = Offset(0, shoulderY - u * 0.28);
  canvas.drawCircle(headC, u * 0.21, Paint()..color = skinC);
  canvas.drawArc(
    Rect.fromCircle(center: headC, radius: u * 0.22),
    pi,
    pi,
    true,
    Paint()..color = navyDark,
  );
  canvas.drawRect(
    Rect.fromLTWH(-u * 0.28, headC.dy - u * 0.08, u * 0.36, u * 0.06),
    Paint()..color = navyDark,
  );
  // Mustache.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-u * 0.09, headC.dy + u * 0.07, u * 0.18, u * 0.045),
      Radius.circular(u * 0.02),
    ),
    Paint()..color = const Color(0xFF4E342E),
  );

  canvas.restore();
}

/// Static standing pose used by the shop's character cards.
void paintCharacterPreview(Canvas canvas, Rect rect, CharacterSkin skin) {
  final u = rect.height / 2.1;
  canvas.save();
  canvas.translate(rect.center.dx, rect.bottom - u * 0.1);

  final limb = Paint()
    ..strokeWidth = u * 0.14
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final hipY = -u * 0.78;
  final shoulderY = -u * 1.30;

  limb.color = shade(skin.pants, -0.25);
  canvas.drawLine(Offset(-u * 0.09, hipY), Offset(-u * 0.14, 0), limb);
  limb.color = skin.pants;
  canvas.drawLine(Offset(u * 0.09, hipY), Offset(u * 0.14, 0), limb);

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-u * 0.24, shoulderY - u * 0.06, u * 0.48, u * 0.62),
      Radius.circular(u * 0.16),
    ),
    Paint()..color = skin.hoodie,
  );
  canvas.drawLine(
    Offset(0, shoulderY + u * 0.02),
    Offset(0, hipY - u * 0.04),
    Paint()
      ..color = skin.hoodieDark
      ..strokeWidth = u * 0.035,
  );

  limb.color = shade(skin.hoodie, -0.3);
  canvas.drawLine(Offset(-u * 0.24, shoulderY + u * 0.06),
      Offset(-u * 0.34, shoulderY + u * 0.5), limb);
  limb.color = skin.hoodie;
  canvas.drawLine(Offset(u * 0.24, shoulderY + u * 0.06),
      Offset(u * 0.34, shoulderY + u * 0.5), limb);

  final headC = Offset(0, shoulderY - u * 0.26);
  canvas.drawCircle(headC, u * 0.20, Paint()..color = skin.skin);
  canvas.drawArc(
    Rect.fromCircle(center: headC, radius: u * 0.21),
    pi * 0.95,
    pi * 1.1,
    true,
    Paint()..color = skin.hair,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-u * 0.26, headC.dy - u * 0.16, u * 0.30, u * 0.07),
      Radius.circular(u * 0.03),
    ),
    Paint()..color = skin.accent,
  );

  canvas.restore();
}
