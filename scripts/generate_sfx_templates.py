#!/usr/bin/env python3
"""
Sound Effect Template Synthesizer for Space Shooter 2D
Generates calibrated, clean 16-bit 44.1kHz Stereo/Mono PCM WAV files in assets/audio/sfx/
"""

import os
import math
import wave
import struct

SAMPLE_RATE = 44100
SFX_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio", "sfx")

def clamp(v, low=-1.0, high=1.0):
    return max(low, min(high, v))

def write_wav(filepath, samples, target_peak=0.5):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    peak = max(max(abs(s) for s in samples), 0.001)
    gain = target_peak / peak if peak > 0.001 else 1.0

    num_samples = len(samples)
    data = bytearray(num_samples * 2)
    for i in range(num_samples):
        val = int(clamp(samples[i] * gain) * 32767.0)
        struct.pack_into('<h', data, i * 2, val)

    with wave.open(filepath, 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(data)
    print(f"[OK] Generated SFX: {os.path.basename(filepath)} ({num_samples/SAMPLE_RATE:.3f}s)")


def gen_button_click():
    dur = 0.085
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        freq = 1200.0 * math.exp(-t * 35.0) + 520.0
        tone1 = math.sin(2.0 * math.pi * freq * t)
        tone2 = math.sin(2.0 * math.pi * (freq * 1.5) * t) * 0.35
        click_impulse = (1.0 - t / 0.004) * 0.4 if t < 0.004 else 0.0
        env = math.pow(1.0 - progress, 1.6)
        s = (tone1 * 0.7 + tone2 + click_impulse) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "button_click.wav"), samples, 0.80)


def gen_play_start():
    dur = 0.22
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        freq = 440.0 if progress < 0.33 else (660.0 if progress < 0.66 else 880.0)
        env = math.pow(1.0 - progress, 1.2)
        s = math.sin(2.0 * math.pi * freq * t) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "play_start.wav"), samples, 0.48)


def gen_modal_chime():
    dur = 0.14
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        freq = 523.25 if progress < 0.5 else 659.25
        env = math.exp(-t * 22.0)
        s = (math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "modal_chime.wav"), samples, 0.45)


def gen_level_complete():
    dur = 0.38
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.50]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        idx = min(3, int(progress * 4.0))
        freq = notes[idx]
        sub_t = (progress * 4.0) % 1.0
        env = math.pow(1.0 - sub_t, 1.4) * (1.2 if idx == 3 else 0.8)
        s = (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "level_complete.wav"), samples, 0.48)


def gen_purchase():
    dur = 0.24
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    notes = [523.25, 659.25, 783.99]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        idx = min(2, int(progress * 3.0))
        freq = notes[idx]
        env = math.exp(-((progress * 3.0) % 1.0) * 12.0)
        s = (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "purchase.wav"), samples, 0.45)


def gen_wave_start():
    dur = 0.24
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    notes = [330.0, 440.0]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        idx = min(1, int(progress * 2.0))
        freq = notes[idx]
        env = math.pow(1.0 - progress, 1.2)
        s = (math.sin(2.0 * math.pi * freq * t) * 0.7 + math.sin(4.0 * math.pi * freq * t) * 0.3) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "wave_start.wav"), samples, 0.45)


def gen_wave_clear():
    dur = 0.32
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    notes = [440.0, 554.37, 659.25]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        idx = min(2, int(progress * 3.0))
        freq = notes[idx]
        env = math.pow(1.0 - progress, 1.3)
        s = (math.sin(2.0 * math.pi * freq * t) * 0.7 + math.sin(4.0 * math.pi * freq * t) * 0.3) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "wave_clear.wav"), samples, 0.46)


def gen_boss_warning():
    dur = 0.5
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Siren pitch sweep
        freq = 300.0 + 200.0 * math.sin(2.0 * math.pi * 4.0 * t)
        env = min(1.0, t / 0.05) * math.exp(-t * 2.5)
        s = (math.sin(2.0 * math.pi * freq * t) * 0.6 + (1.0 if (t * freq % 1.0) < 0.5 else -1.0) * 0.2) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "boss_warning.wav"), samples, 0.48)


def gen_player_hit():
    dur = 0.16
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        progress = i / num_samples
        freq = 170.0 * (1.0 - progress) + 45.0 * progress
        t = i / SAMPLE_RATE
        wave_val = 1.0 if (t * freq % 1.0) < 0.5 else -1.0
        noise = (math.sin(i * 1234.5) % 1.0 - 0.5) * 2.0
        env = math.pow(1.0 - progress, 2.5)
        s = (wave_val * 0.6 + noise * 0.4) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "player_hit.wav"), samples, 0.48)


def gen_shield_hit():
    dur = 0.20
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        progress = i / num_samples
        freq = 440.0 * (1.0 - progress) + 880.0 * progress
        t = i / SAMPLE_RATE
        wave_val = math.sin(2.0 * math.pi * freq * t) * 0.7 + math.sin(3.0 * math.pi * freq * t) * 0.3
        env = math.sin(progress * math.pi)
        samples.append(wave_val * env)
    write_wav(os.path.join(SFX_DIR, "shield_hit.wav"), samples, 0.46)


def gen_player_die():
    dur = 0.45
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        progress = i / num_samples
        freq = 140.0 * math.exp(-t * 12.0) + 30.0
        sub = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 9876.5) % 1.0 - 0.5) * 2.0
        env = math.exp(-t * 6.5)
        samples.append((sub * 0.55 + noise * 0.45) * env)
    write_wav(os.path.join(SFX_DIR, "player_die.wav"), samples, 0.5)


def gen_enemy_explode():
    dur = 0.22
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 190.0 * math.exp(-t * 18.0) + 40.0
        pop = math.sin(2.0 * math.pi * freq * t)
        noise = (math.sin(i * 3456.7) % 1.0 - 0.5) * 2.0
        env = math.exp(-t * 14.0)
        samples.append((pop * 0.5 + noise * 0.5) * env)
    write_wav(os.path.join(SFX_DIR, "enemy_explode.wav"), samples, 0.46)


def gen_laser_shoot():
    dur = 0.12
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        progress = i / num_samples
        freq = 950.0 * (1.0 - progress) + 180.0 * progress
        t = i / SAMPLE_RATE
        env = math.exp(-t * 22.0)
        s = math.sin(2.0 * math.pi * freq * t) * env
        samples.append(s)
    write_wav(os.path.join(SFX_DIR, "laser_shoot.wav"), samples, 0.48)


def gen_cannon_shoot():
    dur = 0.28
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        progress = i / num_samples
        freq = 280.0 * (1.0 - progress) + 35.0 * progress
        t = i / SAMPLE_RATE
        env = math.exp(-t * 12.0)
        punch = math.sin(2.0 * math.pi * freq * t) * 0.7
        noise = (math.sin(i * 4567.8) % 1.0 - 0.5) * 0.3
        samples.append((punch + noise) * env)
    write_wav(os.path.join(SFX_DIR, "cannon_shoot.wav"), samples, 0.5)


def main():
    print("=== Synthesizing Calibrated Sound Effect Templates ===")
    gen_button_click()
    gen_play_start()
    gen_modal_chime()
    gen_level_complete()
    gen_purchase()
    gen_wave_start()
    gen_wave_clear()
    gen_boss_warning()
    gen_player_hit()
    gen_shield_hit()
    gen_player_die()
    gen_enemy_explode()
    gen_laser_shoot()
    gen_cannon_shoot()
    print("=== All Sound Effect Templates Generated in assets/audio/sfx/ ===")

if __name__ == "__main__":
    main()
