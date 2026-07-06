# Metro Dash

A pseudo-3D endless lane runner (yes, *that* kind) built with **Flutter + Flame** —
no sprite sheets, no engine assets. The whole world is drawn with `Canvas`
painters, and every sound is synthesized by a small Python script.

## Play

| Action | Touch | Keyboard |
|---|---|---|
| Switch lane | swipe ◀ ▶ | ← → / A D |
| Jump | swipe ▲ | ↑ / W / Space |
| Roll | swipe ▼ | ↓ / S |
| Pause | HUD button | Esc / P |

- **Hurdles** are jumped, **signal gates** are rolled under, **trains** are dodged.
- Clip a hurdle near the top of a jump and you **trip** instead of dying; side-swipe
  a train mid-lane-change and you **stumble** — but the inspector starts chasing,
  and the second mistake is the last.
- Shaving past an obstacle at the last moment scores a **near-miss bonus**.
- Powerups: **Magnet**, **2× Multiplier**, **Shield**, **Super Sneakers**
  (mega jumps that clear even the gates).
- Chained coin pickups climb a rising pitch ladder; coins fund **skins** in the
  shop and one **revive** per run.
- The world cycles day → dusk → night as you run.

## Run it

```bash
flutter pub get
flutter run            # pick a device: Chrome, Android, Linux
flutter test           # simulation-driven unit tests
```

## Project map

```
lib/
  main.dart              app shell, input (swipe/keys), overlay wiring
  game/
    runner_game.dart     game loop: phases, collisions, scoring, juice
    player.dart          lane tween + jump/roll state machine (pure logic)
    spawner.dart         hand-authored chunk library + difficulty tiers
    projection.dart      the pseudo-3D perspective math
    entities.dart        obstacle/coin/powerup data types
    themes.dart          day/dusk/night palettes + skins
    audio_manager.dart   thin wrapper over flame_audio
    storage.dart         SharedPreferences facade
    particles.dart       screen-space particle pool
    painters/            canvas painters: background, track, entities, player
  ui/                    menu, HUD, pause, game over, shop, settings, how-to
test/                    player physics, spawner survivability, projection
tools/generate_audio.py  synthesizes every WAV in assets/audio/
```

## Regenerating audio

All SFX and the music loop are procedural (pure-stdlib Python):

```bash
python3 tools/generate_audio.py
```

Edit the synth recipes in that script — every sound documents its intent.
