#!/usr/bin/env python3
"""
Procedural Generator for 4 High-Definition Seamless Parallax Backgrounds.
Creates 1920x1080 horizontally repeating textures for the 4 Campaign Sectors:
- Sector 1 (Stages 1-5): Deep Nebula Frontier (Cyan / Indigo / Celestial Azure)
- Sector 2 (Stages 6-10): Solar Hazard & Cosmic Rift (Amber / Crimson / Solar Flare)
- Sector 3 (Stages 11-15): Asteroid Perimeter (Deep Petrol Teal / Radioactive Jade)
- Sector 4 (Stages 16-20): Alien Void Citadel (Dark Matter Violet / Singularity Magenta)

All images are mathematically guaranteed to repeat seamlessly across the horizontal axis:
f(x = 0, y) == f(x = W, y) for all y in [0, H-1].
"""

import os
import math
import struct
import zlib
import time

OUTPUT_DIR = "/Users/idil/GodotProjectFile/new-game-auto/assets/textures/backgrounds"
WIDTH = 1920
HEIGHT = 1080

def write_png(filepath: str, width: int, height: int, rgba_bytes: bytearray):
    """Encodes raw RGBA bytes into a standard PNG file using zlib."""
    raw = bytearray()
    row_bytes = width * 4
    for y in range(height):
        raw.append(0)  # Filter type 0 (None)
        start = y * row_bytes
        raw.extend(rgba_bytes[start : start + row_bytes])

    compressed = zlib.compress(bytes(raw), 6)

    def chunk(chunk_type: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(chunk_type + data) & 0xffffffff
        return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)

    png_data = bytearray(b"\x89PNG\r\n\x1a\n")
    # IHDR
    png_data.extend(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
    # IDAT
    png_data.extend(chunk(b"IDAT", compressed))
    # IEND
    png_data.extend(chunk(b"IEND", b""))

    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "wb") as f:
        f.write(png_data)
    print(f"[GEN] Generated {os.path.basename(filepath)} ({width}x{height}, {len(png_data)//1024} KB)")


def clamp(val, low=0.0, high=1.0):
    return max(low, min(high, val))


def generate_sector_1(width: int, height: int) -> bytearray:
    """Sector 1 (Stages 1-5): Deep Nebula Frontier (Cyan / Indigo / Celestial Azure)"""
    rgba = bytearray(width * height * 4)

    # Periodic horizontal harmonic tables
    h1 = [math.sin(2 * math.pi * 1 * x / width) for x in range(width)]
    h2 = [math.cos(2 * math.pi * 2 * x / width) for x in range(width)]
    h3 = [math.sin(2 * math.pi * 3 * x / width + 1.2) for x in range(width)]
    h5 = [math.cos(2 * math.pi * 5 * x / width + 0.4) for x in range(width)]

    for y in range(height):
        yn = y / height
        y_cent = 1.0 - abs(yn - 0.52) * 1.8
        y_cent = clamp(y_cent, 0.0, 1.0)

        # Secondary upper gas stream
        y_stream = 1.0 - abs(yn - 0.28) * 3.5
        y_stream = clamp(y_stream, 0.0, 1.0)

        row_offset = y * width * 4
        for x in range(width):
            # Base deep space void
            r = 0.025 + 0.015 * yn
            g = 0.035 + 0.02 * yn
            b = 0.085 + 0.03 * (1.0 - yn)

            # Central Cyan Nebula Cloud
            wave_a = 0.5 * h1[x] + 0.3 * h2[x] + 0.2 * h3[x]
            cloud_a = clamp((wave_a + 0.8) * 0.55 * y_cent)

            r += cloud_a * 0.12
            g += cloud_a * 0.45
            b += cloud_a * 0.85

            # Secondary Celestial Azure Filament
            wave_b = 0.6 * h2[x] + 0.4 * h5[x]
            cloud_b = clamp((wave_b + 0.7) * 0.45 * y_stream)

            r += cloud_b * 0.20
            g += cloud_b * 0.15
            b += cloud_b * 0.65

            # Write clamped pixel
            idx = row_offset + x * 4
            rgba[idx] = int(clamp(r) * 255)
            rgba[idx + 1] = int(clamp(g) * 255)
            rgba[idx + 2] = int(clamp(b) * 255)
            rgba[idx + 3] = 255

    return rgba


