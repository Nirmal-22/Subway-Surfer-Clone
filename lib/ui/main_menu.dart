import 'package:flutter/material.dart';

import '../game/runner_game.dart';
import 'widgets.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key, required this.game});

  final RunnerGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x8807102A), Color(0x33071029), Color(0xAA07102A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Animated bouncing title.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, t, child) =>
                  Transform.scale(scale: 0.6 + 0.4 * t, child: child),
              child: Column(
                children: [
                  Text('METRO', style: titleStyle(72)),
                  Text('DASH',
                      style: titleStyle(72, color: const Color(0xFF4FC3F7))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ENDLESS  LANE  RUNNER',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder(
                  valueListenable: game.bestN,
                  builder: (_, best, __) =>
                      StatChip(icon: Icons.emoji_events, value: '$best'),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder(
                  valueListenable: game.bankN,
                  builder: (_, bank, __) =>
                      StatChip(icon: Icons.monetization_on, value: '$bank'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            ChunkyButton(
              label: 'PLAY',
              icon: Icons.play_arrow_rounded,
              fontSize: 34,
              width: 240,
              onTap: game.startGame,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChunkyButton(
                  label: 'SHOP',
                  fontSize: 18,
                  color: const Color(0xFF4FC3F7),
                  onTap: () => game.overlays.add(Overlays.shop),
                ),
                const SizedBox(width: 10),
                ChunkyButton(
                  label: 'HOW TO',
                  fontSize: 18,
                  color: const Color(0xFF81C784),
                  onTap: () => game.overlays.add(Overlays.howTo),
                ),
                const SizedBox(width: 10),
                ChunkyButton(
                  label: 'SOUND',
                  icon: Icons.settings,
                  fontSize: 18,
                  color: const Color(0xFFB0BEC5),
                  onTap: () => game.overlays.add(Overlays.settings),
                ),
              ],
            ),
            const Spacer(flex: 2),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'swipe or use arrow keys  •  esc to pause',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
