#!/usr/bin/env python3
"""
High-Quality Music Template Synthesizer for Space Shooter 2D
Generates calibrated, comfortable-volume 16-bit 44.1kHz Stereo PCM WAV tracks:
- menu_theme.wav: Ethereal space synth theme for Main Menu & Level Select
- stage_1_4.wav: Sector 1 Normal Stages (Deep Nebula)
- boss_stage_5.wav: Boss Stage 5 Encounter (Swarm Vanguard)
- stage_6_9.wav: Sector 2 Normal Stages (Cosmic Rift)
- boss_stage_10.wav: Boss Stage 10 Encounter (Dragon Roach Queen)
- stage_11_14.wav: Sector 3 Normal Stages (Asteroid Belt)
- boss_stage_15.wav: Boss Stage 15 Encounter (Ancient Dreadnought)
- stage_16_19.wav: Sector 4 Normal Stages (Void Citadel)
- boss_stage_20.wav: Boss Stage 20 Final Encounter (Cosmic Overlord)
- Backward-compatible mirrors: ingame_combat.wav, boss_battle.wav
"""

import os
import math
import wave
import struct
import shutil

SAMPLE_RATE = 44100
MUSIC_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio", "music")

def clamp(v, low=-1.0, high=1.0):
    return max(low, min(high, v))

def note_to_freq(note_str):
    notes = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4,
             'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9,
             'A#': 10, 'Bb': 10, 'B': 11}
    pitch = note_str[:-1]
    octave = int(note_str[-1])
    semitone = notes[pitch] + (octave - 4) * 12 - 9 # Relative to A4
    return 440.0 * (2.0 ** (semitone / 12.0))

class SynthVoice:
    @staticmethod
    def sine(phase):
        return math.sin(phase)

    @staticmethod
    def tri(phase):
        p = (phase / (2 * math.pi)) % 1.0
        return 4.0 * abs(p - 0.5) - 1.0

    @staticmethod
    def saw(phase):
        p = (phase / (2 * math.pi)) % 1.0
        return 2.0 * p - 1.0

    @staticmethod
    def square(phase, pulse_width=0.5):
        p = (phase / (2 * math.pi)) % 1.0
        return 1.0 if p < pulse_width else -1.0


def write_stereo_wav(filepath, left_samples, right_samples, target_peak=0.45):
    """
    Writes stereo 16-bit PCM WAV.
    target_peak=0.45 (~ -7.0 dBFS) ensures the output is gentle and never overly loud.
    """
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    peak = max(max(abs(s) for s in left_samples), max(abs(s) for s in right_samples), 0.001)
    gain = target_peak / peak if peak > 0.001 else 1.0

    num_samples = len(left_samples)
    data = bytearray(num_samples * 4) # 2 channels * 2 bytes
    for i in range(num_samples):
        l = int(clamp(left_samples[i] * gain) * 32767.0)
        r = int(clamp(right_samples[i] * gain) * 32767.0)
        struct.pack_into('<hh', data, i * 4, l, r)

    with wave.open(filepath, 'wb') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(data)
    print(f"[OK] Generated: {os.path.basename(filepath)} ({num_samples/SAMPLE_RATE:.2f}s, Peak: {peak:.2f}, MasterGain: {gain:.2f})")


