import 'package:flutter/material.dart';

import '../game/runner_game.dart';
import 'widgets.dart';

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key, required this.game});

  final RunnerGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xD007102A),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: PanelCard(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('HOW TO PLAY', style: titleStyle(36))),
                    const SizedBox(height: 14),
                    const _Row(Icons.swap_horiz, Color(0xFF4FC3F7),
                        'Swipe ◀ ▶  (or arrow keys / A D)', 'switch lanes'),
                    const _Row(Icons.arrow_upward, Color(0xFF81C784),
                        'Swipe ▲  (or ↑ / W / Space)', 'jump over hurdles'),
                    const _Row(Icons.arrow_downward, Color(0xFFFFB74D),
                        'Swipe ▼  (or ↓ / S)', 'roll under signs'),
                    const _Row(Icons.train, Color(0xFFE57373),
                        'Trains block the lane', 'dodge — never headbutt'),
                    const Divider(color: Colors.white24, height: 28),
                    const _Row(Icons.attractions, Color(0xFFE53935),
                        'Magnet', 'pulls coins to you'),
                    const _Row(Icons.close, Color(0xFF8E24AA), '2× Multiplier',
                        'doubles your score'),
                    const _Row(Icons.shield, Color(0xFF039BE5), 'Shield',
                        'survive one hit'),
                    const Divider(color: Colors.white24, height: 28),
                    const _Row(Icons.directions_run, Color(0xFFFFD54F),
                        'Side-swipe a train', 'you stumble — twice and the inspector catches you!'),
                    const SizedBox(height: 18),
                    Center(
                      child: ChunkyButton(
                        label: 'GOT IT',
                        fontSize: 20,
                        onTap: () => game.overlays.remove(Overlays.howTo),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.color, this.title, this.subtitle);

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
