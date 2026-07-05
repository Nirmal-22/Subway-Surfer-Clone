import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'audio_manager.dart';
import 'entities.dart';
import 'painters/background_painter.dart';
import 'painters/entity_painter.dart';
import 'painters/player_painter.dart';
import 'painters/track_painter.dart';
import 'particles.dart';
import 'player.dart';
import 'projection.dart';
import 'spawner.dart';
import 'storage.dart';
import 'themes.dart';

enum GamePhase { menu, running, countdown, paused, crashing, gameOver }

class RunStats {
  const RunStats({
    required this.score,
    required this.coins,
    required this.distance,
    required this.newBest,
  });

  final int score;
  final int coins;
  final int distance;
  final bool newBest;
}

/// Overlay ids used with Flame's overlay system (built in main.dart).
abstract final class Overlays {
  static const menu = 'menu';
  static const hud = 'hud';
  static const pause = 'pause';
  static const gameOver = 'gameOver';
  static const shop = 'shop';
  static const settings = 'settings';
  static const howTo = 'howTo';
}

class RunnerGame extends FlameGame {
  GamePhase phase = GamePhase.menu;

  // --- HUD state -----------------------------------------------------------
  final scoreN = ValueNotifier<int>(0);
  final coinsN = ValueNotifier<int>(0);
  final bankN = ValueNotifier<int>(0);
  final bestN = ValueNotifier<int>(0);
  final magnetN = ValueNotifier<double>(0);
  final multiplierN = ValueNotifier<double>(0);
  final shieldN = ValueNotifier<double>(0);
  final countdownN = ValueNotifier<int?>(null);
  final hintN = ValueNotifier<String?>(null);

  RunStats lastRun =
      const RunStats(score: 0, coins: 0, distance: 0, newBest: false);

  // --- World state ---------------------------------------------------------
  final player = Player();
  late final Spawner _spawner = Spawner(Random());
  final particles = ParticleSystem();

  final List<Obstacle> obstacles = [];
  final List<Coin> coins = [];
  final List<Powerup> powerups = [];

  double _time = 0;
  double _distance = 0;
  double _speed = 12;
  double _scoreF = 0;
  int _coinsRun = 0;
  double _runTime = 0;

  double _magnetT = 0;
  double _multiplierT = 0;
  double _shieldT = 0;
  double _invulnT = 0;

  double _guardChase = 0;
  double _guardLane = 0;
  double _crashT = 0;
  double _countdownT = 0;

  double _shake = 0;
  double _flashT = 0;
  Color _flashColor = const Color(0x00000000);

  double _hintT = 0;
  int _nextTutorialHint = 0;
  int _nextMilestone = 500;

  CharacterSkin skin = CharacterSkin.all.first;

  int get multiplier => _multiplierT > 0 ? 2 : 1;

  static const _tutorialHints = [
    (1.5, 'Swipe ◀ ▶ to switch lanes'),
    (5.0, 'Swipe ▲ to jump'),
    (8.5, 'Swipe ▼ to roll'),
  ];

  @override
  Color backgroundColor() => const Color(0xFF0A1030);

  @override
  Future<void> onLoad() async {
    skin = CharacterSkin.byId(Storage.instance.equippedSkin);
    bestN.value = Storage.instance.bestScore;
    bankN.value = Storage.instance.coinBank;
    await AudioManager.instance.init();
    _resetWorld();
  }

  // --- Flow control --------------------------------------------------------

  void _resetWorld() {
    obstacles.clear();
    coins.clear();
    powerups.clear();
    particles.clear();
    player.reset();
    _spawner.reset();
    _distance = 0;
    _speed = 12;
    _scoreF = 0;
    _coinsRun = 0;
    _runTime = 0;
    _magnetT = 0;
    _multiplierT = 0;
    _shieldT = 0;
    _invulnT = 0;
    _guardChase = 0;
    _guardLane = 0;
    _crashT = 0;
    _shake = 0;
    _flashT = 0;
    _nextTutorialHint = 0;
    _nextMilestone = 500;
    scoreN.value = 0;
    coinsN.value = 0;
    magnetN.value = 0;
    multiplierN.value = 0;
    shieldN.value = 0;
    hintN.value = null;
    countdownN.value = null;
  }

  void startGame() {
    _resetWorld();
    phase = GamePhase.running;
    overlays.removeAll(
        [Overlays.menu, Overlays.gameOver, Overlays.shop, Overlays.settings, Overlays.howTo]);
    overlays.add(Overlays.hud);
    AudioManager.instance.click();
    AudioManager.instance.startMusic();
  }

