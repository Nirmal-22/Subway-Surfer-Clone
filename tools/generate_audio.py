#!/usr/bin/env python3
"""Synthesizes all game audio (SFX + music loop) into assets/audio/ as WAVs.

Pure-stdlib chiptune-style synthesis: square/triangle/sine oscillators plus
filtered noise, so the repo needs no binary audio assets.

Sound design notes:
- Coins form a pitch ladder (coin.wav, coin_1..coin_4.wav) that the game
  climbs while you chain pickups quickly — a rising "combo" feel.
- Each obstacle family has its own crash: trains boom (crash.wav), hurdles
  snap (crash_wood.wav), gates clang (crash_clang.wav).
- beep/go drive the 3-2-1 resume countdown; land/whoosh are gameplay
  feedback for touching down and near-missing an obstacle.
- Everything is in or around A minor so jingles never clash with the music.
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def write_wav(name, samples, volume=0.9):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = volume * 32767 / peak
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-32767, min(32767, s * scale))))
            for s in samples))
    print(f"  {name}: {len(samples)/SR:.2f}s")


def env(i, n, attack=0.01, release=0.3):
    t = i / n
    a = min(1.0, (i / SR) / max(attack, 1e-6))
    r = min(1.0, (1 - t) / max(release, 1e-6))
    return a * min(1.0, r)


def sine(f, t):
    return math.sin(2 * math.pi * f * t)


def square(f, t, duty=0.5):
    return 1.0 if (f * t) % 1.0 < duty else -1.0


def triangle(f, t):
    p = (f * t) % 1.0
    return 4 * abs(p - 0.5) - 1


def tone(freq_fn, dur, osc=sine, attack=0.01, release=0.3, vib=0.0):
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = freq_fn(t) * (1 + vib * math.sin(2 * math.pi * 6 * t))
        phase += f / SR
        out.append(osc(1, phase) * env(i, n, attack, release))
    return out


def noise(dur, lp=0.3, attack=0.005, release=0.4):
    n = int(SR * dur)
    out, last = [], 0.0
    for i in range(n):
        last += lp * (random.uniform(-1, 1) - last)
        out.append(last * env(i, n, attack, release))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0.0 for t in tracks) for i in range(n)]


def gain(track, g):
    return [g * s for s in track]


def concat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out


def silence(dur):
    return [0.0] * int(SR * dur)


NOTES = {}
for octave in range(1, 8):
    for i, name in enumerate(
            ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]):
        NOTES[f"{name}{octave}"] = 440.0 * 2 ** ((octave - 4) + (i - 9) / 12)


def _coin(step):
    """Two-note ding; each combo step climbs the A-minor pentatonic."""
    shift = 2 ** ([0, 2, 4, 7, 9][step] / 12)
    a, b = NOTES["A5"] * shift, NOTES["E6"] * shift
    return concat(
        tone(lambda t: a, 0.06, square, release=0.5),
        mix(tone(lambda t: b, 0.13, square, release=0.25),
            gain(tone(lambda t: b * 2, 0.13, sine, release=0.2), 0.25)),
    )


def _kick():
    return mix(
        tone(lambda t: 150 - 95 * min(1.0, t / 0.06), 0.10, sine,
             attack=0.001, release=0.5),
        gain(noise(0.03, lp=0.9, release=0.2), 0.35),
    )


def _snare():
    return mix(
        noise(0.11, lp=0.55, attack=0.001, release=0.28),
        gain(tone(lambda t: 190, 0.07, sine, attack=0.001, release=0.3), 0.5),
    )


def main():
    os.makedirs(OUT, exist_ok=True)
    random.seed(7)

    # Coin combo ladder: coin.wav is the base, coin_1..4 climb the scale.
    write_wav("coin.wav", _coin(0), 0.5)
    for step in range(1, 5):
        write_wav(f"coin_{step}.wav", _coin(step), 0.5)

    # Jump: rising whoosh with a breath of air.
    write_wav("jump.wav", mix(
        tone(lambda t: 260 + 640 * t / 0.24, 0.24, triangle, release=0.35),
        gain(noise(0.16, lp=0.35, release=0.5), 0.3),
    ), 0.6)

    # Land: soft body thud on touchdown.
    write_wav("land.wav", mix(
        tone(lambda t: 130 - 60 * min(1.0, t / 0.10), 0.12, sine,
             attack=0.001, release=0.5),
        gain(noise(0.07, lp=0.5, attack=0.001, release=0.3), 0.4),
    ), 0.5)

    # Roll: low tumbling whoosh.
    write_wav("roll.wav", mix(
        noise(0.28, lp=0.12, release=0.5),
        gain(tone(lambda t: 110, 0.2, sine, release=0.5), 0.3),
    ), 0.55)

    # Swipe: quick air tick.
    write_wav("swipe.wav", mix(
        noise(0.09, lp=0.5, release=0.3),
        tone(lambda t: 900 - 300 * t / 0.09, 0.09, sine, release=0.3),
    ), 0.35)

    # Whoosh: bigger air rush for shaving past an obstacle (near miss).
    write_wav("whoosh.wav", mix(
        noise(0.24, lp=0.4, attack=0.06, release=0.4),
        gain(tone(lambda t: 520 - 340 * t / 0.24, 0.24, sine,
                  attack=0.05, release=0.4), 0.5),
    ), 0.55)

    # Stumble: descending blip + trip thud.
    write_wav("stumble.wav", mix(
        tone(lambda t: 500 - 260 * t / 0.25, 0.25, square, release=0.3),
        gain(tone(lambda t: 120, 0.1, sine, attack=0.001, release=0.4), 0.6),
    ), 0.6)

    # Crash (train): heavy metal boom with a sub drop.
    write_wav("crash.wav", mix(
        noise(0.55, lp=0.6, attack=0.001, release=0.6),
        tone(lambda t: 170 - 115 * min(1.0, t / 0.5), 0.55, sine,
             attack=0.001, release=0.6),
        gain(tone(lambda t: 58, 0.45, sine, attack=0.001, release=0.7), 0.8),
        gain(tone(lambda t: 820, 0.16, triangle, attack=0.001, release=0.15),
             0.25),
    ), 0.95)

    # Crash (hurdle): dry wooden snap.
    write_wav("crash_wood.wav", mix(
        noise(0.05, lp=0.95, attack=0.001, release=0.15),
        gain(noise(0.16, lp=0.6, attack=0.001, release=0.35), 0.7),
        tone(lambda t: 300 - 170 * min(1.0, t / 0.16), 0.18, square,
             attack=0.001, release=0.3),
        gain(tone(lambda t: 95, 0.2, sine, attack=0.001, release=0.5), 0.6),
    ), 0.85)

    # Crash (gate): inharmonic metallic clang.
    clang_partials = [(620, 0.9), (932, 0.7), (1480, 0.5), (2093, 0.35)]
    write_wav("crash_clang.wav", mix(
        gain(noise(0.06, lp=0.9, attack=0.001, release=0.2), 0.8),
        *[gain(tone(lambda t, f=f: f, 0.5, sine, attack=0.001,
                    release=0.75), g)
          for f, g in clang_partials],
        gain(tone(lambda t: 80, 0.3, sine, attack=0.001, release=0.6), 0.5),
    ), 0.85)

    # Powerup: sparkly rising arpeggio.
    write_wav("powerup.wav", concat(
        tone(lambda t: NOTES["A4"], 0.07, square, release=0.4),
        tone(lambda t: NOTES["C5"], 0.07, square, release=0.4),
        tone(lambda t: NOTES["E5"], 0.07, square, release=0.4),
        mix(tone(lambda t: NOTES["A5"], 0.18, square, release=0.25),
            gain(tone(lambda t: NOTES["E6"], 0.18, sine, release=0.2), 0.4)),
    ), 0.5)

    # Click: tiny UI tick.
    write_wav("click.wav",
              tone(lambda t: 750, 0.05, sine, release=0.15), 0.4)

    # Countdown beep and the final "go!".
    write_wav("beep.wav",
              tone(lambda t: NOTES["A5"], 0.09, square, release=0.3), 0.45)
    write_wav("go.wav", mix(
        tone(lambda t: NOTES["A5"] * 2, 0.16, square, release=0.3),
        gain(tone(lambda t: NOTES["E6"] * 2, 0.16, sine, release=0.25), 0.5),
    ), 0.5)

    # Game over: sad descending minor line, resolving low.
    write_wav("gameover.wav", concat(
        tone(lambda t: NOTES["E5"], 0.18, triangle, release=0.35),
        tone(lambda t: NOTES["C5"], 0.18, triangle, release=0.35),
        tone(lambda t: NOTES["A4"], 0.18, triangle, release=0.35),
        mix(tone(lambda t: NOTES["E4"], 0.45, triangle, release=0.5),
            gain(tone(lambda t: NOTES["A2"], 0.45, sine, release=0.6), 0.6)),
    ), 0.65)

    # High score: triumphant fanfare with a closing chord.
    write_wav("highscore.wav", concat(
        tone(lambda t: NOTES["A4"], 0.11, square, release=0.4),
        tone(lambda t: NOTES["C5"], 0.11, square, release=0.4),
        tone(lambda t: NOTES["E5"], 0.11, square, release=0.4),
        mix(tone(lambda t: NOTES["A5"], 0.55, square, release=0.35),
            tone(lambda t: NOTES["C6"], 0.55, triangle, release=0.35),
            gain(tone(lambda t: NOTES["E6"], 0.55, sine, release=0.3), 0.6)),
    ), 0.6)

    _music()


def _music():
    """16-bar chiptune loop at 140 BPM: kick, snare, hats, bass, arp lead."""
    bpm = 140
    beat = 60.0 / bpm
    eighth = beat / 2

    # Am - F - C - G progression, 4 beats each, repeated twice with a
    # melody variation on the repeat.
    chords = [
        ("A2", ["A4", "C5", "E5"]),
        ("F2", ["F4", "A4", "C5"]),
        ("C3", ["C4", "E4", "G4", "C5"]),
        ("G2", ["G4", "B4", "D5"]),
    ]

    kick, snare = _kick(), _snare()
    bass_t, lead_t, hat_t, drum_t = [], [], [], []
    for rep in range(2):
        for ci, (bass_note, arp) in enumerate(chords):
            for b in range(4):  # beats per chord
                # Bass: pumping eighth notes.
                for e in range(2):
                    f = NOTES[bass_note]
                    bass_t.extend(
                        tone(lambda t, f=f: f, eighth * 0.92, triangle,
                             attack=0.004, release=0.25))
                    bass_t.extend(silence(eighth * 0.08))
                # Lead: arpeggio, upward then bouncing on repeat.
                for e in range(2):
                    idx = (b * 2 + e)
                    seq = arp if rep == 0 else arp[::-1]
                    f = NOTES[seq[(idx + ci) % len(seq)]]
                    lead_t.extend(
                        tone(lambda t, f=f: f, eighth * 0.85, square,
                             attack=0.004, release=0.2, vib=0.004))
                    lead_t.extend(silence(eighth * 0.15))
                # Hats on the off-beat.
                hat_t.extend(silence(eighth))
                hat_t.extend(noise(eighth * 0.35, lp=0.85, release=0.12))
                hat_t.extend(silence(eighth * 0.65))
                # Drums: kick on every beat, snare on 2 and 4.
                hit = mix(kick, gain(snare, 1.0)) if b % 2 == 1 else kick
                drum_t.extend(hit)
                drum_t.extend(silence(beat - len(hit) / SR))

    write_wav("music.wav", mix(
        gain(bass_t, 0.50),
        gain(lead_t, 0.27),
        gain(hat_t, 0.10),
        gain(drum_t, 0.55),
    ), 0.85)


if __name__ == "__main__":
    main()
