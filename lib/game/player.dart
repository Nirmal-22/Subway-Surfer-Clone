import 'dart:math';

enum PlayerAction { running, jumping, rolling, dead }

/// Player movement state machine: lane tweening, jump arc, roll, and the
/// timing data the collision code needs. No rendering here.
class Player {
  static const double jumpDuration = 0.58;
  static const double rollDuration = 0.50;
  static const double laneChangeDuration = 0.16;

  /// Peak of the jump arc in meters. Hurdles are ~1 m tall.
  static const double jumpHeight = 2.1;

  /// Standing/rolling body heights in meters (gate clearance checks).
  static const double standingHeight = 1.7;
  static const double rollingHeight = 0.8;

  int lane = 0; // target lane: -1, 0, 1
  double lanePos = 0; // continuous, rendered position
  double _laneFrom = 0;
  double _laneT = 1; // 1 = tween finished

  PlayerAction action = PlayerAction.running;
  double actionT = 0; // 0..1 progress through jump/roll

  /// Advances the run cycle animation; scaled by world speed.
  double runPhase = 0;

  void reset() {
    lane = 0;
    lanePos = 0;
    _laneFrom = 0;
    _laneT = 1;
    action = PlayerAction.running;
    actionT = 0;
    runPhase = 0;
  }

  bool get isChangingLanes => _laneT < 1;
  bool get isRolling => action == PlayerAction.rolling;
  bool get isJumping => action == PlayerAction.jumping;

  /// Feet height above the ground in meters.
  double get airHeight =>
      isJumping ? jumpHeight * sin(pi * actionT.clamp(0.0, 1.0)) : 0;

  double get bodyHeight => isRolling ? rollingHeight : standingHeight;

  /// Returns true if the move was accepted (used to gate sfx).
  bool changeLane(int dir) {
    if (action == PlayerAction.dead) return false;
    final next = (lane + dir).clamp(-1, 1);
    if (next == lane) return false;
    _laneFrom = lanePos;
    lane = next;
    _laneT = 0;
    return true;
  }

  bool jump() {
    if (action == PlayerAction.dead || isJumping) return false;
    action = PlayerAction.jumping;
    actionT = 0;
    return true;
  }

  bool roll() {
    if (action == PlayerAction.dead || isRolling) return false;
    // Rolling mid-air slams the player down, like the original.
    action = PlayerAction.rolling;
    actionT = 0;
    return true;
  }

  /// Bounce back to the lane we came from after a side-swipe stumble.
  void snapBack() {
    final from = _laneFrom.round().clamp(-1, 1);
    lane = from;
    _laneFrom = lanePos;
    _laneT = 0;
  }

  /// Shove the player toward [target] (shield pop escape).
  void forceLane(int target) {
    lane = target.clamp(-1, 1);
    _laneFrom = lanePos;
    _laneT = 0;
  }

  void update(double dt, double speedFactor) {
    if (action == PlayerAction.dead) return;

    runPhase += dt * 9 * speedFactor;

    if (_laneT < 1) {
      _laneT = min(1, _laneT + dt / laneChangeDuration);
      final eased = 1 - pow(1 - _laneT, 3).toDouble(); // ease-out cubic
      lanePos = _laneFrom + (lane - _laneFrom) * eased;
    }

    if (isJumping) {
      actionT += dt / jumpDuration;
      if (actionT >= 1) {
        action = PlayerAction.running;
        actionT = 0;
      }
    } else if (isRolling) {
      actionT += dt / rollDuration;
      if (actionT >= 1) {
        action = PlayerAction.running;
        actionT = 0;
      }
    }
  }
}
