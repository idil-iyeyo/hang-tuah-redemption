# Generator for the 4 Dedicated Thruster Pixel Art Skins
# Matching the 4 Player Starship Themes & Thruster Dictionary
import struct, zlib, os

# Color Palette
C_NONE          = (0, 0, 0, 0)
C_BLACK_OUTL    = (0x22, 0x1a, 0x22, 255)  # 'k' Outline

# 1. CYAN / PLASMA (Standard / Wau Bulan)
C_CYAN_CORE     = (0xff, 0xff, 0xff, 255)  # 'W' Intense white-hot core
C_CYAN_HI       = (0x7e, 0xf6, 0xff, 255)  # 'C' Bright electric cyan
C_CYAN_MID      = (0x28, 0xb8, 0xe8, 255)  # 'c' Royal turquoise jet
C_CYAN_DARK     = (0x0f, 0x58, 0x7c, 255)  # 'z' Dark cyan flame edge

# 2. CRIMSON / SOLAR (Keris Panglima / Raja Bersanding)
C_CRIMSON_CORE  = (0xff, 0xf6, 0xbc, 255)  # 'S' Incandescent yellow flame core
C_CRIMSON_HI    = (0xff, 0x72, 0x36, 255)  # 'R' Fiery orange flare
C_CRIMSON_MID   = (0xd6, 0x18, 0x36, 255)  # 'r' Blood crimson exhaust
C_CRIMSON_DARK  = (0x6e, 0x07, 0x1c, 255)  # 'q' Deep velvet smoke edge

# 3. VOID / NEBULA PURPLE (Perahu Naga / Pendekar Bayang)
C_VOID_CORE     = (0xff, 0xee, 0xff, 255)  # 'P' White-violet singularity core
C_VOID_HI       = (0xd2, 0x88, 0xff, 255)  # 'V' Radiant nebula lilac
C_VOID_MID      = (0x8c, 0x32, 0xeb, 255)  # 'v' Warp indigo flame
C_VOID_DARK     = (0x46, 0x12, 0x84, 255)  # 'u' Deep cosmic void trail

# 4. GOLDEN / SOLAR FLARE (Mahkota Sultan / Golden Aegis)
C_GOLD_CORE     = (0xff, 0xff, 0xf0, 255)  # 'L' Solar white core
C_GOLD_HI       = (0xff, 0xee, 0x52, 255)  # 'Y' Radiant pure gold
C_GOLD_MID      = (0xe0, 0x9e, 0x1c, 255)  # 'y' Amber fire trail
C_GOLD_DARK     = (0x8c, 0x54, 0x0c, 255)  # 'j' Deep dragon ember

COLOR_MAP = {
    '.': C_NONE,
    'k': C_BLACK_OUTL,
    'W': C_CYAN_CORE,
    'C': C_CYAN_HI,
    'c': C_CYAN_MID,
    'z': C_CYAN_DARK,
    'S': C_CRIMSON_CORE,
    'R': C_CRIMSON_HI,
    'r': C_CRIMSON_MID,
    'q': C_CRIMSON_DARK,
    'P': C_VOID_CORE,
    'V': C_VOID_HI,
    'v': C_VOID_MID,
    'u': C_VOID_DARK,
    'L': C_GOLD_CORE,
    'Y': C_GOLD_HI,
    'y': C_GOLD_MID,
    'j': C_GOLD_DARK,
}

def write_png(filename, width, height, rgba_data):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        raw.extend(rgba_data[y*width*4 : (y+1)*width*4])
    compressed = zlib.compress(bytes(raw), 9)
    
    png = bytearray(b'\x89PNG\r\n\x1a\n')
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    png.extend(struct.pack('>I', len(ihdr)))
    png.extend(b'IHDR')
    png.extend(ihdr)
    png.extend(struct.pack('>I', zlib.crc32(b'IHDR' + ihdr)))
    
    png.extend(struct.pack('>I', len(compressed)))
    png.extend(b'IDAT')
    png.extend(compressed)
    png.extend(struct.pack('>I', zlib.crc32(b'IDAT' + compressed)))
    
    png.extend(struct.pack('>I', 0))
    png.extend(b'IEND')
    png.extend(struct.pack('>I', zlib.crc32(b'IEND')))
    
    with open(filename, 'wb') as f:
        f.write(png)

def parse_ascii(grid, w=32, h=32):
    rgba = bytearray()
    for y in range(h):
        row = grid[y] if y < len(grid) else ''
        for x in range(w):
            ch = row[x] if x < len(row) else '.'
            rgba.extend(COLOR_MAP.get(ch, C_NONE))
    return rgba

# 32x32 flame geometry: flows from nozzle base at x=25..27 leftwards to x=3..5
THRUSTER_CYAN = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "....................kkkk........",
    "..............kkkkkkzcczk.......",
    "........kkkkkkzccccCCWWck.......",
    "....kkkkzccccCCWWWWWWWWck.......",
    "....kkkkzccccCCWWWWWWWWck.......",
    "........kkkkkkzccccCCWWck.......",
    "..............kkkkkkzcczk.......",
    "....................kkkk........",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

THRUSTER_CRIMSON = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "....................kkkk........",
    "..............kkkkkkqrrqk.......",
    "........kkkkkkqrrrrRRSSrk.......",
    "....kkkkqrrrrRRSSSSSSSSrk.......",
    "....kkkkqrrrrRRSSSSSSSSrk.......",
    "........kkkkkkqrrrrRRSSrk.......",
    "..............kkkkkkqrrqk.......",
    "....................kkkk........",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

THRUSTER_VOID = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "....................kkkk........",
    "..............kkkkkkuvvuk.......",
    "........kkkkkkuvvvvVVPPvk.......",
    "....kkkkuvvvvVVPPPPPPPPvk.......",
    "....kkkkuvvvvVVPPPPPPPPvk.......",
    "........kkkkkkuvvvvVVPPvk.......",
    "..............kkkkkkuvvuk.......",
    "....................kkkk........",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

THRUSTER_GOLD = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "....................kkkk........",
    "..............kkkkkkjyyjk.......",
    "........kkkkkkjyyyyYYLLyk.......",
    "....kkkkjyyyyYYLLLLLLLLyk.......",
    "....kkkkjyyyyYYLLLLLLLLyk.......",
    "........kkkkkkjyyyyYYLLyk.......",
    "..............kkkkkkjyyjk.......",
    "....................kkkk........",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

def main():
    out_dir = "/Users/idil/GodotProjectFile/new-game-auto/assets/textures/thrusters"
    os.makedirs(out_dir, exist_ok=True)
    
    files = [
        ("thruster_cyan.png", THRUSTER_CYAN),
        ("thruster_crimson.png", THRUSTER_CRIMSON),
        ("thruster_void.png", THRUSTER_VOID),
        ("thruster_gold.png", THRUSTER_GOLD),
        ("thruster_default.png", THRUSTER_CYAN), # Standard slot alias
    ]
    
    for filename, grid in files:
        path = os.path.join(out_dir, filename)
        rgba = parse_ascii(grid, 32, 32)
        write_png(path, 32, 32, rgba)
        print(f"Generated thruster texture: {path}")

if __name__ == "__main__":
    main()
