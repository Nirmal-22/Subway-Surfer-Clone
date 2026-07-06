import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:metro_dash/game/entities.dart';
import 'package:metro_dash/game/spawner.dart';

void main() {
  test('every chunk leaves at least one train-free lane at every depth', () {
    for (final (i, chunk) in chunkLibrary.indexed) {
      for (var d = 0.0; d <= chunk.length; d += 0.25) {
        final blockedLanes = <int>{};
        for (final o in chunk.obstacles) {
          if (!o.type.isTrain) continue;
          // Moving trains sweep backward over the whole chunk, so treat
          // their lane as blocked at any depth.
          final from = o.type == ObstacleType.movingTrain ? 0.0 : o.at;
          if (d >= from && d <= o.at + o.length) blockedLanes.add(o.lane);
        }
        expect(blockedLanes.length, lessThan(3),
            reason: 'chunk #$i has all lanes train-blocked at depth $d');
      }
    }
  });

  test('chunk placements stay inside the chunk', () {
    for (final (i, chunk) in chunkLibrary.indexed) {
      expect(chunk.length, greaterThan(0));
      for (final o in chunk.obstacles) {
        expect(o.at, inInclusiveRange(0, chunk.length),
            reason: 'chunk #$i obstacle at ${o.at}');
        expect(o.lane, inInclusiveRange(-1, 1));
      }
      for (final c in chunk.coins) {
        expect(c.lane, inInclusiveRange(-1, 1));
        expect(c.h, greaterThanOrEqualTo(0.4));
      }
    }
  });

  test('coins are never buried inside a train', () {
    for (final (i, chunk) in chunkLibrary.indexed) {
      for (final c in chunk.coins) {
        for (final o in chunk.obstacles) {
          if (!o.type.isTrain || o.type == ObstacleType.movingTrain) continue;
          final inside =
              o.lane == c.lane && c.at >= o.at && c.at <= o.at + o.length;
          expect(inside, isFalse,
              reason: 'chunk #$i coin at ${c.at} inside train lane ${o.lane}');
        }
      }
    }
  });

  test('spawner fills ahead and advances its cursor', () {
    final spawner = Spawner(Random(42));
    final obstacles = <Obstacle>[];
    final coins = <Coin>[];
    final powerups = <Powerup>[];

    spawner.fillTo(
      distance: 0,
      ahead: 70,
      speed: 12,
      obstacle: obstacles.add,
      coin: coins.add,
      powerup: powerups.add,
    );
    expect(obstacles, isNotEmpty);
    expect(coins, isNotEmpty);

    // Everything spawned should be ahead of the player.
    for (final o in obstacles) {
      expect(o.d, greaterThan(0));
    }

    // Simulate a long run: powerups eventually appear, difficulty ramps.
    for (var dist = 0.0; dist < 3000; dist += 50) {
      spawner.fillTo(
        distance: dist,
        ahead: 70,
        speed: 25,
        obstacle: obstacles.add,
        coin: coins.add,
        powerup: powerups.add,
      );
    }
    expect(powerups, isNotEmpty);
    expect(spawner.tierFor(3000), 3);
  });

  test('every powerup type shows up over a long run', () {
    final spawner = Spawner(Random(7));
    final seen = <PowerupType>{};
    for (var dist = 0.0; dist < 15000; dist += 50) {
      spawner.fillTo(
        distance: dist,
        ahead: 70,
        speed: 25,
        obstacle: (_) {},
        coin: (_) {},
        powerup: (pu) => seen.add(pu.type),
      );
    }
    expect(seen, PowerupType.values.toSet());
  });
}
