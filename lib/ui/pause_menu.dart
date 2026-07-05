import 'package:flutter/material.dart';

import '../game/runner_game.dart';
import 'widgets.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key, required this.game});

  final RunnerGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xB007102A),
      child: Center(
        child: PanelCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED', style: titleStyle(48)),
              const SizedBox(height: 20),
              ChunkyButton(
                label: 'RESUME',
                icon: Icons.play_arrow_rounded,
                width: 220,
                onTap: game.resumeGame,
              ),
              const SizedBox(height: 12),
              ChunkyButton(
                label: 'RESTART',
                icon: Icons.replay_rounded,
                width: 220,
                color: const Color(0xFF4FC3F7),
                onTap: game.startGame,
              ),
              const SizedBox(height: 12),
              ChunkyButton(
                label: 'MENU',
                icon: Icons.home_rounded,
                width: 220,
                color: const Color(0xFFB0BEC5),
                onTap: game.goMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