def generate_sector_2(width: int, height: int) -> bytearray:
    """Sector 2 (Stages 6-10): Solar Hazard & Cosmic Rift (Amber / Crimson / Solar Flare)"""
    rgba = bytearray(width * height * 4)

    h1 = [math.sin(2 * math.pi * 1 * x / width + 0.8) for x in range(width)]
    h2 = [math.cos(2 * math.pi * 2 * x / width + 2.1) for x in range(width)]
    h4 = [math.sin(2 * math.pi * 4 * x / width + 0.5) for x in range(width)]
    h6 = [math.cos(2 * math.pi * 6 * x / width + 1.7) for x in range(width)]

    for y in range(height):
        yn = y / height
        # Diagonal plasma drift
        y_band = 1.0 - abs(yn - 0.45) * 1.6
        y_band = clamp(y_band, 0.0, 1.0)

        # High flare filament
        y_flare = 1.0 - abs(yn - 0.72) * 3.2
        y_flare = clamp(y_flare, 0.0, 1.0)

        row_offset = y * width * 4
        for x in range(width):
            # Base warm obsidian void
            r = 0.08 + 0.03 * yn
            g = 0.02 + 0.01 * yn
            b = 0.03 + 0.02 * (1.0 - yn)

            # Fiery Solar Amber River
            plasma = 0.45 * h1[x] + 0.35 * h2[x] + 0.2 * h4[x]
            plasma_val = clamp((plasma + 0.75) * 0.6 * y_band)

            r += plasma_val * 0.95
            g += plasma_val * 0.52
            b += plasma_val * 0.12

            # Intense Solar Flare Corona
            flare = 0.6 * h2[x] + 0.4 * h6[x]
            flare_val = clamp((flare + 0.8) * 0.4 * y_flare)

            r += flare_val * 0.90
            g += flare_val * 0.22
            b += flare_val * 0.35

            idx = row_offset + x * 4
            rgba[idx] = int(clamp(r) * 255)
            rgba[idx + 1] = int(clamp(g) * 255)
            rgba[idx + 2] = int(clamp(b) * 255)
            rgba[idx + 3] = 255

    return rgba


def generate_sector_3(width: int, height: int) -> bytearray:
    """Sector 3 (Stages 11-15): Asteroid Perimeter (Deep Petrol Teal / Radioactive Jade)"""
    rgba = bytearray(width * height * 4)

    h1 = [math.cos(2 * math.pi * 1 * x / width + 1.5) for x in range(width)]
    h2 = [math.sin(2 * math.pi * 2 * x / width + 0.3) for x in range(width)]
    h3 = [math.cos(2 * math.pi * 3 * x / width + 2.8) for x in range(width)]
    h5 = [math.sin(2 * math.pi * 5 * x / width + 1.1) for x in range(width)]

    for y in range(height):
        yn = y / height
        y_ring = 1.0 - abs(yn - 0.58) * 1.9
        y_ring = clamp(y_ring, 0.0, 1.0)

        y_haze = 1.0 - abs(yn - 0.32) * 2.8
        y_haze = clamp(y_haze, 0.0, 1.0)

        row_offset = y * width * 4
        for x in range(width):
            # Abyssal teal void
            r = 0.015 + 0.01 * yn
            g = 0.05 + 0.02 * yn
            b = 0.06 + 0.03 * (1.0 - yn)

            # Emerald Jade Asteroid Dust Ring
            dust = 0.5 * h1[x] + 0.3 * h3[x] + 0.2 * h5[x]
            dust_val = clamp((dust + 0.8) * 0.5 * y_ring)

            r += dust_val * 0.10
            g += dust_val * 0.78
            b += dust_val * 0.55

            # Upper Turquoise Aurora
            haze = 0.6 * h2[x] + 0.4 * h5[x]
            haze_val = clamp((haze + 0.7) * 0.35 * y_haze)

            r += haze_val * 0.05
            g += haze_val * 0.45
            b += haze_val * 0.75

            idx = row_offset + x * 4
            rgba[idx] = int(clamp(r) * 255)
            rgba[idx + 1] = int(clamp(g) * 255)
            rgba[idx + 2] = int(clamp(b) * 255)
            rgba[idx + 3] = 255

    return rgba


