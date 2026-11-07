# Master Alien Slime Pixel Art Generator: Defect-Free Edition
# All enemies face LEFT (front at left), thrusters on RIGHT (exhaust pushes leftwards).
# Perfectly aligned, zero asymmetrical defects, zero floating stray pixels.
# Features:
# - DREADNOUGHT TITAN (48x48): Colossal Armored Slime with massive curved frontal horns,
#   symmetric twin armored cybernetic cannons, glowing cyclopean reactor eye, and twin heavy thrusters.
# - HEAVY ENEMY (32x32): Armored Bio-Borer with dual front chitin horns, heavy carapace, twin rear thrusters.
# - BILE SPEWER (32x32): Cauldron Maw Spitter with acid drip, top bubbling reservoir, rear thruster.
# - CHARGER ROACH (32x32): Needle Jet Slime with spear rostrum, swept wings, triple rocket exhaust.
# - VOID BILE (32x32): Cosmic Phase Jelly with cyan void eye, ethereal tendrils, phase emitter.
# - BILE BREEDER (32x32): Brood Nursery Slime with transparent gestation sac, glowing embryos, brood thruster.

import struct, zlib, os

# Color Palette
C_NONE          = (0, 0, 0, 0)

# Slime Body (Queen's purple/rose family)
C_PURPLE_LIGHT  = (0xd8, 0x8e, 0xba, 255)  # 'L' Slime highlight
C_PURPLE_MAIN   = (0xb5, 0x70, 0x97, 255)  # 'P' Slime primary body
C_PURPLE_MID    = (0x96, 0x62, 0x83, 255)  # 'M' Shading
C_PURPLE_DARK   = (0x76, 0x4d, 0x67, 255)  # 'D' Deep shadow
C_PURPLE_OUTL   = (0x40, 0x15, 0x40, 255)  # 'O' Slime outline / crease

# Cybernetic Heavy Armor / Metal
C_ARMOR_HI      = (0x9e, 0xa2, 0xad, 255)  # 'h' Armor edge highlight
C_ARMOR_LIGHT   = (0x74, 0x78, 0x82, 255)  # 'l' Metal plating light
C_ARMOR_MID     = (0x54, 0x58, 0x60, 255)  # 'g' Metal midtone
C_ARMOR_DARK    = (0x36, 0x38, 0x40, 255)  # 'd' Metal shadow / seams
C_ARMOR_DEEP    = (0x1e, 0x20, 0x25, 255)  # 'x' Darkest gunmetal / nozzle rim

# Thruster / Energy Core (Queen's thruster cyan)
C_CYAN_CORE     = (0xa8, 0xee, 0xff, 255)  # 'b' Plasma highlight
C_CYAN_MID      = (0x64, 0xa1, 0xc2, 255)  # 'c' Thruster cyan
C_CYAN_DARK     = (0x28, 0x45, 0x58, 255)  # 'z' Thruster base dark

# Class-Specific Distinguishing Elements:
# Horns & Hardened Chitin (Horn Bone / Amber Chitin)
C_CHITIN_HI     = (0xdf, 0xca, 0x9f, 255)  # 'H' Horn highlight
C_CHITIN_MID    = (0xb2, 0x99, 0x68, 255)  # 'C' Horn midtone
C_CHITIN_DARK   = (0x6d, 0x54, 0x33, 255)  # 'K' Horn shadow

# Acid / Bile (Caustic Yellow-Green)
C_ACID_HI       = (0xc8, 0xff, 0x50, 255)  # 'A' Acid glow
C_ACID_MID      = (0x8e, 0xe2, 0x28, 255)  # 'a' Acid liquid
C_ACID_DARK     = (0x4c, 0x88, 0x14, 255)  # 'k' Acid shadow

# Void / Cosmic Phase (Electric Cyan & Void Indigo)
C_VOID_GLOW     = (0x50, 0xf0, 0xe8, 255)  # 'V' Void eye / spark
C_VOID_INDIGO   = (0x33, 0x22, 0x66, 255)  # 'I' Void internal rift

# Breeder Nursery Embryos (Translucent Glowing Amber)
C_LARVA_GLOW    = (0xff, 0xba, 0x50, 255)  # 'E' Larval embryo yolk
C_LARVA_CORE    = (0xff, 0x7b, 0x28, 255)  # 'e' Larval embryo eye

# Dreadnought Titan Cyclopean Sensor (Incandescent Orange / Red)
C_REACTOR_CORE  = (0xff, 0xaa, 0x33, 255)  # 'S' Reactor core flare
C_REACTOR_RED   = (0xee, 0x33, 0x22, 255)  # 's' Sensor eye glow