  void goMenu() {
    _resetWorld();
    phase = GamePhase.menu;
    overlays.removeAll([
      Overlays.hud,
      Overlays.pause,
      Overlays.gameOver,
      Overlays.shop,
      Overlays.settings,
      Overlays.howTo,
    ]);
    overlays.add(Overlays.menu);
    AudioManager.instance.click();
  }

  void pauseGame() {
    if (phase != GamePhase.running) return;
    phase = GamePhase.paused;
    overlays.add(Overlays.pause);
    AudioManager.instance.click();
  }

  void resumeGame() {
    if (phase != GamePhase.paused) return;
    overlays.remove(Overlays.pause);
    phase = GamePhase.countdown;
    _countdownT = 3.0;
    countdownN.value = 3;
    AudioManager.instance.click();
  }

  void togglePause() {
    if (phase == GamePhase.running) {
      pauseGame();
    } else if (phase == GamePhase.paused) {
      resumeGame();
    }
  }

  /// Called by the app lifecycle observer when the app loses focus.
  void autoPause() {
    if (phase == GamePhase.running) pauseGame();
  }

  void equipSkin(String id) {
    skin = CharacterSkin.byId(id);
    Storage.instance.equippedSkin = id;
  }

  // --- Input ---------------------------------------------------------------

  void inputLeft() => _inputLane(-1);
  void inputRight() => _inputLane(1);

  void _inputLane(int dir) {
    if (phase != GamePhase.running) return;
    if (player.changeLane(dir)) AudioManager.instance.swipe();
  }

  void inputJump() {
    if (phase != GamePhase.running) return;
    if (player.jump()) AudioManager.instance.jump();
  }

  void inputRoll() {
    if (phase != GamePhase.running) return;
    if (player.roll()) AudioManager.instance.roll();
  }

  // --- Update --------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    // Clamp so a hitched frame (tab switch etc.) can't tunnel the player
    // through obstacles.
    final clamped = min(dt, 1 / 20);
    _time += clamped;
    particles.update(clamped);
    _shake = max(0, _shake - clamped * 22);
    _flashT = max(0, _flashT - clamped * 2.6);