def generate_sector_4(width: int, height: int) -> bytearray:
    """Sector 4 (Stages 16-20): Alien Void Citadel (Dark Matter Violet / Singularity Magenta)"""
    rgba = bytearray(width * height * 4)

    h1 = [math.sin(2 * math.pi * 1 * x / width + 2.4) for x in range(width)]
    h2 = [math.cos(2 * math.pi * 2 * x / width + 1.1) for x in range(width)]
    h4 = [math.sin(2 * math.pi * 4 * x / width + 3.0) for x in range(width)]
    h7 = [math.cos(2 * math.pi * 7 * x / width + 0.2) for x in range(width)]

    for y in range(height):
        yn = y / height
        y_singularity = 1.0 - abs(yn - 0.50) * 1.5
        y_singularity = clamp(y_singularity, 0.0, 1.0)

        y_rift = 1.0 - abs(yn - 0.78) * 3.8
        y_rift = clamp(y_rift, 0.0, 1.0)

        row_offset = y * width * 4
        for x in range(width):
            # Abyssal Obsidian Void
            r = 0.04 + 0.02 * yn
            g = 0.01 + 0.01 * yn
            b = 0.07 + 0.03 * yn

            # Quantum Void Singularity Core
            core = 0.45 * h1[x] + 0.35 * h2[x] + 0.2 * h4[x]
            core_val = clamp((core + 0.8) * 0.65 * y_singularity)

            r += core_val * 0.75
            g += core_val * 0.10
            b += core_val * 0.95

            # Neon Hyper-Magenta Dimensional Rift
            rift = 0.55 * h2[x] + 0.45 * h7[x]
            rift_val = clamp((rift + 0.85) * 0.45 * y_rift)

            r += rift_val * 0.95
            g += rift_val * 0.15
            b += rift_val * 0.55

            idx = row_offset + x * 4
            rgba[idx] = int(clamp(r) * 255)
            rgba[idx + 1] = int(clamp(g) * 255)
            rgba[idx + 2] = int(clamp(b) * 255)
            rgba[idx + 3] = 255

    return rgba


def main():
    print("=== SYNTHESIZING 4 SEAMLESS CAMPAIGN BACKGROUNDS ===")
    t_start = time.time()
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 1. Sector 1 (Stages 1-5)
    raw1 = generate_sector_1(WIDTH, HEIGHT)
    write_png(os.path.join(OUTPUT_DIR, "bg_sector_1.png"), WIDTH, HEIGHT, raw1)

    # 2. Sector 2 (Stages 6-10)
    raw2 = generate_sector_2(WIDTH, HEIGHT)
    write_png(os.path.join(OUTPUT_DIR, "bg_sector_2.png"), WIDTH, HEIGHT, raw2)

    # 3. Sector 3 (Stages 11-15)
    raw3 = generate_sector_3(WIDTH, HEIGHT)
    write_png(os.path.join(OUTPUT_DIR, "bg_sector_3.png"), WIDTH, HEIGHT, raw3)

    # 4. Sector 4 (Stages 16-20)
    raw4 = generate_sector_4(WIDTH, HEIGHT)
    write_png(os.path.join(OUTPUT_DIR, "bg_sector_4.png"), WIDTH, HEIGHT, raw4)

    print(f"=== ALL 4 BACKGROUNDS COMPLETED IN {time.time() - t_start:.2f}s ===")

if __name__ == "__main__":
    main()
