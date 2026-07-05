import 'package:flutter/material.dart';

import '../game/audio_manager.dart';
import '../game/painters/player_painter.dart';
import '../game/runner_game.dart';
import '../game/storage.dart';
import '../game/themes.dart';
import 'widgets.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.game});

  final RunnerGame game;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = Storage.instance;
    final owned = storage.ownedSkins;
    final equipped = storage.equippedSkin;

    return Container(
      color: const Color(0xD007102A),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: PanelCard(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SHOP', style: titleStyle(40)),
                        ValueListenableBuilder(
                          valueListenable: widget.game.bankN,
                          builder: (_, bank, __) => StatChip(
                              icon: Icons.monetization_on, value: '$bank'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final skin in CharacterSkin.all)
                          _SkinCard(
                            skin: skin,
                            owned: owned.contains(skin.id),
                            equipped: equipped == skin.id,
                            onTap: () => _handleTap(skin),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ChunkyButton(
                      label: 'BACK',
                      color: const Color(0xFFB0BEC5),
                      fontSize: 20,
                      onTap: () =>
                          widget.game.overlays.remove(Overlays.shop),
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

  void _handleTap(CharacterSkin skin) {
    final storage = Storage.instance;
    final owned = storage.ownedSkins;

    if (owned.contains(skin.id)) {
      widget.game.equipSkin(skin.id);
      AudioManager.instance.click();
      setState(() {});
      return;
    }
    if (storage.coinBank < skin.price) {
      AudioManager.instance.stumble();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough coins — need ${skin.price - storage.coinBank} more!'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    storage.coinBank -= skin.price;
    storage.ownedSkins = [...owned, skin.id];
    widget.game.bankN.value = storage.coinBank;
    widget.game.equipSkin(skin.id);
    AudioManager.instance.powerup();
    setState(() {});
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });

  final CharacterSkin skin;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2340),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: equipped ? kAccent : kPanelBorder,
            width: equipped ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 100,
              child: CustomPaint(painter: _PreviewPainter(skin)),
            ),
            const SizedBox(height: 6),
            Text(skin.name,
                style: const TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 20,
                    color: Colors.white,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            if (equipped)
              const Text('EQUIPPED',
                  style: TextStyle(
                      color: kAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1))
            else if (owned)
              const Text('TAP TO EQUIP',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on,
                      color: kAccent, size: 14),
                  const SizedBox(width: 4),
                  Text('${skin.price}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.skin);

  final CharacterSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    paintCharacterPreview(canvas, Offset.zero & size, skin);
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.skin != skin;
}
