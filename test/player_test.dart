import 'package:flutter_test/flutter_test.dart';
import 'package:metro_dash/game/player.dart';

void main() {
  Player freshPlayer() => Player()..reset();

  void tick(Player p, double seconds, [double speedFactor = 1]) {
    const dt = 1 / 120;
    for (var t = 0.0; t < seconds; t += dt) {
      p.update(dt, speedFactor);
    }
  }

  test('lane changes clamp to the three lanes', () {
    final p = freshPlayer();
    expect(p.changeLane(-1), isTrue);
    tick(p, 0.3);
    expect(p.lane, -1);
    expect(p.lanePos, closeTo(-1, 0.001));
    expect(p.changeLane(-1), isFalse); // already leftmost
    expect(p.lane, -1);
  });

  test('lane tween completes and reports transition state', () {
    final p = freshPlayer();
    p.changeLane(1);
    expect(p.isChangingLanes, isTrue);
    tick(p, Player.laneChangeDuration * 2);
    expect(p.isChangingLanes, isFalse);
    expect(p.lanePos, closeTo(1, 0.001));
  });

  test('jump rises, clears hurdle height mid-air, then lands', () {
    final p = freshPlayer();
    expect(p.jump(), isTrue);
    expect(p.jump(), isFalse); // no double jump
    tick(p, Player.jumpDuration / 2);
    expect(p.airHeight, greaterThan(1.0)); // clears a 1 m hurdle
    tick(p, Player.jumpDuration);
    expect(p.action, PlayerAction.running);
    expect(p.airHeight, 0);
  });

  test('rolling mid-air cancels the jump (fast slam)', () {
    final p = freshPlayer();
    p.jump();
    tick(p, 0.1);
    expect(p.roll(), isTrue);
    expect(p.isRolling, isTrue);
    expect(p.airHeight, 0);
    expect(p.bodyHeight, Player.rollingHeight);
    tick(p, Player.rollDuration * 1.5);
    expect(p.action, PlayerAction.running);
  });

  test('snapBack returns the player toward the previous lane', () {
    final p = freshPlayer();
    p.changeLane(1);
    tick(p, 0.06); // mid-transition
    p.snapBack();
    tick(p, 0.5);
    expect(p.lane, 0);
    expect(p.lanePos, closeTo(0, 0.001));
  });

  test('super sneakers raise the jump arc and reset clears the boost', () {
    final p = freshPlayer();
    p.jumpBoost = 1.55;
    p.jump();
    tick(p, Player.jumpDuration / 2);
    // Mid-jump apex must beat an unboosted jump's ceiling.
    expect(p.airHeight, greaterThan(Player.jumpHeight));
    expect(p.airHeight, greaterThan(2.9)); // clears a signal gate
    p.reset();
    expect(p.jumpBoost, 1.0);
  });

  test('dead players ignore input', () {
    final p = freshPlayer();
    p.action = PlayerAction.dead;
    expect(p.changeLane(1), isFalse);
    expect(p.jump(), isFalse);
    expect(p.roll(), isFalse);
  });
}
