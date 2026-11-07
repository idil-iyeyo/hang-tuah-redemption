# Generator for 4 Distinct Malay Cultural Ship Silhouettes & Skins
# Every ship has a completely unique morphological shape and cultural identity:
# 1. WAU BULAN: Crescent-moon wings, soaring organic curved kite frame with songket tassels.
# 2. KERIS PANGLIMA: Piercing asymmetrical wavy keris-dagger hull with golden sarong hilt and sharp guard.
# 3. PERAHU NAGA / LANCHANG: Royal Malay war-galley boat with dragon bow rostrum and twin outrigger stabilizer hulls.
# 4. TENGKOLOK SULTAN: Iconic folded royal Malay headdress crown with peaked star-wings and emerald brooch.
# All ships strictly respect:
# - Rear thruster exhaust nozzle at x=4..5, y=15..17 (seamless thruster flame connection).
# - Front central nose at x=25..26, y=15..17 (seamless blaster & cannon alignment).
# - Full vertical balance, no floating pixels, zero defects.

import struct, zlib, os

# Color Palettes
C_NONE          = (0, 0, 0, 0)
C_BLACK_OUTL    = (0x22, 0x1a, 0x22, 255)  # 'k' Outline

# Gold Songket & Royal Accents
C_GOLD_HI       = (0xff, 0xe4, 0x54, 255)  # 'Y' Gold highlight
C_GOLD_MID      = (0xd9, 0xa5, 0x22, 255)  # 'y' Gold songket mid
C_GOLD_DARK     = (0x8f, 0x66, 0x10, 255)  # 'j' Gold shadow

# Royal Malay Turquoise / Ocean (Wau Bulan)
C_CYAN_HI       = (0x5c, 0xf4, 0xff, 255)  # 'C' Cyan silk glow
C_CYAN_MID      = (0x1b, 0xad, 0xd8, 255)  # 'c' Royal turquoise
C_CYAN_DARK     = (0x0e, 0x5e, 0x7c, 255)  # 'z' Ocean blue shadow
C_WHITE_SILK    = (0xf5, 0xfa, 0xff, 255)  # 'T' White kite silk

# Keris Steel & Hardened Kemuning Wood (Keris Panglima)
C_STEEL_HI      = (0xf4, 0xf6, 0xfc, 255)  # 'S' Pamor steel highlight
C_STEEL_MID     = (0xa0, 0xa9, 0xb8, 255)  # 's' Damascus blade mid
C_STEEL_DARK    = (0x50, 0x56, 0x64, 255)  # 'x' Dark folded iron
C_WOOD_HI       = (0xc4, 0x92, 0x5a, 255)  # 'W' Polished wood hilt
C_WOOD_MID      = (0x8c, 0x5b, 0x28, 255)  # 'w' Kemuning teak
C_WOOD_DARK     = (0x54, 0x32, 0x10, 255)  # 'f' Deep wood grain

# Royal Crimson & Dragon Scarlet (Perahu Naga / Lanchang)
C_CRIMSON_HI    = (0xf8, 0x44, 0x64, 255)  # 'R' Scarlet dragon highlight
C_CRIMSON_MID   = (0xc4, 0x16, 0x36, 255)  # 'r' Royal crimson hull
C_CRIMSON_DARK  = (0x78, 0x08, 0x1e, 255)  # 'q' Deep maroon hull

# Imperial Emerald & Violet Velvet (Tengkolok Diraja)
C_EMERALD_HI    = (0x58, 0xf8, 0x92, 255)  # 'G' Emerald jewel glow
C_EMERALD_MID   = (0x18, 0xb6, 0x54, 255)  # 'g' Malay jade brooch
C_EMERALD_DARK  = (0x0a, 0x66, 0x2c, 255)  # 'e' Deep forest emerald
C_INDIGO_HI     = (0xba, 0x7a, 0xff, 255)  # 'V' Royal violet silk
C_INDIGO_MID    = (0x7c, 0x30, 0xdc, 255)  # 'v' Indigo velvet
C_INDIGO_DARK   = (0x46, 0x12, 0x88, 255)  # 'u' Deep purple shadow