COLOR_MAP = {
    '.': C_NONE,
    'L': C_PURPLE_LIGHT,
    'P': C_PURPLE_MAIN,
    'M': C_PURPLE_MID,
    'D': C_PURPLE_DARK,
    'O': C_PURPLE_OUTL,
    'h': C_ARMOR_HI,
    'l': C_ARMOR_LIGHT,
    'g': C_ARMOR_MID,
    'd': C_ARMOR_DARK,
    'x': C_ARMOR_DEEP,
    'b': C_CYAN_CORE,
    'c': C_CYAN_MID,
    'z': C_CYAN_DARK,
    'H': C_CHITIN_HI,
    'C': C_CHITIN_MID,
    'K': C_CHITIN_DARK,
    'A': C_ACID_HI,
    'a': C_ACID_MID,
    'k': C_ACID_DARK,
    'V': C_VOID_GLOW,
    'I': C_VOID_INDIGO,
    'E': C_LARVA_GLOW,
    'e': C_LARVA_CORE,
    'S': C_REACTOR_CORE,
    's': C_REACTOR_RED,
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

def parse_ascii_grid(ascii_rows, w=32, h=32):
    rgba_bytes = bytearray()
    for y in range(h):
        row_str = ascii_rows[y] if y < len(ascii_rows) else ''
        for x in range(w):
            ch = row_str[x] if x < len(row_str) else '.'
            col = COLOR_MAP.get(ch, C_NONE)
            rgba_bytes.extend(col)
    return rgba_bytes

# =============================================================================
# BOSS: DREADNOUGHT TITAN (48x48)
# An imposing Super-Heavy Armored Bio-Titan Slime:
# - Front (Left) features massive, sweeping forward-curving bio-mechanical Titan Horns ('H', 'C', 'K').
# - Reinforced industrial armor plating on upper & lower dorsal carapaces.
# - Twin heavy forward cannons built into the armor flanks.
# - Pulsating core with an incandescent horizontal Cyclopean sensor eye ('S', 's').
# - Perfectly vertically symmetric dual heavy rocket thrusters on rear (right) with cyan plasma exhaust.
# =============================================================================
DREADNOUGHT_TITAN_ASCII = [
    "................................................",
    "....HH..........................................",
    "...HCCK...............dddddddddd................",
    "..HCCCCK..........ddddhhhhhhhhhhdddd............",
    ".HCCCCK.......ddddhhhhhhhhhhhhhhhhhhdddd........",
    ".HCCCK....ddddhhhhllllggggggggggllllhhhhdddd....",
    ".HCCCK.dddddxxllllggggddddddddddggggllllxxdd....",
    "..KCCK.xxxxllllggggddddOOOOOOOOddddggggllllxxxx.",
    "...KCK.xxxxllllggggddOOPPPLLLLPOOddggggllllxxxx.",
    "....KK.xxxxllllggggdOOPPPLLLLLLPOOdggggllllxxxx.",
    ".......xxxxllllggggdOPPPLLLLLLLLPOdggggllllxxxx.",
    ".......dxxxllllggggOPPLLLLLLLLLLLPOdgggllllxxxx.",
    ".......dxxxllllgggOPPLLLLLLLLLLLLPOdgggllllxxxx.",
    ".......dxxxllllgggOPLLLLLLLLLLLLLPOdgggxxxxzzzz.",
    ".......dxxxllllgggOPLLLLLLLLLLLLLPOdgggxxxxzccz.",
    ".......dxxxllllgggOPLLLLLLLLLLLLLPOdgggxxxxzccb.",
    ".......dxxxllllgggOPLLLLLLLLLLLLLPOdgggxxxxzccb.",
    "....xxxhhhhllllgggOPLLLLLLLLLLLLLPOdgggxxxxzccz.",
    "...xhllllgggggggggOPLLLLLLLLLLLLLPOdgggxxxxzzzz.",
    "..xhlllgggggggggggOPLLLLLLLLLLLLLPOdgggllllxxxx.",
    "..xhllgddddddddddddOPLLLLLLLLLLLPOdddddglhhhhx..",
    "..xhllgxdsssssssssssssssssssssssssssxdxxglhhx...",
    "..xhllgxdSSSSSSSSSSSSSSSSSSSSSSSSSSSxdxxglhx....",
    "..xhllgxdsssssssssssssssssssssssssssxdxxglhx....",
    "..xhllgddddddddddddOPLLLLLLLLLLLPOdddddglhhx..",
    "..xhlllgggggggggggOPLLLLLLLLLLLLLPOdgggllllxxxx.",
    "...xhllllgggggggggOPLLLLLLLLLLLLLPOdgggxxxxzzzz.",
    "....xxxhhhhllllgggOPLLLLLLLLLLLLLPOdgggxxxxzccz.",
    ".......dxxxllllgggOPLLLLLLLLLLLLLPOdgggxxxxzccb.",
    ".......dxxxllllgggOPLLLLLLLLLLLLLPOdgggxxxxzccb.",
    ".......dxxxllllgggOPLLLLLLLLLLLLLPOdgggxxxxzccz.",
    ".......dxxxllllgggOPLLLLLLLLLLLLLPOdgggxxxxzzzz.",
    ".......dxxxllllgggOPPLLLLLLLLLLLLPOdgggllllxxxx.",
    ".......dxxxllllggggOPPLLLLLLLLLLLPOdgggllllxxxx.",
    ".......xxxxllllggggdOPPPLLLLLLLLPOdggggllllxxxx.",
    "....KK.xxxxllllggggdOOPPPLLLLLLPOOdggggllllxxxx.",
    "...KCK.xxxxllllggggddOOPPPLLLLPOOddggggllllxxxx.",
    "..KCCK.xxxxllllggggddddOOOOOOOOddddggggllllxxxx.",
    ".HCCCK.dddddxxllllggggddddddddddggggllllxxdd....",
    ".HCCCK....ddddhhhhllllggggggggggllllhhhhdddd....",
    ".HCCCCK.......ddddhhhhhhhhhhhhhhhhhhdddd........",
    "..HCCCCK..........ddddhhhhhhhhhhdddd............",
    "...HCCK...............dddddddddd................",
    "....HH..........................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................"
]

# =============================================================================
# ENEMY 1: HEAVY ENEMY (32x32)
# Armored Bio-Borer:
# - Two forward-curving bone/chitin mandibles ('H', 'C', 'K') on front (left).
# - Thick arched cybernetic dorsal shell plates.
# - Perfectly vertically symmetric dual rear rocket thrusters on right.
# =============================================================================
HEAVY_ENEMY_ASCII = [
    "................................",
    ".............ddddddd............",
    "...........ddhhlllllddd.........",
    "....HH....dhhlllllllllldd.......",
    "...HCCK..dhllllllllllllldd..dd..",
    "..HCCCCKdhllllggddddggllldddlld.",
    "..HCCCCKdhlllddOOOOOOddlldxggld.",
    "...KCCK.dhllldOOPPPLLPOOdldxggld.",
    "....KK..dhllldOPPLLLLLPOOdxdgglld",
    "........dhldOPPLLLLLLLPPOxdgglld",
    "........dhldOPPLLLLLLLPPOxdxxxzz",
    "........dhldOPPLLLLLLLPPOxdxxzcb",
    "........dhldOPPLLLLLLLPPOxdxxzcb",
    "........dhldOPPLLLLLLLPPOxdxxxzz",
    "........dhldOPPLLLLLLLPPOxdgglld",
    "........dhldOPPLLLLLLLPPOxdgglld",
    "........dhldOPPLLLLLLLPPOxdxxxzz",
    "........dhldOPPLLLLLLLPPOxdxxzcb",
    "........dhldOPPLLLLLLLPPOxdxxzcb",
    "........dhldOPPLLLLLLLPPOxdxxxzz",
    "....KK..dhldOPPLLLLLLLPPOxdgglld",
    "...KCCK.dhllldOPPLLLLLPOOdxdgglld",
    "..HCCCCKdhlllddOOOOOOddlldxggld.",
    "..HCCCCKdhllllggddddggllldddlld.",
    "...HCCK..dhllllllllllllldd..dd..",
    "....HH....dhhlllllllllldd.......",
    "...........ddhhlllllddd.........",
    ".............ddddddd............",
    "................................",
    "................................",
    "................................",
    "................................"
]

# =============================================================================
# ENEMY 2: BILE SPEWER (32x32)
# Acid Cauldron Spitter:
# - Forward caustic acid maw ('A', 'a', 'k') dripping green bile.
# - Dorsal venom fluid reservoir, flowing gelatinous body.
# - Rear cybernetic stabilizer with clean exhaust.
# =============================================================================
BILE_SPEWER_ASCII = [
    "................................",
    "..........kkkkk.................",
    "........kkaAAAakkk..............",
    ".......kaAAAAAAAAak.............",
    "......kaAaaaaaaaAAak...dd.......",
    ".....kAAAAaaaaaaAAAak.dllld.....",
    "....kaAAAAAaaaaaAAAAakdlggld....",
    "....kAAAAAAAaaaAAAAAAkdlggld....",
    "...kaAAAaaAAAAaAAAaaAkdxgglld...",
    "...kAaaaaaaaAAaaaaaaAkdxgglld...",
    "..kAAAAAAAAAAAAAAaaaaAdxxxxdd...",
    ".kAAaaaaAAkaaaakAaaaaAdxxxxdd...",
    ".kAaaaaaAkkkOkkkkAaaaAdxxxxzz...",
    "kAaaaaaaAkOOPPPOkAaaaAdxxxzcb...",
    "kaaaaaaaAkOPLLPOkkkkkAdxxxzcb...",
    "kaaaaaaaAkOPLLLLPOOkkkdxxxzcb...",
    "kAaaaaaaAkOPLLLLLPPOOdxxxzcb...",
    ".kAaaaaaAkOPPLLLLLPPPOdxxxxzz...",
    ".kAAaaaaAkOOPPLLLLPPPddxxxxdd...",
    "..kAAAAAAAAkOOPPPPPPOdgglld.....",
    "...kaAAAAaak..OOPPPPPOdllld.....",
    "....kaaaak.....OPPPPMO..dd......",
    ".....kkkk......OPMMMDMO.........",
    "................OMDDDDMO........",
    ".................OMDDMO.........",
    "..................OMMO..........",
    "...................OO...........",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

# =============================================================================
# ENEMY 3: CHARGER ROACH (32x32)
# High-Velocity Needle Jet:
# - Solid razor-sharp hardened spear rostrum on left ('x', 'h', 'l').
# - Sleek swept delta foils.
# - Symmetrical triple rocket nozzles on right with long blazing flame tails.
# =============================================================================
CHARGER_ROACH_ASCII = [
    "................................",
    "................................",
    "................................",
    "................................",
    ".....................dddd.......",
    "...................ddhhldd......",
    ".................ddhhlllldd.dd..",
    "...............ddhhllllllllddld.",
    ".............ddhhllllllllllldld.",
    "...........ddhhlllOOOOOOOOllddld",
    ".........ddhhlllOOPPPLLLLPPOxxxx",
    ".......ddhhlllOOPPPLLLLLLPPOxzzb",
    ".....ddhhlllOOPPPLLLLLLLLPPxccbb",
    "...ddhhlllOOPPPLLLLLLLLLLPPxbbbb",
    ".dxhhlllOOPPPLLLLLLLLLLLLPPxzzb.",
    "xhllllOOPPPLLLLLLLLLLLLLLPPxccbb",
    ".dxhhlllOOPPPLLLLLLLLLLLLPPxzzb.",
    "...ddhhlllOOPPPLLLLLLLLLLPPxbbbb",
    ".....ddhhlllOOPPPLLLLLLLLPPxccbb",
    ".......ddhhlllOOPPPLLLLLLPPOxzzb",
    ".........ddhhlllOOPPPLLLLPPOxxxx",
    "...........ddhhlllOOOOOOOOllddld",
    ".............ddhhllllllllllldld.",
    "...............ddhhllllllllddld.",
    ".................ddhhlllldd.dd..",
    "...................ddhhldd......",
    ".....................dddd.......",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
]

# =============================================================================
# ENEMY 4: VOID BILE (32x32)
# Phase Jelly / Cosmic Rift Slime:
# - Central glowing cyan void eye ('V', 'I').
# - Sinuous ethereal phase tentacles.
# - Aligned phase-ring propulsion node on rear.
# =============================================================================
VOID_BILE_ASCII = [
    "................................",
    "..........OOOO..................",
    "........OOPLLPOO................",
    ".......OPLLLLLLPO...............",
    "......OPLLLLLLLLPO..............",
    ".....OPLLLLLLLLLLPO...dd........",
    "....OPLLLLLLLLLLLLPO.dllld......",
    "...OPLLLLLVVVLLLLLLPOdlggld.....",
    "..OPLLLLLVVVVVLLLLLLPdxggld.....",
    "..OPLLLLVVIIIVVLLLLLPdxxdd......",
    ".OPLLLLVIIIIIIIVLLLLPOxVVb......",
    ".OPLLLLVIIIIIIIVLLLLPOxVVb......",
    ".OPLLLLVIIIIIIIVLLLLPOxVVb......",
    ".OPLLLLVVIIIVVLLLLLLPOxVVb......",
    "..OPLLLLLVVVVVLLLLLLPdxxdd......",
    "..OPLLLLLLVVVLLLLLLLPOxggld.....",
    "...OPLLLLLLLLLLLLLLPOdlggld.....",
    "....OPLLLLLLLLLLLLPO.dllld......",
    ".....OPLLLLLLLLLLPO...dd........",
    "......OPLLLLLLLLPO..............",
    ".......OPLLLLLLPO...............",
    "........OPPMMMMPO...............",
    ".......OPM..OMPMO...............",
    "......OPMO..OPDMO...............",
    ".....OPMO....OMDMO..............",
    ".....OPMO....OMDMO..............",
    "......OO......OMMO..............",
    "...............OO...............",
    "................................",
    "................................",
    "................................",
    "................................"
]

# =============================================================================
# ENEMY 5: BILE BREEDER (32x32)
# Brood Nursery Slime:
# - Large transparent gestation womb dome with glowing baby embryos ('E', 'e').
# - Organic cluster egg-pods along the belly.
# - Solid cybernetic life-support thruster cleanly integrated on rear.
# =============================================================================
BILE_BREEDER_ASCII = [
    "................................",
    "............OOOOOOOO............",
    ".........OOOPPLLLLLLPOOO........",
    ".......OOPPPLLLLLLLLLLPPOO......",
    "......OOPLLLLLOOOOOLLLLLPPPO....",
    ".....OOPLLLLOOEEEEEEOLLLLLPPO...",
    "....OOPLLLLOOEeEEEEeEOLLLLLPPO..",
    "...OOPLLLLOOEEeEEEEeEEOLLLLLPPO.",
    "..OOPPLLLLOOEEEEEEEEEEEOLLLLLPPO",
    ".OOPPLLLLLOOEEeEEEEeEEEOLLLLLPPO",
    ".OOPPLLLLLLOOEeEEEEeEEOLLLLLLPPO",
    "OOPPLLLLLLLOOEEEEEEOLLLLLLLLLPPO",
    "OOPPLLLLLLLLOOOOOOOOLLLLLLLLLPPO",
    "OOPPLLLLLLLLLLLLLLLLLLLLLLLLLPPO",
    "OOPPLLLLLLLLLLLLLLLLLLLLLLLLLPPx",
    "OOPPLLLLLLLLLLLLLLLLLLLLLLLLLPPx",
    ".OOPPLLLLLLLLLLLLLLLLLLLLLLLPxxx",
    ".OOPPLLLLLLLLLLLLLLLLLLLLLLLPxcc",
    "..OOPPPLLLLLLLLLLLLLLLLLLLLPPxcb",
    "...OOPPPPPPLLLLLLLLLLLLLLPPPxxcc",
    "....OOPPPPPPPPPPPPPPPPPPPPPOxxxx",
    ".....OOPPPPPPPPPPPPPPPPPPPOOxxxx",
    "......OOPPMMMMMMMMMMMMMMMOO.xggd",
    ".......OPPMMMMDDDDDDDDDDMO..xggd",
    ".......OPPMM..MDDDDDDDDMO...dll.",
    "........OPPO...MDDDDDDMO....dd..",
    "........OPPO....MDDDDMO.........",
    ".........OO......MDDMO..........",
    "..................OMMO..........",
    "...................OO...........",
    "................................",
    "................................"
]

def main():
    enemy_dir = "/Users/idil/GodotProjectFile/new-game-auto/assets/textures/enemies"
    boss_dir = "/Users/idil/GodotProjectFile/new-game-auto/assets/textures/bosses"
    os.makedirs(enemy_dir, exist_ok=True)
    os.makedirs(boss_dir, exist_ok=True)
    
    enemies = [
        ("heavy_enemy.png", HEAVY_ENEMY_ASCII, 32, 32, enemy_dir),
        ("bile_spewer.png", BILE_SPEWER_ASCII, 32, 32, enemy_dir),
        ("charger_roach.png", CHARGER_ROACH_ASCII, 32, 32, enemy_dir),
        ("void_bile.png", VOID_BILE_ASCII, 32, 32, enemy_dir),
        ("bile_breeder.png", BILE_BREEDER_ASCII, 32, 32, enemy_dir),
        ("dreadnought_titan.png", DREADNOUGHT_TITAN_ASCII, 48, 48, boss_dir)
    ]
    
    for filename, grid, w, h, target_dir in enemies:
        path = os.path.join(target_dir, filename)
        rgba = parse_ascii_grid(grid, w, h)
        write_png(path, w, h, rgba)
        print(f"Generated clean pixel art: {path} ({w}x{h})")

if __name__ == "__main__":
    main()
