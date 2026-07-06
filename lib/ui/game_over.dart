import 'dart:math';

import 'package:flutter/material.dart';

import '../game/runner_game.dart';
import 'widgets.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key, required this.game});

  final RunnerGame game;

  @override
  Widget build(BuildContext context) {
    final run = game.lastRun;
    return Container(
      color: const Color(0x9907102A),
      child: Center(
        child: SingleChildScrollView(
          child: PanelCard(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (run.newBest)
                  _Pulse(
                    child: Text('NEW RECORD!',
                        style: titleStyle(44, color: const Color(0xFFFFD54F))),
                  )
                else
                  Text('GAME OVER',
                      style: titleStyle(44, color: const Color(0xFFE57373))),
                const SizedBox(height: 8),
                AnimatedCount(
                  value: run.score,
                  style: titleStyle(64, color: Colors.white),
                ),
                const Text(
                  'SCORE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Stat(
                        icon: Icons.monetization_on,
                        color: const Color(0xFFFFD54F),
                        value: '+${run.coins}',
                        label: 'COINS'),
                    const SizedBox(width: 18),
                    _Stat(
                        icon: Icons.straighten,
                        color: const Color(0xFF4FC3F7),
                        value: '${run.distance} m',
                        label: 'DISTANCE'),
                    const SizedBox(width: 18),
                    ValueListenableBuilder(
                      valueListenable: game.bestN,
                      builder: (_, best, __) => _Stat(
                          icon: Icons.emoji_events,
                          color: const Color(0xFF81C784),
                          value: '$best',
                          label: 'BEST'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ChunkyButton(
                  label: 'RUN AGAIN',
                  icon: Icons.replay_rounded,
                  width: 240,
                  fontSize: 28,
                  onTap: game.startGame,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChunkyButton(
                      label: 'MENU',
                      fontSize: 18,
                      color: const Color(0xFFB0BEC5),
                      onTap: game.goMenu,
                    ),
                    const SizedBox(width: 10),
                    ChunkyButton(
                      label: 'SHOP',
                      fontSize: 18,
                      color: const Color(0xFF4FC3F7),
                      // Stacks on top so the shop's BACK button lands here
                      // again (mirrors how the main menu opens it).
                      onTap: () => game.overlays.add(Overlays.shop),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Bangers', fontSize: 22, color: Colors.white)),
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Gentle infinite scale pulse for the NEW RECORD! banner.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: 1 + 0.05 * sin(_c.value * 2 * pi),
        child: child,
      ),
      child: widget.child,
    );
  }
}