    switch (phase) {
      case GamePhase.menu:
        _distance += 9 * clamped;
        player.update(clamped, 0.8);
      case GamePhase.countdown:
        final before = _countdownT.ceil();
        _countdownT -= clamped;
        if (_countdownT <= 0) {
          countdownN.value = null;
          phase = GamePhase.running;
        } else if (_countdownT.ceil() != before) {
          countdownN.value = _countdownT.ceil();
        }
      case GamePhase.running:
        _updateRun(clamped);
      case GamePhase.crashing:
        _crashT += clamped / 1.15;
        _guardChase = min(1, _guardChase + clamped * 3);
        _guardLane += (player.lanePos - _guardLane) * min(1, clamped * 10);
        if (_crashT >= 1) _finalizeRun();
      case GamePhase.paused:
      case GamePhase.gameOver:
        break;
    }
  }

  void _updateRun(double dt) {
    _runTime += dt;
    _speed = 12 + 20 * (1 - exp(-_distance / 1500));
    _distance += _speed * dt;
    _scoreF += _speed * dt * 2 * multiplier;
    scoreN.value = _scoreF.round();

    player.update(dt, _speed / 12);
    _invulnT = max(0, _invulnT - dt);

    // Powerup timers.
    if (_magnetT > 0) magnetN.value = _magnetT = max(0, _magnetT - dt);
    if (_multiplierT > 0) {
      multiplierN.value = _multiplierT = max(0, _multiplierT - dt);
    }
    if (_shieldT > 0) shieldN.value = _shieldT = max(0, _shieldT - dt);

    // Guard gives up over time.
    _guardChase = max(0, _guardChase - dt / 6);
    _guardLane += (player.lanePos - _guardLane) * min(1, dt * 6);

    _spawner.fillTo(
      distance: _distance,
      ahead: Projection.maxDepth,
      speed: _speed,
      obstacle: obstacles.add,
      coin: coins.add,
      powerup: powerups.add,
    );

    // Advance the world toward the camera.
    for (final o in obstacles) {
      o.d -= (_speed + o.speed) * dt;
    }
    for (final c in coins) {
      c.d -= _speed * dt;
    }
    for (final pu in powerups) {
      pu.d -= _speed * dt;
    }
    obstacles.removeWhere((o) => o.d + o.length < -5);
    coins.removeWhere((c) => c.collected || c.d < -3);
    powerups.removeWhere((pu) => pu.collected || pu.d < -3);

    _updateCoins(dt);
    _updatePowerups();
    _checkCollisions();
    _updateHints(dt);
  }

  void _updateCoins(double dt) {
    final proj = Projection(size.toSize());
    for (final c in coins) {
      if (_magnetT > 0 && c.d < 14 && c.d > -1) {
        c.lane += (player.lanePos - c.lane) * min(1, dt * 9);
        c.h += ((player.airHeight + 0.6) - c.h) * min(1, dt * 9);
        c.d -= 14 * dt; // reel it in
      }
      if (c.d.abs() < 1.0 &&
          (c.lane - player.lanePos).abs() < 0.5 &&
          (c.h - (player.airHeight + 0.6)).abs() < 1.1) {
        c.collected = true;
        _coinsRun++;
        coinsN.value = _coinsRun;
        AudioManager.instance.coin();
        particles.burst(
          proj.project(c.d, c.lane, h: c.h),
          count: 6,
          color: const Color(0xFFFFD54F),
          speed: 90,
          life: 0.4,
          size: 3,
        );
      }
    }
  }

  void _updatePowerups() {
    final proj = Projection(size.toSize());
    for (final pu in powerups) {
      if (pu.d.abs() < 1.0 && (pu.lane - player.lanePos).abs() < 0.55) {
        pu.collected = true;
        AudioManager.instance.powerup();
        switch (pu.type) {
          case PowerupType.magnet:
            magnetN.value = _magnetT = 8;
          case PowerupType.multiplier:
            multiplierN.value = _multiplierT = 10;
          case PowerupType.shield:
            shieldN.value = _shieldT = 15;
        }
        particles.burst(
          proj.project(pu.d, pu.lane.toDouble(), h: 1.05),
          count: 14,
          color: const Color(0xFFFFFFFF),
          speed: 140,
          life: 0.5,
          size: 4,
        );
      }
    }
  }

  void _checkCollisions() {
    for (final o in obstacles) {
      if (o.resolved) continue;
      if (o.d >= 0.45 || o.d + o.length <= -0.45) continue;
      final laneDiff = (player.lanePos - o.lane).abs();
      if (laneDiff >= 0.55) continue;

      final cleared = switch (o.type) {
        ObstacleType.hurdle => player.airHeight > 0.85,
        ObstacleType.gate => player.isRolling,
        ObstacleType.train || ObstacleType.movingTrain => false,
      };
      if (cleared) continue;
      if (_invulnT > 0) continue;

      if (_shieldT > 0) {
        _popShield(o);
        continue;
      }

      // Side-swipe while changing lanes: stumble instead of dying — unless
      // the guard is already breathing down our neck.
      if (player.isChangingLanes && laneDiff > 0.22) {
        if (_guardChase > 0.5) {
          _crash();
          return;
        }
        o.resolved = true;
        player.snapBack();
        _guardChase = 1.0;
        _shake = 5;
        _flash(const Color(0xFFE53935), 0.25);
        AudioManager.instance.stumble();
        _showHint('Close one!');
        continue;
      }

      _crash();
      return;
    }
  }

  void _popShield(Obstacle o) {
    shieldN.value = _shieldT = 0;
    _invulnT = 1.0;
    o.resolved = true;
    _flash(const Color(0xFF4FC3F7), 0.4);
    _shake = 5;
    AudioManager.instance.stumble();
    if (o.type.isTrain) {
      // Shove the player into the nearest train-free lane.
      final lanes = [-1, 0, 1]
        ..sort((a, b) => (a - player.lanePos)
            .abs()
            .compareTo((b - player.lanePos).abs()));
      for (final lane in lanes) {
        final blocked = obstacles.any((other) =>
            other.type.isTrain &&
            other.lane == lane &&
            other.d < 3 &&
            other.d + other.length > -1);
        if (!blocked) {
          player.forceLane(lane);
          break;
        }
      }
    }
  }

  void _crash() {
    phase = GamePhase.crashing;
    player.action = PlayerAction.dead;
    _crashT = 0;
    _guardChase = 1;
    _shake = 14;
    _flash(const Color(0xFFFFFFFF), 0.5);
    AudioManager.instance.crash();
    final proj = Projection(size.toSize());
    particles.burst(
      Offset(proj.screenX(0, player.lanePos), proj.playerPlaneY - 40),
      count: 18,
      color: const Color(0xFFB0BEC5),
      speed: 190,
      life: 0.7,
      size: 4,
      gravity: 500,
    );
  }

  void _finalizeRun() {
    final storage = Storage.instance;
    final score = _scoreF.round();
    final newBest = score > storage.bestScore;
    if (newBest) storage.bestScore = score;
    if (_distance.round() > storage.bestDistance) {
      storage.bestDistance = _distance.round();
    }
    storage.coinBank += _coinsRun;
    storage.gamesPlayed += 1;
    if (!storage.tutorialSeen && _runTime > 10) storage.tutorialSeen = true;

    lastRun = RunStats(
      score: score,
      coins: _coinsRun,
      distance: _distance.round(),
      newBest: newBest,
    );
    bestN.value = storage.bestScore;
    bankN.value = storage.coinBank;

    phase = GamePhase.gameOver;
    overlays.remove(Overlays.hud);
    overlays.add(Overlays.gameOver);
    if (newBest) {
      AudioManager.instance.highscore();
      // Confetti from the top of the screen.
      final rng = Random();
      const colors = [
        Color(0xFFFFD54F),
        Color(0xFF4FC3F7),
        Color(0xFFE57373),
        Color(0xFF81C784),
      ];
      for (var i = 0; i < 60; i++) {
        particles.burst(
          Offset(rng.nextDouble() * size.x, -10),
          count: 1,
          color: colors[i % colors.length],
          speed: 60,
          life: 2.2,
          size: 4,
          gravity: 160,
          baseAngle: pi / 2,
          spread: 1.2,
        );
      }
    } else {
      AudioManager.instance.gameover();
    }
  }

  void _flash(Color color, double strength) {
    _flashColor = color;
    _flashT = strength;
  }

  void _showHint(String text) {
    hintN.value = text;
    _hintT = 1.8;
  }

  void _updateHints(double dt) {
    if (_hintT > 0) {
      _hintT -= dt;
      if (_hintT <= 0) hintN.value = null;
    }
    if (!Storage.instance.tutorialSeen &&
        _nextTutorialHint < _tutorialHints.length &&
        _runTime >= _tutorialHints[_nextTutorialHint].$1) {
      _showHint(_tutorialHints[_nextTutorialHint].$2);
      _nextTutorialHint++;
    }
    if (_distance >= _nextMilestone) {
      _showHint('$_nextMilestone m!');
      _nextMilestone += 500;
    }
  }

  // --- Render --------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final proj = Projection(size.toSize());
    final theme = WorldTheme.forDistance(_distance);

    canvas.save();
    if (_shake > 0) {
      canvas.translate(
        sin(_time * 47) * _shake,
        cos(_time * 39) * _shake * 0.7,
      );
    }

    paintBackground(canvas, proj, theme, _distance, _time);
    paintTrack(canvas, proj, theme, _distance);

    // Far-to-near entity pass so nearer things draw on top.
    final drawables = <(double, void Function())>[
      for (final o in obstacles)
        (o.d, () => paintObstacle(canvas, proj, theme, o, _time)),
      for (final c in coins)
        if (!c.collected) (c.d, () => paintCoin(canvas, proj, c, _time)),
      for (final pu in powerups)
        if (!pu.collected)
          (pu.d, () => paintPowerup(canvas, proj, pu, _time)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    for (final d in drawables) {
      d.$2();
    }

    if (phase != GamePhase.menu) {
      paintPlayer(canvas, proj, skin, player, _time,
          shieldT: _shieldT, crashT: phase == GamePhase.crashing ? _crashT : 0);
      paintGuard(canvas, proj, _guardLane,
          phase == GamePhase.crashing ? 1 : _guardChase, _time);
    }

    particles.render(canvas);
    _renderSpeedLines(canvas, proj);
    canvas.restore();

    if (_flashT > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = _flashColor.withValues(alpha: min(0.5, _flashT)),
      );
    }
  }

  void _renderSpeedLines(Canvas canvas, Projection proj) {
    if (phase != GamePhase.running || _speed < 21) return;
    final strength = ((_speed - 21) / 11).clamp(0.0, 1.0);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.20 * strength);
    for (var i = 0; i < 10; i++) {
      final side = i.isEven ? 0.09 : 0.91;
      final phase01 = ((_time * (2.2 + 0.3 * (i % 4)) + i * 0.37) % 1);
      final y = proj.screenH * (0.15 + 0.75 * phase01);
      final len = proj.screenH * 0.06 * strength * (0.5 + (i % 3) * 0.35);
      paint.strokeWidth = 2.0 + (i % 3);
      canvas.drawLine(
        Offset(proj.screenW * side + (i % 5) * 6 - 12, y),
        Offset(proj.screenW * side + (i % 5) * 6 - 12, y + len),
        paint,
      );
    }
  }
}