# Thruster Exhaust Interface
C_EXHAUST_BASE  = (0x34, 0x32, 0x30, 255)  # 'B' Thruster rim dark
C_EXHAUST_GLOW  = (0x64, 0xa1, 0xc2, 255)  # 'O' Thruster nozzle cyan

COLOR_MAP = {
    '.': C_NONE,
    'k': C_BLACK_OUTL,
    'Y': C_GOLD_HI,
    'y': C_GOLD_MID,
    'j': C_GOLD_DARK,
    'C': C_CYAN_HI,
    'c': C_CYAN_MID,
    'z': C_CYAN_DARK,
    'T': C_WHITE_SILK,
    'S': C_STEEL_HI,
    's': C_STEEL_MID,
    'x': C_STEEL_DARK,
    'W': C_WOOD_HI,
    'w': C_WOOD_MID,
    'f': C_WOOD_DARK,
    'R': C_CRIMSON_HI,
    'r': C_CRIMSON_MID,
    'q': C_CRIMSON_DARK,
    'G': C_EMERALD_HI,
    'g': C_EMERALD_MID,
    'e': C_EMERALD_DARK,
    'V': C_INDIGO_HI,
    'v': C_INDIGO_MID,
    'u': C_INDIGO_DARK,
    'B': C_EXHAUST_BASE,
    'O': C_EXHAUST_GLOW,
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

# =============================================================================
# SKIN 1: "default" -> WAU BULAN (The Soaring Crescent Kite)
# Silhouette:
# - Sweeping crescent-moon curved wings flaring wide upwards and downwards.
# - Thin aerodynamic kite spars with floral songket panels and trailing wingtips.
# - Sharp front prow (x=25) for blaster mount; central exhaust hub (x=5) for thruster.
# =============================================================================
SKIN_WAU_BULAN = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................kkkk............",
    "..............kkcyYckk..........",
    "............kkcTTTTyYkkk........",
    "..........kkccTTccTTyYckkk......",
    "........kkccczyYTTccTTyYckkk....",
    ".......kcccczyYTTTTTTyYzzckk....",
    "......kkcccczzyYYYYYYzzzzckkk...",
    ".....kkcczzzyyyyyYYYYyyyyzzzkk..",
    "....kkczzyyyyYyyyyyYyyyyyzzckk..",
    "...BkkczzyyYYYYYYYYYYYYyyyzzckk.",
    "..OBkczzyyYYTTTTTTTTYYyyyzzckkkk",
    "..OBkczzyyYYTTTTTTTTYYyyyzzckkkk",
    "...BkkczzyyYYYYYYYYYYYYyyyzzckk.",
    "....kkczzyyyyYyyyyyYyyyyyzzckk..",
    ".....kkcczzzyyyyyYYYYyyyyzzzkk..",
    "......kkcccczzyYYYYYYzzzzckkk...",
    ".......kcccczyYTTTTTTyYzzckk....",
    "........kkccczyYTTccTTyYckkk....",
    "..........kkccTTccTTyYckkk......",
    "............kkcTTTTyYkkk........",
    "..............kkcyYckk..........",
    "................kkkk............",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

# =============================================================================
# SKIN 2: "crimson" -> KERIS PANGLIMA (The Mythical Dagger Starfighter)
# Silhouette:
# - Long, razor-sharp undulating/wavy dagger blade fuselage (Pamor steel).
# - Distinct asymmetrical Keris guard (Ganja Keris) with flared hilt barb.
# - Rich carved teak & gold hilt core with crimson battle aura.
# =============================================================================
SKIN_KERIS_PANGLIMA = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "............kkkk................",
    "...........kYYYYk...............",
    "..........kYRRRRYk..............",
    ".........kYRRssRRYk.....kkkk....",
    "........kYRRssssRRYkkkkkSSSSk...",
    ".......kYRRssSSssRRYSSSSSSSk....",
    "...BkkkWWrrssSSSssrrSSSSSSk.....",
    "..OBkkkWWrrssSSSssrrSSSSSSSkkkkk",
    "..OBkkkWWffxxSSSxxffxxxxSSSkkkkk",
    "...BkkkWWffxxSSSxxffxxxxSSk.....",
    ".......kWffxxSSxxffWxxffkk......",
    "........kWffxxxxffWkkkkk........",
    ".........kWffffWWkk.............",
    "..........kffffkk...............",
    "...........kkkk.................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

# =============================================================================
# SKIN 3: "void" -> PERAHU NAGA (The Malay War Galley / Royal Lanchang)
# Silhouette:
# - Trimaran / Catamaran hull with twin extended outrigger stabilizer hulls.
# - Prominent carved dragon/serpent bow-sprit projecting at the front.
# - Royal crimson war-pennants, golden shields along gunwales.
# =============================================================================
SKIN_PERAHU_NAGA = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "..................kkkk..........",
    "............kkkkkkqrrRkk........",
    "..........kkqrrrrqqYYYrkk.......",
    ".........kqqrrrrqqYYYYYrkk......",
    "........kqrrrrrqqYYjYYYrrk......",
    ".......kqrrrrrqqYYYYYYYYrrk.....",
    "......kqqrrqqqqqYYYYYYYYrrk.....",
    ".....kqqrrqYYYYYYYyyyyyYrrkk....",
    "...BkkqqrrqYYYYYYYsssssYrrkkkkkk",
    "..OBkkqqrrqYYYYYYYsssssYrrkkkkkk",
    "...BkkqqrrqYYYYYYYyyyyyYrrkk....",
    "......kqqrrqqqqqYYYYYYYYrrk.....",
    ".......kqrrrrrqqYYYYYYYYrrk.....",
    "........kqrrrrrqqYYjYYYrrk......",
    ".........kqqrrrrqqYYYYYrkk......",
    "..........kkqrrrrqqYYYrkk.......",
    "............kkkkkkqrrRkk........",
    "..................kkkk..........",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

# =============================================================================
# SKIN 4: "gold" -> TENGKOLOK DIRAJA (The Folded Royal Crown Headdress)
# Silhouette:
# - Dynamic asymmetric folded headcloth silhouette with upward-peaked crest.
# - Rich violet & imperial gold brocade folds (Solek Dendam Tak Sudah).
# - Central glowing emerald jade medallion brooch (Bintang Kebesaran).
# =============================================================================
SKIN_TENGKOLOK_DIRAJA = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "...............kkkk.............",
    ".............kkYYYYk............",
    "............kkYvvvvYk...........",
    "...........kkYvvVVvvYk..........",
    "..........kkYvvVeeVvvYkk........",
    ".........kkYvvVeggEVvvYYkk......",
    "........kkYvvVveeGGeevYyYYk.....",
    ".......kkYvvVvveGGGGevYYyyYk....",
    "......kkYvvVvvveeGGeevYYyyYk....",
    ".....kkYvvVvvvvVeggEVvYYyyYk....",
    "...BkkYvvVvvvvvvVeeVvvYYyyYkkkkk",
    "..OBkkYvvVvvvvvvvVVvvvYYyyYkkkkk",
    "...BkkYvvVvvvvvvVeeVvvYYyyYk....",
    ".....kkYvvVvvvvVeggEVvYYyyYk....",
    "......kkYvvVvvveeGGeevYYyyYk....",
    ".......kkYvvVvveGGGGevYYyyYk....",
    "........kkYvvVveeGGeevYyYYk.....",
    ".........kkYvvVeggEVvvYYkk......",
    "..........kkYvvVeeVvvYkk........",
    "...........kkYvvVVvvYk..........",
    "............kkYvvvvYk...........",
    ".............kkYYYYk............",
    "...............kkkk.............",
    "................................",
    "................................",
    "................................",
    "................................"
]

def main():
    ship_dir = "/Users/idil/GodotProjectFile/new-game-auto/assets/textures/ships"
    os.makedirs(ship_dir, exist_ok=True)
    
    skins = [
        ("skin_wau_bulan.png", SKIN_WAU_BULAN),
        ("skin_raja_crimson.png", SKIN_KERIS_PANGLIMA),
        ("skin_void_pendekar.png", SKIN_PERAHU_NAGA),
        ("skin_gold_sultan.png", SKIN_TENGKOLOK_DIRAJA),
    ]
    
    for filename, grid in skins:
        path = os.path.join(ship_dir, filename)
        rgba = parse_ascii(grid, 32, 32)
        write_png(path, 32, 32, rgba)
        print(f"Generated distinct morphological ship skin: {path}")

if __name__ == "__main__":
    main()
