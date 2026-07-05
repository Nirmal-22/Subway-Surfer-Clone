import 'dart:math';

import 'entities.dart';

/// A placement inside a [Chunk], at depth `at` meters from the chunk start.
class ObstacleSpec {
  const ObstacleSpec(this.type, this.lane, this.at,
      {this.length = 1.0, this.speed = 0});

  final ObstacleType type;
  final int lane;
  final double at;
  final double length;
  final double speed;
}

class CoinSpec {
  const CoinSpec(this.lane, this.at, {this.h = 0.55});

  final int lane;
  final double at;
  final double h;
}

/// A hand-authored obstacle pattern. Difficulty 1..3 gates when it can
/// appear. Every chunk must be survivable: trains never cover all three
/// lanes at the same depth (verified by a unit test).
class Chunk {
  const Chunk({
    required this.length,
    required this.obstacles,
    this.coins = const [],
    this.difficulty = 1,
  });

  final double length;
  final List<ObstacleSpec> obstacles;
  final List<CoinSpec> coins;
  final int difficulty;
}

/// A straight run of coins along one lane.
List<CoinSpec> coinRow(int lane, double start,
    {int count = 6, double spacing = 2.2, double h = 0.55}) {
  return [
    for (var i = 0; i < count; i++) CoinSpec(lane, start + i * spacing, h: h)
  ];
}

/// An arc of coins over a jump (e.g. above a hurdle at `centerAt`).
List<CoinSpec> coinArc(int lane, double centerAt, {int count = 5}) {
  const span = 7.0;
  return [
    for (var i = 0; i < count; i++)
      CoinSpec(
        lane,
        centerAt - span / 2 + span * i / (count - 1),
        h: 0.55 + 1.5 * sin(pi * i / (count - 1)),
      )
  ];
}

final List<Chunk> chunkLibrary = [
  // --- Difficulty 1: single-action intros ---------------------------------
  Chunk(
    length: 22,
    difficulty: 1,
    obstacles: const [ObstacleSpec(ObstacleType.hurdle, 0, 10)],
    coins: coinArc(0, 10),
  ),
  Chunk(
    length: 22,
    difficulty: 1,
    obstacles: const [ObstacleSpec(ObstacleType.gate, 0, 10)],
    coins: coinRow(0, 6, count: 5, h: 0.45),
  ),
  Chunk(
    length: 26,
    difficulty: 1,
    obstacles: const [
      ObstacleSpec(ObstacleType.hurdle, -1, 8),
      ObstacleSpec(ObstacleType.hurdle, 0, 8),
    ],
    coins: coinRow(1, 4, count: 8),
  ),
  Chunk(
    length: 30,
    difficulty: 1,
    obstacles: const [ObstacleSpec(ObstacleType.train, -1, 4, length: 20)],
    coins: coinRow(0, 6, count: 8),
  ),
  // Breather: pure coin zigzag.
  Chunk(
    length: 26,
    difficulty: 1,
    obstacles: const [],
    coins: [
      ...coinRow(-1, 2, count: 3),
      ...coinRow(0, 9, count: 3),
      ...coinRow(1, 16, count: 3),
    ],
  ),

  // --- Difficulty 2: combinations -----------------------------------------
  Chunk(
    length: 36,
    difficulty: 2,
    obstacles: const [
      ObstacleSpec(ObstacleType.train, -1, 4, length: 24),
      ObstacleSpec(ObstacleType.train, 1, 4, length: 24),
    ],
    coins: coinRow(0, 6, count: 10),
  ),
  Chunk(
    length: 34,
    difficulty: 2,
    obstacles: const [
      ObstacleSpec(ObstacleType.train, 0, 4, length: 20),
      ObstacleSpec(ObstacleType.hurdle, -1, 12),
    ],
    coins: [...coinRow(1, 6, count: 8), ...coinArc(-1, 12)],
  ),
  Chunk(
    length: 30,
    difficulty: 2,
    obstacles: const [
      ObstacleSpec(ObstacleType.gate, -1, 10),
      ObstacleSpec(ObstacleType.gate, 1, 10),
      ObstacleSpec(ObstacleType.hurdle, 0, 10),
    ],
    coins: coinArc(0, 10),
  ),
  Chunk(
    length: 34,
    difficulty: 2,
    obstacles: const [
      ObstacleSpec(ObstacleType.hurdle, 0, 8),
      ObstacleSpec(ObstacleType.hurdle, 0, 16),
      ObstacleSpec(ObstacleType.train, 1, 6, length: 22),
    ],
    coins: [...coinArc(0, 8), ...coinArc(0, 16)],
  ),
  // All-lane hurdle wall — jump anywhere.
  Chunk(
    length: 26,
    difficulty: 2,
    obstacles: const [
      ObstacleSpec(ObstacleType.hurdle, -1, 12),
      ObstacleSpec(ObstacleType.hurdle, 0, 12),
      ObstacleSpec(ObstacleType.hurdle, 1, 12),
    ],
    coins: [...coinArc(-1, 12), ...coinArc(0, 12), ...coinArc(1, 12)],
  ),

  // --- Difficulty 3: high speed pressure ----------------------------------
  Chunk(
    length: 40,
    difficulty: 3,
    obstacles: const [
      ObstacleSpec(ObstacleType.movingTrain, 0, 18, length: 20, speed: 8),
    ],
    coins: [...coinRow(-1, 4, count: 6), ...coinRow(1, 4, count: 6)],
  ),
  Chunk(
    length: 42,
    difficulty: 3,
    obstacles: const [
      ObstacleSpec(ObstacleType.train, -1, 4, length: 30),
      ObstacleSpec(ObstacleType.train, 1, 4, length: 30),
      ObstacleSpec(ObstacleType.hurdle, 0, 10),
      ObstacleSpec(ObstacleType.hurdle, 0, 22),
    ],
    coins: [...coinArc(0, 10), ...coinArc(0, 22)],
  ),
  Chunk(
    length: 42,
    difficulty: 3,
    obstacles: const [
      ObstacleSpec(ObstacleType.movingTrain, -1, 16, length: 18, speed: 7),
      ObstacleSpec(ObstacleType.gate, 0, 12),
      ObstacleSpec(ObstacleType.train, 1, 4, length: 26),
    ],
    coins: coinRow(0, 16, count: 8, h: 0.45),
  ),
  Chunk(
    length: 38,
    difficulty: 3,
    obstacles: const [
      ObstacleSpec(ObstacleType.train, 0, 4, length: 24),
      ObstacleSpec(ObstacleType.gate, -1, 10),
      ObstacleSpec(ObstacleType.hurdle, 1, 18),
    ],
    coins: [...coinRow(-1, 13, count: 5, h: 0.45), ...coinArc(1, 18)],
  ),
];

