import 'package:flutter/material.dart';

import '../game/audio_manager.dart';
import '../game/runner_game.dart';
import '../game/storage.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.game});

  final RunnerGame game;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = Storage.instance;
    return Container(
      color: const Color(0xD007102A),
      child: Center(
        child: PanelCard(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SETTINGS', style: titleStyle(40)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Music',
                      style: TextStyle(color: Colors.white)),
                  secondary:
                      const Icon(Icons.music_note, color: Colors.white70),
                  activeTrackColor: kAccent,
                  value: storage.musicOn,
                  onChanged: (v) async {
                    AudioManager.instance.click();
                    await AudioManager.instance.setMusicOn(v);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Sound effects',
                      style: TextStyle(color: Colors.white)),
                  secondary:
                      const Icon(Icons.volume_up, color: Colors.white70),
                  activeTrackColor: kAccent,
                  value: storage.soundOn,
                  onChanged: (v) {
                    storage.soundOn = v;
                    AudioManager.instance.click();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _confirmReset,
                  icon: const Icon(Icons.delete_forever,
                      color: Color(0xFFE57373)),
                  label: const Text('Reset progress',
                      style: TextStyle(color: Color(0xFFE57373))),
                ),
                const SizedBox(height: 12),
                ChunkyButton(
                  label: 'BACK',
                  color: const Color(0xFFB0BEC5),
                  fontSize: 20,
                  onTap: () =>
                      widget.game.overlays.remove(Overlays.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
            'High score, coins and unlocked characters will be wiped.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset',
                  style: TextStyle(color: Color(0xFFE57373)))),
        ],
      ),
    );
    if (yes != true) return;
    await Storage.instance.resetProgress();
    widget.game.bestN.value = 0;
    widget.game.bankN.value = 0;
    widget.game.equipSkin('dash');
    setState(() {});
  }
}
