/// World entities: obstacles, coins and powerups. Plain data objects moved
/// and collision-checked by [RunnerGame]; rendering lives in the painters.
library;

enum ObstacleType {
  /// Low hurdle — cleared by jumping.
  hurdle,

  /// Overhead signal gantry — cleared by rolling under it.
  gate,

  /// Parked train — blocks the lane entirely, switch lanes.
  train,

  /// Oncoming train — like [train] but approaches with extra speed.
  movingTrain,
}

extension ObstacleTypeX on ObstacleType {
  bool get isTrain =>
      this == ObstacleType.train || this == ObstacleType.movingTrain;
}

class Obstacle {
  Obstacle({
    required this.type,
    required this.lane,
    required this.d,
    this.length = 1.0,
    this.speed = 0,
    this.colorSeed = 0,
  });

  final ObstacleType type;

  /// Lane index: -1, 0 or 1.
  final int lane;

  /// Distance (meters) of the near face from the player plane.
  double d;

  /// Depth extent in meters (trains are long, hurdles thin).
  final double length;

  /// Extra approach speed in m/s (moving trains).
  final double speed;

  /// Deterministic seed used by the painter to vary train colors.
  final int colorSeed;

  /// Set once the player has stumbled on / shield-popped this obstacle so it
  /// can't hit twice.
  bool resolved = false;

  /// Set once the obstacle has fully passed the player plane, so the
  /// near-miss check runs exactly once per obstacle.
  bool passed = false;
}

class Coin {
  Coin({required this.lane, required this.d, this.h = 0.55});

  /// Continuous so the magnet can pull coins across lanes.
  double lane;
  double d;
  double h;
  bool collected = false;
}

enum PowerupType { magnet, multiplier, shield, boost }

class Powerup {
  Powerup({required this.type, required this.lane, required this.d});

  final PowerupType type;
  final int lane;
  double d;
  bool collected = false;
}
