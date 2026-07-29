"""Generate the project-owned vehicle SFX set with Python's standard library."""

from __future__ import annotations

import math
import random
import wave
from pathlib import Path

SAMPLE_RATE = 44_100
OUTPUT = Path(__file__).resolve().parents[2] / "art" / "audio" / "vehicle" / "sfx"

# name: duration, base frequency, end frequency, noise mix, pulse rate, gain
SOUNDS = {
    "primary_start": (0.11, 260.0, 720.0, 0.04, 0.0, 0.44),
    "primary_loop": (0.24, 520.0, 590.0, 0.05, 12.0, 0.28),
    "primary_end": (0.10, 410.0, 150.0, 0.03, 0.0, 0.32),
    "impact_enemy": (0.08, 170.0, 95.0, 0.28, 0.0, 0.34),
    "impact_cover": (0.07, 310.0, 120.0, 0.18, 0.0, 0.28),
    "enemy_destroy_small": (0.16, 230.0, 70.0, 0.32, 0.0, 0.38),
    "enemy_destroy_priority": (0.34, 150.0, 46.0, 0.28, 5.0, 0.48),
    "pickup": (0.18, 520.0, 880.0, 0.00, 0.0, 0.32),
    "upgrade_select": (0.13, 390.0, 610.0, 0.00, 0.0, 0.28),
    "upgrade_confirm": (0.28, 330.0, 760.0, 0.00, 4.0, 0.38),
    "boss_warning": (0.62, 82.0, 118.0, 0.08, 3.0, 0.48),
    "player_hull_hit": (0.18, 190.0, 58.0, 0.24, 0.0, 0.46),
}


def render(name: str, spec: tuple[float, float, float, float, float, float]) -> None:
    duration, start_hz, end_hz, noise_mix, pulse_rate, gain = spec
    rng = random.Random(f"cardborne:{name}:v1")
    frames = bytearray()
    count = int(duration * SAMPLE_RATE)
    phase = 0.0
    for index in range(count):
        t = index / max(1, count - 1)
        frequency = start_hz + (end_hz - start_hz) * t
        phase += math.tau * frequency / SAMPLE_RATE
        envelope = math.sin(math.pi * t) ** 0.7
        pulse = 1.0 if pulse_rate <= 0.0 else 0.72 + 0.28 * math.sin(math.tau * pulse_rate * index / SAMPLE_RATE)
        harmonic = math.sin(phase) * 0.78 + math.sin(phase * 2.01) * 0.22
        sample = (harmonic * (1.0 - noise_mix) + rng.uniform(-1.0, 1.0) * noise_mix) * envelope * pulse * gain
        value = max(-32767, min(32767, round(sample * 32767)))
        frames.extend(int(value).to_bytes(2, byteorder="little", signed=True))
    path = OUTPUT / f"{name}.wav"
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(frames)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, spec in SOUNDS.items():
        render(name, spec)
    print(f"generated {len(SOUNDS)} deterministic PCM WAV files in {OUTPUT}")


if __name__ == "__main__":
    main()
