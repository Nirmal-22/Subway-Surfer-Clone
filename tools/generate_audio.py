#!/usr/bin/env python3
"""Synthesizes all game audio (SFX + music loop) into assets/audio/ as WAVs.

Pure-stdlib chiptune-style synthesis: square/triangle/sine oscillators plus
filtered noise, so the repo needs no binary audio assets.
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


def concat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out


def silence(dur):
    return [0.0] * int(SR * dur)


NOTES = {}
for octave in range(2, 7):
    for i, name in enumerate(
            ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]):
        NOTES[f"{name}{octave}"] = 440.0 * 2 ** ((octave - 4) + (i - 9) / 12)


def main():
    os.makedirs(OUT, exist_ok=True)
    random.seed(7)

    # Coin: bright two-note ding.
    write_wav("coin.wav", concat(
        tone(lambda t: NOTES["B5"], 0.07, square, release=0.5),
        tone(lambda t: NOTES["E6"], 0.12, square, release=0.25),
    ), 0.5)

    # Jump: rising whoosh.
    write_wav("jump.wav",
              tone(lambda t: 280 + 620 * t / 0.22, 0.22, triangle,
                   release=0.35), 0.6)

    # Roll: low noise whoosh.
    write_wav("roll.wav", noise(0.28, lp=0.12, release=0.5), 0.55)

    # Swipe: quick air tick.
    write_wav("swipe.wav", mix(
        noise(0.09, lp=0.5, release=0.3),
        tone(lambda t: 900 - 300 * t / 0.09, 0.09, sine, release=0.3),
    ), 0.35)

    # Stumble: descending blip.
    write_wav("stumble.wav",
              tone(lambda t: 500 - 260 * t / 0.25, 0.25, square,
                   release=0.3), 0.6)

    # Crash: noise burst + falling thud.
    write_wav("crash.wav", mix(
        noise(0.5, lp=0.6, release=0.7),
        tone(lambda t: 160 - 100 * t / 0.5, 0.5, sine, release=0.6),
        tone(lambda t: 90, 0.35, sine, release=0.8),
    ), 0.95)

    # Powerup: rising arpeggio.
    write_wav("powerup.wav", concat(
        tone(lambda t: NOTES["C5"], 0.09, square, release=0.4),
        tone(lambda t: NOTES["E5"], 0.09, square, release=0.4),
        tone(lambda t: NOTES["G5"], 0.09, square, release=0.4),
        tone(lambda t: NOTES["C6"], 0.16, square, release=0.25),
    ), 0.5)

    # Click: tiny UI tick.
    write_wav("click.wav",
              tone(lambda t: 750, 0.05, sine, release=0.15), 0.4)

    # Game over: sad descending minor line.
    write_wav("gameover.wav", concat(
        tone(lambda t: NOTES["E5"], 0.18, triangle, release=0.35),
        tone(lambda t: NOTES["C5"], 0.18, triangle, release=0.35),
        tone(lambda t: NOTES["A4"], 0.18, triangle, release=0.35),
        tone(lambda t: NOTES["E4"], 0.42, triangle, release=0.5),
    ), 0.65)

    # High score: triumphant fanfare.
    write_wav("highscore.wav", concat(
        tone(lambda t: NOTES["C5"], 0.12, square, release=0.4),
        tone(lambda t: NOTES["E5"], 0.12, square, release=0.4),
        tone(lambda t: NOTES["G5"], 0.12, square, release=0.4),
        mix(tone(lambda t: NOTES["C6"], 0.5, square, release=0.35),
            tone(lambda t: NOTES["E6"], 0.5, triangle, release=0.35)),
    ), 0.6)

    _music()


def _music():
    """16-bar chiptune loop at 140 BPM: bass, arpeggio lead, hats."""
    bpm = 140
    beat = 60.0 / bpm
    eighth = beat / 2

    # Am - F - C - G progression, 4 beats each, repeated twice with a
    # melody variation.
    chords = [
        ("A2", ["A4", "C5", "E5"]),
        ("F2", ["F4", "A4", "C5"]),
        ("C3", ["C4", "E4", "G4", "C5"]),
        ("G2", ["G4", "B4", "D5"]),
    ]

    bass_t, lead_t, hat_t = [], [], []
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

    bass = [0.55 * s for s in bass_t]
    lead = [0.30 * s for s in lead_t]
    hats = [0.12 * s for s in hat_t]
    write_wav("music.wav", mix(bass, lead, hats), 0.85)


if __name__ == "__main__":
    main()
