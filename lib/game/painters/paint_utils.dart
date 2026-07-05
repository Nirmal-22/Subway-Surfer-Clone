import 'dart:ui';

/// Convex quad path from four corners (clockwise).
Path quad(Offset a, Offset b, Offset c, Offset d) => Path()
  ..moveTo(a.dx, a.dy)
  ..lineTo(b.dx, b.dy)
  ..lineTo(c.dx, c.dy)
  ..lineTo(d.dx, d.dy)
  ..close();

/// Darken (amount < 0) or lighten (amount > 0) a color.
Color shade(Color color, double amount) {
  if (amount >= 0) return Color.lerp(color, const Color(0xFFFFFFFF), amount)!;
  return Color.lerp(color, const Color(0xFF000000), -amount)!;
}

/// Fades distant things toward the sky color to fake atmospheric depth.
/// [f] is the perspective factor (1 near, 0 far).
Color fog(Color base, Color sky, double f) {
  final t = (1 - f).clamp(0.0, 1.0);
  return Color.lerp(base, sky, t * t * 0.75)!;
}

/// Cheap deterministic hash → [0, 1). Used to vary buildings/trains without
/// storing state.
double hash1(int n) {
  var x = n * 374761393 + 668265263;
  x = (x ^ (x >> 13)) * 1274126177;
  x = x ^ (x >> 16);
  return (x & 0x7fffffff) / 0x7fffffff;
}
