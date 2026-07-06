import 'package:flutter_test/flutter_test.dart';
import 'package:metro_dash/game/themes.dart';

void main() {
  test('theme blend is continuous across segment boundaries', () {
    // Just before and just after each boundary must be near-identical, so
    // the sky never pops as a new segment starts.
    for (final boundary in [1200.0, 2400.0, 3600.0]) {
      final before = WorldTheme.forDistance(boundary - 0.5);
      final after = WorldTheme.forDistance(boundary + 0.5);
      expect((before.nightness - after.nightness).abs(), lessThan(0.02),
          reason: 'nightness jump at $boundary m');
      expect(
        (before.skyTop.r - after.skyTop.r).abs() +
            (before.skyTop.g - after.skyTop.g).abs() +
            (before.skyTop.b - after.skyTop.b).abs(),
        lessThan(0.05),
        reason: 'sky color jump at $boundary m',
      );
    }
  });

  test('cycle wraps night back to day', () {
    // Segment 3 (3600 m+) should be day again.
    expect(WorldTheme.forDistance(3700).nightness, 0);
  });

  test('skin lookup falls back to the default', () {
    expect(CharacterSkin.byId('nope').id, 'dash');
    expect(CharacterSkin.byId('neon').id, 'neon');
  });
}
