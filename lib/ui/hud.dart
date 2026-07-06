import 'package:flutter/material.dart';

import '../game/runner_game.dart';
import 'widgets.dart';

class Hud extends StatelessWidget {
  const Hud({super.key, required this.game});

  final RunnerGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Score + coins (top-left).
          Positioned(
            left: 14,
            top: 10,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder(
                    valueListenable: game.scoreN,
                    builder: (_, score, __) => Text(
                      '$score',
                      style: titleStyle(40, color: Colors.white),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: game.bestN,
                    builder: (_, best, __) => Text(
                      'BEST $best',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ValueListenableBuilder(
                    valueListenable: game.coinsN,
                    builder: (_, coins, __) => _Bump(
                      trigger: coins,
                      child: StatChip(
                          icon: Icons.monetization_on, value: '$coins'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pause (top-right).
          Positioned(
            right: 10,
            top: 10,
            child: IconButton(
              onPressed: game.pauseGame,
              icon: const Icon(Icons.pause_circle_filled,
                  color: Colors.white70, size: 44),
            ),
          ),
          // Active powerup timers (right edge).
          Positioned(
            right: 14,
            top: 80,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PowerupChip(
                    listenable: game.magnetN,
                    icon: Icons.attractions,
                    color: const Color(0xFFE53935),
                  ),
                  _PowerupChip(
                    listenable: game.multiplierN,
                    icon: Icons.close,
                    label: '2×',
                    color: const Color(0xFF8E24AA),
                  ),
                  _PowerupChip(
                    listenable: game.shieldN,
                    icon: Icons.shield,
                    color: const Color(0xFF039BE5),
                  ),
                  _PowerupChip(
                    listenable: game.boostN,
                    icon: Icons.keyboard_double_arrow_up,
                    color: const Color(0xFF43A047),
                  ),
                ],
              ),
            ),
          ),
          // Hint / milestone banner.
          Align(
            alignment: const Alignment(0, -0.45),
            child: IgnorePointer(
              child: ValueListenableBuilder(
                valueListenable: game.hintN,
                builder: (_, hint, __) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: hint == null
                      ? const SizedBox.shrink()
                      : Container(
                          key: ValueKey(hint),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xCC10162B),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: kPanelBorder),
                          ),
                          child: Text(hint, style: titleStyle(24)),
                        ),
                ),
              ),
            ),
          ),
          // Resume countdown.
          Center(
            child: IgnorePointer(
              child: ValueListenableBuilder(
                valueListenable: game.countdownN,
                builder: (_, count, __) => count == null
                    ? const SizedBox.shrink()
                    : TweenAnimationBuilder<double>(
                        key: ValueKey(count),
                        tween: Tween(begin: 0.3, end: 1),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (_, t, child) =>
                            Transform.scale(scale: t, child: child),
                        child: Text('$count', style: titleStyle(110)),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scale-pop wrapper: bumps its child whenever [trigger] changes.
class _Bump extends StatelessWidget {
  const _Bump({required this.trigger, required this.child});

  final Object trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 1.28, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(
        scale: s,
        alignment: Alignment.centerLeft,
        child: child,
      ),
      child: child,
    );
  }
}

class _PowerupChip extends StatelessWidget {
  const _PowerupChip({
    required this.listenable,
    required this.icon,
    required this.color,
    this.label,
  });

  final ValueNotifier<double> listenable;
  final IconData icon;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: listenable,
      builder: (_, secs, __) {
        if (secs <= 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white38),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Text(label!,
                    style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 18,
                        color: Colors.white))
              else
                Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '${secs.ceil()}',
                style: const TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