def generate_menu_theme():
    bpm = 100.0
    sec_per_beat = 60.0 / bpm
    total_beats = 32
    duration = total_beats * sec_per_beat # 19.2s
    total_samples = int(duration * SAMPLE_RATE)

    left = [0.0] * total_samples
    right = [0.0] * total_samples

    progression = [
        {"root": note_to_freq('D2'), "chord": [note_to_freq('F3'), note_to_freq('A3'), note_to_freq('C4'), note_to_freq('E4')]},
        {"root": note_to_freq('Bb1'), "chord": [note_to_freq('F3'), note_to_freq('A3'), note_to_freq('D4'), note_to_freq('F4')]},
        {"root": note_to_freq('C2'), "chord": [note_to_freq('E3'), note_to_freq('G3'), note_to_freq('C4'), note_to_freq('E4')]},
        {"root": note_to_freq('A1'), "chord": [note_to_freq('E3'), note_to_freq('G3'), note_to_freq('C4'), note_to_freq('E4')]},
    ]

    for step_idx, step in enumerate(progression):
        start_sample = int(step_idx * 8 * sec_per_beat * SAMPLE_RATE)
        end_sample = int((step_idx + 1) * 8 * sec_per_beat * SAMPLE_RATE)
        chord_len = end_sample - start_sample

        root_freq = step["root"]
        chord_freqs = step["chord"]

        for s in range(chord_len):
            idx = start_sample + s
            if idx >= total_samples:
                break
            t = s / SAMPLE_RATE
            env = min(1.0, s / (SAMPLE_RATE * 0.4)) * min(1.0, (chord_len - s) / (SAMPLE_RATE * 0.4))

            sub = SynthVoice.sine(2.0 * math.pi * root_freq * t) * 0.28 * env
            pad_l = 0.0
            pad_r = 0.0
            for i, cf in enumerate(chord_freqs):
                p1 = SynthVoice.tri(2.0 * math.pi * (cf * 0.998) * t)
                p2 = SynthVoice.saw(2.0 * math.pi * (cf * 1.002) * t) * 0.18
                p3 = SynthVoice.sine(2.0 * math.pi * cf * t) * 0.35
                voice = (p1 + p2 + p3) * 0.07 * env
                pan = -0.4 + 0.8 * (i / len(chord_freqs))
                pad_l += voice * (1.0 - pan)
                pad_r += voice * (1.0 + pan)

            left[idx] += sub + pad_l
            right[idx] += sub + pad_r

    arp_notes_pool = [
        ['D4', 'F4', 'A4', 'C5', 'E5', 'A4', 'F4', 'C5'],
        ['Bb3', 'D4', 'F4', 'A4', 'D5', 'A4', 'F4', 'D4'],
        ['C4', 'E4', 'G4', 'C5', 'E5', 'G4', 'E4', 'C5'],
        ['A3', 'C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4'],
    ]
    sixteenth_dur = sec_per_beat / 4.0
    sixteenth_samples = int(sixteenth_dur * SAMPLE_RATE)
    total_16ths = total_beats * 4

    for i in range(total_16ths):
        prog_idx = min(3, (i // 32))
        note_name = arp_notes_pool[prog_idx][i % 8]
        freq = note_to_freq(note_name)
        note_start = int(i * sixteenth_samples)
        pan = 0.35 * math.sin(i * 0.8)

        for s in range(min(sixteenth_samples * 2, total_samples - note_start)):
            idx = note_start + s
            t = s / SAMPLE_RATE
            env = math.exp(-t * 9.0) * 0.14
            tone = (SynthVoice.sine(2.0 * math.pi * freq * t) +
                    SynthVoice.sine(2.0 * math.pi * freq * 2.0 * t) * 0.2 +
                    SynthVoice.tri(2.0 * math.pi * freq * 0.5 * t) * 0.12) * env
            left[idx] += tone * (1.0 - pan)
            right[idx] += tone * (1.0 + pan)

    # Click-free loop crossfade
    xfade = int(0.2 * SAMPLE_RATE)
    for s in range(xfade):
        w = s / float(xfade)
        end_idx = total_samples - xfade + s
        left[s] = left[s] * w + left[end_idx] * (1.0 - w)
        right[s] = right[s] * w + right[end_idx] * (1.0 - w)
        left[end_idx] = left[s]
        right[end_idx] = right[s]

    write_stereo_wav(os.path.join(MUSIC_DIR, "menu_theme.wav"), left, right, 0.45)


def generate_normal_stage_track(filename, bpm, root_notes, melody_notes, title_desc):
    sec_per_beat = 60.0 / bpm
    total_beats = 32
    duration = total_beats * sec_per_beat # ~14-16s
    total_samples = int(duration * SAMPLE_RATE)

    left = [0.0] * total_samples
    right = [0.0] * total_samples

    sixteenth_dur = sec_per_beat / 4.0
    sixteenth_samples = int(sixteenth_dur * SAMPLE_RATE)
    total_16ths = total_beats * 4

    # 1. Soft punchy kick & snare
    for b in range(total_beats):
        beat_start = int(b * sec_per_beat * SAMPLE_RATE)
        for s in range(min(int(0.16 * SAMPLE_RATE), total_samples - beat_start)):
            idx = beat_start + s
            t = s / SAMPLE_RATE
            freq = 130.0 * math.exp(-t * 30.0) + 42.0
            env = math.exp(-t * 18.0)
            k = math.sin(2.0 * math.pi * freq * t) * env * 0.55
            left[idx] += k
            right[idx] += k

        if b % 2 == 1:
            for s in range(min(int(0.18 * SAMPLE_RATE), total_samples - beat_start)):
                idx = beat_start + s
                t = s / SAMPLE_RATE
                env = math.exp(-t * 24.0)
                noise = (math.sin(s * 1103.7) % 1.0 - 0.5) * 1.5 * env * 0.32
                body = math.sin(2.0 * math.pi * 180.0 * t) * env * 0.22
                left[idx] += (noise + body) * 0.95
                right[idx] += (noise + body) * 1.05

    # 2. Hi-hats
    for i in range(total_16ths):
        h_start = int(i * sixteenth_samples)
        accent = 0.8 if i % 4 == 2 else 0.4
        for s in range(min(int(0.045 * SAMPLE_RATE), total_samples - h_start)):
            idx = h_start + s
            t = s / SAMPLE_RATE
            h = (math.sin(s * 739.1) % 1.0 - 0.5) * 0.18 * math.exp(-t * 75.0) * accent
            pan = 0.2 if i % 2 == 0 else -0.2
            left[idx] += h * (1.0 - pan)
            right[idx] += h * (1.0 + pan)

    # 3. Rolling Bassline
    roots = [note_to_freq(r) for r in root_notes]
    for i in range(total_16ths):
        prog_idx = (i // 32) % len(roots)
        root = roots[prog_idx]
        freq = root * 2.0 if (i % 4 in [1, 3]) else root

        b_start = int(i * sixteenth_samples)
        for s in range(min(int(sixteenth_dur * 0.9 * SAMPLE_RATE), total_samples - b_start)):
            idx = b_start + s
            t = s / SAMPLE_RATE
            env = math.exp(-t * 20.0) * 0.26
            bass = (SynthVoice.saw(2.0 * math.pi * freq * t) * 0.55 +
                    SynthVoice.square(2.0 * math.pi * freq * t, 0.4) * 0.35) * env
            left[idx] += bass
            right[idx] += bass

    # 4. Melodic Synth Motif
    eighth_dur = sec_per_beat / 2.0
    eighth_samples = int(eighth_dur * SAMPLE_RATE)
    for step_idx, m_note in enumerate(melody_notes):
        freq = note_to_freq(m_note)
        m_start = int(step_idx * eighth_samples)
        pan = 0.28 * math.sin(step_idx * 1.1)

        for s in range(min(int(eighth_dur * 1.4 * SAMPLE_RATE), total_samples - m_start)):
            idx = m_start + s
            t = s / SAMPLE_RATE
            env = min(1.0, t / 0.015) * math.exp(-t * 6.0) * 0.15
            lead = (SynthVoice.saw(2.0 * math.pi * freq * t) * 0.4 +
                    SynthVoice.tri(2.0 * math.pi * (freq * 1.002) * t) * 0.4) * env
            left[idx] += lead * (1.0 - pan)
            right[idx] += lead * (1.0 + pan)

    # Seamless crossfade
    xfade = int(0.15 * SAMPLE_RATE)
    for s in range(xfade):
        w = s / float(xfade)
        end_idx = total_samples - xfade + s
        left[s] = left[s] * w + left[end_idx] * (1.0 - w)
        right[s] = right[s] * w + right[end_idx] * (1.0 - w)
        left[end_idx] = left[s]
        right[end_idx] = right[s]

    write_stereo_wav(os.path.join(MUSIC_DIR, filename), left, right, 0.45)


def generate_boss_stage_track(filename, bpm, root_chords, trill_notes, title_desc):
    sec_per_beat = 60.0 / bpm
    total_beats = 32
    duration = total_beats * sec_per_beat # ~13-14s
    total_samples = int(duration * SAMPLE_RATE)

    left = [0.0] * total_samples
    right = [0.0] * total_samples

    sixteenth_dur = sec_per_beat / 4.0
    sixteenth_samples = int(sixteenth_dur * SAMPLE_RATE)
    total_16ths = total_beats * 4

    # 1. Driving double-kick & metal snare
    kick_pattern_16ths = [0, 2, 4, 7, 8, 10, 12, 14]
    for b in range(0, total_beats, 4):
        for k_16 in kick_pattern_16ths:
            k_start = int((b * 4 + k_16) * sixteenth_samples)
            if k_start >= total_samples:
                break
            for s in range(min(int(0.18 * SAMPLE_RATE), total_samples - k_start)):
                idx = k_start + s
                t = s / SAMPLE_RATE
                freq = 160.0 * math.exp(-t * 30.0) + 38.0
                kick = math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 15.0) * 0.65
                left[idx] += kick
                right[idx] += kick

        for sn_16 in [4, 12]:
            sn_start = int((b * 4 + sn_16) * sixteenth_samples)
            if sn_start >= total_samples:
                break
            for s in range(min(int(0.22 * SAMPLE_RATE), total_samples - sn_start)):
                idx = sn_start + s
                t = s / SAMPLE_RATE
                noise = (math.sin(s * 1511.9) % 1.0 - 0.5) * 1.8 * math.exp(-t * 18.0) * 0.38
                metal = math.sin(2.0 * math.pi * 310.0 * t) * math.exp(-t * 16.0) * 0.25
                left[idx] += (noise + metal) * 1.05
                right[idx] += (noise + metal) * 0.95

    # 2. Distorted Boss Bass & Chords
    for i in range(total_16ths):
        bar_idx = (i // 32) % len(root_chords)
        c_info = root_chords[bar_idx]
        root_f = note_to_freq(c_info["root"])

        b_start = int(i * sixteenth_samples)
        for s in range(min(int(sixteenth_dur * 0.88 * SAMPLE_RATE), total_samples - b_start)):
            idx = b_start + s
            t = s / SAMPLE_RATE
            env = math.exp(-t * 16.0) * 0.3
            raw = (SynthVoice.saw(2.0 * math.pi * root_f * t) * 0.6 +
                   SynthVoice.square(2.0 * math.pi * root_f * 2.0 * t, 0.35) * 0.4)
            distorted = math.tanh(raw * 1.5) * env
            left[idx] += distorted
            right[idx] += distorted

    # Dramatic chord stabs
    stab_positions = [0, 3, 6, 10, 12, 14]
    for b in range(0, total_beats, 4):
        bar_idx = (b // 8) % len(root_chords)
        stabs = [note_to_freq(n) for n in root_chords[bar_idx]["stabs"]]
        for p in stab_positions:
            s_start = int((b * 4 + p) * sixteenth_samples)
            if s_start >= total_samples:
                break
            for s in range(min(int(0.16 * SAMPLE_RATE), total_samples - s_start)):
                idx = s_start + s
                t = s / SAMPLE_RATE
                env = min(1.0, t / 0.01) * math.exp(-t * 12.0) * 0.16
                for ci, cf in enumerate(stabs):
                    v = (SynthVoice.saw(2.0 * math.pi * cf * t) + SynthVoice.saw(2.0 * math.pi * (cf * 1.004) * t)) * 0.45 * env
                    pan = -0.3 + 0.3 * ci
                    left[idx] += v * (1.0 - pan)
                    right[idx] += v * (1.0 + pan)

    # 3. Urgency High Trills
    for i in range(total_16ths):
        n_name = trill_notes[i % len(trill_notes)]
        freq = note_to_freq(n_name)
        t_start = int(i * sixteenth_samples)
        pan = 0.35 * math.sin(i * 1.4)
        for s in range(min(int(sixteenth_dur * 1.1 * SAMPLE_RATE), total_samples - t_start)):
            idx = t_start + s
            t = s / SAMPLE_RATE
            env = math.exp(-t * 24.0) * 0.12
            lead = (SynthVoice.saw(2.0 * math.pi * freq * t) * 0.5 + SynthVoice.tri(2.0 * math.pi * freq * t) * 0.5) * env
            left[idx] += lead * (1.0 - pan)
            right[idx] += lead * (1.0 + pan)

    # Loop crossfade
    xfade = int(0.15 * SAMPLE_RATE)
    for s in range(xfade):
        w = s / float(xfade)
        end_idx = total_samples - xfade + s
        left[s] = left[s] * w + left[end_idx] * (1.0 - w)
        right[s] = right[s] * w + right[end_idx] * (1.0 - w)
        left[end_idx] = left[s]
        right[end_idx] = right[s]

    write_stereo_wav(os.path.join(MUSIC_DIR, filename), left, right, 0.45)


def main():
    print("=== Synthesizing Calibrated, Quieter Music Templates ===")
    # Main Menu
    generate_menu_theme()

    # Stage 1-4: Sector 1 (Deep Nebula) in D minor
    generate_normal_stage_track(
        "stage_1_4.wav",
        bpm=120.0,
        root_notes=['D2', 'Bb1', 'F2', 'C2'],
        melody_notes=['D5', 'F5', 'A5', 'C6', 'A5', 'F5', 'D5', 'E5',
                      'F5', 'G5', 'A5', 'D6', 'C6', 'A5', 'G5', 'F5',
                      'E5', 'G5', 'C6', 'E6', 'D6', 'C6', 'A5', 'G5',
                      'A5', 'C6', 'E6', 'F6', 'E6', 'D6', 'C6', 'A5'],
        title_desc="Sector 1 (Stages 1-4): Deep Nebula"
    )

    # Boss Stage 5: Swarm Vanguard in G minor
    generate_boss_stage_track(
        "boss_stage_5.wav",
        bpm=136.0,
        root_chords=[
            {"root": 'G1', "stabs": ['Bb3', 'D4', 'G4']},
            {"root": 'Eb1', "stabs": ['Bb3', 'Eb4', 'G4']},
            {"root": 'F1', "stabs": ['A3', 'C4', 'F4']},
            {"root": 'D1', "stabs": ['A3', 'C4', 'D4']},
        ],
        trill_notes=['G5', 'Bb5', 'D6', 'G6', 'D6', 'Bb5', 'A5', 'Bb5',
                     'Eb5', 'G5', 'Bb5', 'Eb6', 'Bb5', 'G5', 'F5', 'G5'],
        title_desc="Boss Stage 5: Swarm Vanguard"
    )

    # Stage 6-9: Sector 2 (Cosmic Rift) in A minor
    generate_normal_stage_track(
        "stage_6_9.wav",
        bpm=128.0,
        root_notes=['A1', 'F1', 'C2', 'G1'],
        melody_notes=['E5', 'E5', 'D5', 'C5', 'A4', 'C5', 'D5', 'E5',
                      'G5', 'E5', 'D5', 'C5', 'A4', 'B4', 'C5', 'D5',
                      'F5', 'F5', 'E5', 'D5', 'A4', 'C5', 'D5', 'F5',
                      'A5', 'G5', 'E5', 'D5', 'B4', 'C5', 'D5', 'E5'],
        title_desc="Sector 2 (Stages 6-9): Cosmic Rift"
    )

    # Boss Stage 10: Dragon Roach Queen in C minor
    generate_boss_stage_track(
        "boss_stage_10.wav",
        bpm=145.0,
        root_chords=[
            {"root": 'C1', "stabs": ['Eb3', 'G3', 'C4']},
            {"root": 'Ab0', "stabs": ['Eb3', 'Ab3', 'C4']},
            {"root": 'F1', "stabs": ['F3', 'Ab3', 'C4']},
            {"root": 'G1', "stabs": ['D3', 'G3', 'B3']},
        ],
        trill_notes=['C5', 'Eb5', 'G5', 'C6', 'G5', 'Eb5', 'D5', 'Eb5',
                     'C5', 'Eb5', 'G5', 'C6', 'G5', 'Ab5', 'G5', 'Eb5',
                     'Ab4', 'C5', 'Eb5', 'Ab5', 'Eb5', 'C5', 'Bb4', 'C5',
                     'G4', 'B4', 'D5', 'G5', 'F5', 'D5', 'B4', 'D5'],
        title_desc="Boss Stage 10: Dragon Roach Queen"
    )

    # Stage 11-14: Sector 3 (Asteroid Belt) in E minor
    generate_normal_stage_track(
        "stage_11_14.wav",
        bpm=132.0,
        root_notes=['E1', 'C2', 'G1', 'D1'],
        melody_notes=['B4', 'E5', 'G5', 'B5', 'A5', 'G5', 'E5', 'F#5',
                      'G5', 'A5', 'B5', 'E6', 'D6', 'B5', 'A5', 'G5',
                      'C5', 'E5', 'G5', 'C6', 'B5', 'G5', 'E5', 'D5',
                      'D5', 'F#5', 'A5', 'D6', 'C6', 'A5', 'F#5', 'D5'],
        title_desc="Sector 3 (Stages 11-14): Asteroid Belt"
    )

    # Boss Stage 15: Ancient Dreadnought in F minor
    generate_boss_stage_track(
        "boss_stage_15.wav",
        bpm=140.0,
        root_chords=[
            {"root": 'F1', "stabs": ['Ab3', 'C4', 'F4']},
            {"root": 'Db1', "stabs": ['Ab3', 'Db4', 'F4']},
            {"root": 'Bb0', "stabs": ['Bb3', 'Db4', 'F4']},
            {"root": 'C1', "stabs": ['G3', 'C4', 'E4']},
        ],
        trill_notes=['F5', 'Ab5', 'C6', 'F6', 'C6', 'Ab5', 'G5', 'Ab5',
                     'Db5', 'F5', 'Ab5', 'Db6', 'Ab5', 'F5', 'Eb5', 'F5'],
        title_desc="Boss Stage 15: Ancient Dreadnought"
    )

    # Stage 16-19: Sector 4 (Void Citadel) in B minor
    generate_normal_stage_track(
        "stage_16_19.wav",
        bpm=136.0,
        root_notes=['B1', 'G1', 'D2', 'A1'],
        melody_notes=['F#5', 'F#5', 'E5', 'D5', 'B4', 'D5', 'E5', 'F#5',
                      'A5', 'F#5', 'E5', 'D5', 'B4', 'C#5', 'D5', 'E5',
                      'G5', 'G5', 'F#5', 'E5', 'B4', 'D5', 'E5', 'G5',
                      'B5', 'A5', 'F#5', 'E5', 'C#5', 'D5', 'E5', 'F#5'],
        title_desc="Sector 4 (Stages 16-19): Void Citadel"
    )

    # Boss Stage 20: Cosmic Overlord in D minor
    generate_boss_stage_track(
        "boss_stage_20.wav",
        bpm=150.0,
        root_chords=[
            {"root": 'D1', "stabs": ['F3', 'A3', 'D4']},
            {"root": 'Bb0', "stabs": ['F3', 'Bb3', 'D4']},
            {"root": 'G1', "stabs": ['G3', 'Bb3', 'D4']},
            {"root": 'A1', "stabs": ['E3', 'A3', 'C#4']},
        ],
        trill_notes=['D5', 'F5', 'A5', 'D6', 'A5', 'F5', 'E5', 'F5',
                     'Bb4', 'D5', 'F5', 'Bb5', 'F5', 'D5', 'C5', 'D5',
                     'G4', 'Bb4', 'D5', 'G5', 'F5', 'D5', 'C#5', 'D5',
                     'A4', 'C#5', 'E5', 'A5', 'G5', 'E5', 'C#5', 'A4'],
        title_desc="Final Boss Stage 20: Cosmic Overlord"
    )

    # Backwards-compatible aliases
    shutil.copy(os.path.join(MUSIC_DIR, "stage_1_4.wav"), os.path.join(MUSIC_DIR, "ingame_combat.wav"))
    shutil.copy(os.path.join(MUSIC_DIR, "boss_stage_10.wav"), os.path.join(MUSIC_DIR, "boss_battle.wav"))
    print("[OK] Created backward-compatible mirrors: ingame_combat.wav & boss_battle.wav")

    print("=== All 9 Dedicated Stage Music Templates Synthesized Successfully! ===")

if __name__ == "__main__":
    main()
