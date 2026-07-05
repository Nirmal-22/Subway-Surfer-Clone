import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:metro_dash/game/projection.dart';

void main() {
  final p = Projection(const Size(400, 800));

  test('player plane maps to identity scale and fixed screen row', () {
    expect(p.f(0), 1.0);
    expect(p.screenY(0), p.playerPlaneY);
    expect(p.screenX(0, 0), p.centerX);
  });

  test('perspective factor decreases monotonically with depth', () {
    var prev = p.f(0);
    for (var d = 1.0; d <= Projection.maxDepth; d += 1) {
      final f = p.f(d);
      expect(f, lessThan(prev));
      expect(f, greaterThan(0));
      prev = f;
    }
  });

  test('screen y approaches the horizon with depth, never crosses it', () {
    var prev = p.screenY(0);
    for (var d = 1.0; d <= Projection.maxDepth; d += 1) {
      final y = p.screenY(d);
      expect(y, lessThan(prev));
      expect(y, greaterThan(p.horizonY));
      prev = y;
    }
  });

  test('lanes are symmetric around the center', () {
    for (final d in [0.0, 10.0, 40.0]) {
      final left = p.screenX(d, -1);
      final right = p.screenX(d, 1);
      expect(p.centerX - left, closeTo(right - p.centerX, 1e-6));
      // Lanes converge as depth grows.
      if (d > 0) expect(right - left, lessThan(2 * p.laneSpacing));
    }
  });

  test('height lifts things up the screen, scaled by depth', () {
    expect(p.screenY(0, h: 1), lessThan(p.screenY(0)));
    final liftNear = p.screenY(0) - p.screenY(0, h: 1);
    final liftFar = p.screenY(50) - p.screenY(50, h: 1);
    expect(liftFar, lessThan(liftNear));
  });

  test('things behind the player plane grow instead of shrinking', () {
    expect(p.f(-2), greaterThan(1));
  });
}