/// Streams chunks (plus periodic powerups) into the world as the player
/// advances. Difficulty tiers unlock with distance; the gap between chunks
/// widens with speed so patterns stay reactable.
class Spawner {
  Spawner(this._rng);

  final Random _rng;

  /// Absolute track position (meters from run start) where the next chunk
  /// will begin.
  double _cursor = 25; // opening grace distance

  double _nextPowerupAt = 350;

  void reset() {
    _cursor = 25;
    _nextPowerupAt = 350 + _rng.nextDouble() * 150;
  }

  int tierFor(double distance) {
    if (distance < 400) return 1;
    if (distance < 1200) return 2;
    return 3;
  }

  Chunk _pick(double distance) {
    final tier = tierFor(distance);
    // Higher tiers keep some easy chunks in the mix as breathers.
    final weights = <Chunk, double>{
      for (final c in chunkLibrary)
        if (c.difficulty <= tier)
          c: c.difficulty == tier ? 3.0 : (tier - c.difficulty == 1 ? 1.5 : 0.6)
    };
    var roll = _rng.nextDouble() * weights.values.reduce((a, b) => a + b);
    for (final e in weights.entries) {
      roll -= e.value;
      if (roll <= 0) return e.key;
    }
    return weights.keys.last;
  }

  /// Ensures the world is populated up to `distance + ahead` meters.
  /// Emitted entities get depths relative to the player (`abs - distance`).
  void fillTo({
    required double distance,
    required double ahead,
    required double speed,
    required void Function(Obstacle) obstacle,
    required void Function(Coin) coin,
    required void Function(Powerup) powerup,
  }) {
    while (_cursor < distance + ahead) {
      final chunk = _pick(distance);
      final base = _cursor;

      for (final o in chunk.obstacles) {
        obstacle(Obstacle(
          type: o.type,
          lane: o.lane,
          d: base + o.at - distance,
          length: o.length,
          speed: o.speed,
          colorSeed: _rng.nextInt(1 << 16),
        ));
      }
      for (final c in chunk.coins) {
        coin(Coin(lane: c.lane.toDouble(), d: base + c.at - distance, h: c.h));
      }

      final gap = 8 + speed * 0.45;
      final end = base + chunk.length;

      if (end > _nextPowerupAt) {
        // Drop a powerup in the gap after this chunk, center of a free spot.
        final type =
            PowerupType.values[_rng.nextInt(PowerupType.values.length)];
        powerup(Powerup(
          type: type,
          lane: _rng.nextInt(3) - 1,
          d: end + gap * 0.5 - distance,
        ));
        _nextPowerupAt = end + 380 + _rng.nextDouble() * 220;
      }

      _cursor = end + gap;
    }
  }
}
