import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/runner_game.dart';
import 'game/storage.dart';
import 'ui/game_over.dart';
import 'ui/howto_screen.dart';
import 'ui/hud.dart';
import 'ui/main_menu.dart';
import 'ui/pause_menu.dart';
import 'ui/settings_screen.dart';
import 'ui/shop_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const MetroDashApp());
}

class MetroDashApp extends StatelessWidget {
  const MetroDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metro Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF07102A),
      ),
      home: const GameHost(),
    );
  }
}

class GameHost extends StatefulWidget {
  const GameHost({super.key});

  @override
  State<GameHost> createState() => _GameHostState();
}

class _GameHostState extends State<GameHost> with WidgetsBindingObserver {
  late final RunnerGame _game;
  final _focusNode = FocusNode();

  // Swipe detection: accumulate drag distance and fire a single action per
  // gesture once the threshold is crossed. One flick = one move; the next
  // move needs a new swipe.
  Offset _dragAccum = Offset.zero;
  bool _swipeFired = false;
  static const _swipeThreshold = 26.0;

  @override
  void initState() {
    super.initState();
    _game = RunnerGame();
    WidgetsBinding.instance.addObserver(this);
    // Show the main menu once the first frame exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.overlays.add(Overlays.menu);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _game.autoPause();
  }

  void _onPanStart(DragStartDetails _) {
    _dragAccum = Offset.zero;
    _swipeFired = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_swipeFired) return;
    _dragAccum += details.delta;
    final dx = _dragAccum.dx;
    final dy = _dragAccum.dy;
    if (dx.abs() < _swipeThreshold && dy.abs() < _swipeThreshold) return;
    if (dx.abs() > dy.abs()) {
      dx > 0 ? _game.inputRight() : _game.inputLeft();
    } else {
      dy > 0 ? _game.inputRoll() : _game.inputJump();
    }
    _swipeFired = true;
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      _game.inputLeft();
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _game.inputRight();
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.space) {
      _game.inputJump();
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      _game.inputRoll();
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.keyP) {
      _game.togglePause();
    } else if (key == LogicalKeyboardKey.enter) {
      switch (_game.phase) {
        case GamePhase.menu:
        case GamePhase.gameOver:
          _game.startGame();
        case GamePhase.paused:
          _game.resumeGame();
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          child: GameWidget(
            game: _game,
            overlayBuilderMap: {
              Overlays.menu: (_, RunnerGame g) => MainMenu(game: g),
              Overlays.hud: (_, RunnerGame g) => Hud(game: g),
              Overlays.pause: (_, RunnerGame g) => PauseMenu(game: g),
              Overlays.gameOver: (_, RunnerGame g) => GameOverScreen(game: g),
              Overlays.shop: (_, RunnerGame g) => ShopScreen(game: g),
              Overlays.settings: (_, RunnerGame g) => SettingsScreen(game: g),
              Overlays.howTo: (_, RunnerGame g) => HowToScreen(game: g),
            },
          ),
        ),
      ),
    );
  }
}
