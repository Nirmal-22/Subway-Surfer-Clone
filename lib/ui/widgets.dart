import 'package:flutter/material.dart';

import '../game/audio_manager.dart';

const kAccent = Color(0xFFFFC400);
const kPanel = Color(0xE6141B33);
const kPanelBorder = Color(0x33FFFFFF);

TextStyle titleStyle(double size, {Color color = kAccent}) => TextStyle(
      fontFamily: 'Bangers',
      fontSize: size,
      color: color,
      letterSpacing: 2,
      shadows: const [
        Shadow(color: Color(0xAA000000), offset: Offset(0, 3), blurRadius: 6),
      ],
    );

/// Big cartoonish press-down button.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = kAccent,
    this.textColor = const Color(0xFF3E2723),
    this.icon,
    this.width,
    this.fontSize = 26,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final double? width;
  final double fontSize;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final dark = HSLColor.fromColor(widget.color)
        .withLightness(
            (HSLColor.fromColor(widget.color).lightness - 0.18).clamp(0, 1))
        .toColor();
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        AudioManager.instance.click();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.color, Color.lerp(widget.color, dark, 0.35)!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: dark,
              offset: Offset(0, _down ? 1 : 5),
            ),
            const BoxShadow(
              color: Color(0x55000000),
              offset: Offset(0, 8),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: widget.fontSize),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: widget.fontSize,
                letterSpacing: 1.5,
                color: widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kPanelBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

/// Small icon + value chip (coins, best score...).
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    this.iconColor = kAccent,
  });

  final IconData icon;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xAA10162B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kPanelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 18,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Integer that counts up when it first appears (game-over score reveal).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}', style: style),
    );
  }
}
