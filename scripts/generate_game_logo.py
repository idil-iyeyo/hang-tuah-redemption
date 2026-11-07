# Game Logo Generator: Vector SVG + Rendered PNGs + Energy Shield
# Generates:
# - icon.svg (512x512 scalable vector logo with Malay Sci-Fi Starfighter, Crossed Plasma Keris, Reticle, and Hexagonal Shield Crest)
# - assets/textures/game_logo.png (512x512 master high-res logo)
# - assets/textures/game_logo_192.png (192x192 launcher icon)
# - assets/textures/game_logo_432.png (432x432 adaptive foreground icon)
# - assets/textures/energy_shield.png (128x128 forcefield barrier for player shield)

import struct, zlib, math, os

def write_png(filename, width, height, rgba_data):
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # Filter None
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

# =============================================================================
# 1. VECTOR SVG GENERATION
# =============================================================================
def generate_vector_svg():
    return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <!-- Background Space Gradients -->
    <radialGradient id="bgGrad" cx="50%" cy="45%" r="65%">
      <stop offset="0%" stop-color="#182642"/>
      <stop offset="60%" stop-color="#0c1220"/>
      <stop offset="100%" stop-color="#05070c"/>
    </radialGradient>
    <linearGradient id="borderGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#00f0ff"/>
      <stop offset="35%" stop-color="#1a508b"/>
      <stop offset="70%" stop-color="#ffd700"/>
      <stop offset="100%" stop-color="#00a8ff"/>
    </linearGradient>
    <linearGradient id="goldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fff5b8"/>
      <stop offset="35%" stop-color="#ffd700"/>
      <stop offset="75%" stop-color="#d48806"/>
      <stop offset="100%" stop-color="#874d00"/>
    </linearGradient>
    <linearGradient id="cyanGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#7bf0ff"/>
      <stop offset="70%" stop-color="#00b4ff"/>
      <stop offset="100%" stop-color="#0048aa"/>
    </linearGradient>
    <linearGradient id="shipHull" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#242c3d"/>
      <stop offset="30%" stop-color="#4d5c7a"/>
      <stop offset="50%" stop-color="#dce5f5"/>
      <stop offset="70%" stop-color="#4d5c7a"/>
      <stop offset="100%" stop-color="#242c3d"/>
    </linearGradient>
    <linearGradient id="wingLeft" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#3d4e6e"/>
      <stop offset="50%" stop-color="#1c2434"/>
      <stop offset="100%" stop-color="#0d131c"/>
    </linearGradient>
    <linearGradient id="wingRight" x1="100%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#5a6f9c"/>
      <stop offset="50%" stop-color="#283348"/>
      <stop offset="100%" stop-color="#0d131c"/>
    </linearGradient>
    <radialGradient id="coreGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="1"/>
      <stop offset="30%" stop-color="#00f0ff" stop-opacity="0.8"/>
      <stop offset="70%" stop-color="#0066ff" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="#002288" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="thrusterFlame" x1="50%" y1="0%" x2="50%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#66ffff"/>
      <stop offset="65%" stop-color="#0088ff"/>
      <stop offset="100%" stop-color="#001144" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <!-- Outer Rounded Shield / Hexagonal Emblem -->
  <!-- Outer Rim Shadow -->
  <polygon points="256,16 478,96 478,356 256,496 34,356 34,96" fill="none" stroke="#000d18" stroke-width="16" stroke-linejoin="round"/>
  <!-- Outer Bevel Rim -->
  <polygon points="256,18 474,98 474,354 256,492 38,354 38,98" fill="url(#borderGrad)" stroke="#001a33" stroke-width="4" stroke-linejoin="round"/>
  <!-- Inner Shield Void -->
  <polygon points="256,32 454,106 454,342 256,474 58,342 58,106" fill="url(#bgGrad)" stroke="#1a2b47" stroke-width="3" stroke-linejoin="round"/>

  <!-- High-Tech Circuit & Reticle Accents in Background -->
  <circle cx="256" cy="248" r="168" fill="none" stroke="#00f0ff" stroke-width="1.5" stroke-dasharray="6 8" opacity="0.35"/>
  <circle cx="256" cy="248" r="132" fill="none" stroke="#ffd700" stroke-width="1" opacity="0.25"/>
  <circle cx="256" cy="248" r="90" fill="none" stroke="#00f0ff" stroke-width="1.5" opacity="0.4"/>
  
  <!-- Reticle Crosshairs -->
  <line x1="256" y1="76" x2="256" y2=\"116\" stroke="#00f0ff" stroke-width="3" opacity="0.6" stroke-linecap="round"/>
  <line x1="256" y1="380" x2="256" y2="420" stroke="#00f0ff" stroke-width="3" opacity="0.6" stroke-linecap="round"/>
  <line x1="88" y1="248" x2="128" y2="248" stroke="#00f0ff" stroke-width="3" opacity="0.6" stroke-linecap="round"/>
  <line x1="384" y1="248" x2="424" y2="248" stroke="#00f0ff" stroke-width="3" opacity="0.6" stroke-linecap="round"/>

  <!-- Diagonal Tech Slits -->
  <line x1="136" y1="128" x2="164" y2="156" stroke="#ffd700" stroke-width="2.5" opacity="0.5" stroke-linecap="round"/>
  <line x1="376" y1="128" x2="348" y2="156" stroke="#ffd700" stroke-width="2.5" opacity="0.5" stroke-linecap="round"/>

  <!-- Nebula Background Flare -->
  <circle cx="256" cy="248" r="140" fill="url(#coreGlow)" opacity="0.45"/>

  <!-- ==================== CROSSED CEREMONIAL PLASMA KERIS (BACKGROUND) ==================== -->
  <!-- Keris 1 (Top-Left to Bottom-Right) -->
  <g transform="rotate(-34 256 248)">
    <!-- Blade Waves (Undulating Pamor) -->
    <path d="M256,80 Q266,110 256,140 Q246,170 256,200 Q266,230 256,260 Q246,290 256,320 L256,336 L251,336 Q239,290 249,260 Q259,230 249,200 Q239,170 249,140 Q259,110 251,80 Z" fill="url(#cyanGrad)" opacity="0.85"/>
    <!-- Keris Guard (Ganja Keris) -->
    <path d="M234,336 L278,336 L286,346 L226,346 Z" fill="url(#goldGrad)"/>
    <!-- Keris Hilt (Hulu Keris) -->
    <path d="M251,346 L261,346 L264,380 Q266,396 254,402 Q242,396 246,380 Z" fill="url(#goldGrad)"/>
  </g>

  <!-- Keris 2 (Top-Right to Bottom-Left) -->
  <g transform="rotate(34 256 248)">
    <!-- Blade Waves (Undulating Pamor) -->
    <path d="M256,80 Q246,110 256,140 Q266,170 256,200 Q246,230 256,260 Q266,290 256,320 L256,336 L261,336 Q273,290 263,260 Q253,230 263,200 Q273,170 263,140 Q253,110 261,80 Z" fill="url(#cyanGrad)" opacity="0.85"/>
    <!-- Keris Guard (Ganja Keris) -->
    <path d="M278,336 L234,336 L226,346 L286,346 Z" fill="url(#goldGrad)"/>
    <!-- Keris Hilt (Hulu Keris) -->
    <path d="M261,346 L251,346 L248,380 Q246,396 258,402 Q270,396 266,380 Z" fill="url(#goldGrad)"/>
  </g>

  <!-- ==================== HANG TUAH VOID INTERCEPTOR (FOREGROUND) ==================== -->
  <!-- Plasma Thruster Exhaust Plumes -->
  <polygon points="242,350 250,350 246,430" fill="url(#thrusterFlame)"/>
  <polygon points="262,350 270,350 266,430" fill="url(#thrusterFlame)"/>
  <polygon points="251,354 261,354 256,448" fill="url(#thrusterFlame)"/>

  <!-- Left Swept Wing (Wau Bulan Curved Aero-Foils) -->
  <path d="M256,220 L160,260 L92,306 L144,318 L212,298 L240,344 L256,348 Z" fill="url(#wingLeft)" stroke="#101824" stroke-width="2"/>
  <!-- Left Wing Trim / Armor Plate -->
  <path d="M256,240 L168,272 L116,308 L142,316 L204,298 L238,336 Z" fill="#223249" stroke="#00f0ff" stroke-width="1.5" opacity="0.9"/>
  <!-- Left Golden Songket Wing Edge Accent -->
  <path d="M92,306 L144,318 L130,314 L98,304 Z" fill="url(#goldGrad)"/>
  <polygon points="124,286 128,274 132,286 144,290 132,294 128,306 124,294 112,290" fill="#ffd700" opacity="0.8"/>

  <!-- Right Swept Wing -->
  <path d="M256,220 L352,260 L420,306 L368,318 L300,298 L272,344 L256,348 Z" fill="url(#wingRight)" stroke="#101824" stroke-width="2"/>
  <!-- Right Wing Trim / Armor Plate -->
  <path d="M256,240 L344,272 L396,308 L370,316 L308,298 L274,336 Z" fill="#324666" stroke="#00f0ff" stroke-width="1.5" opacity="0.9"/>
  <!-- Right Golden Songket Wing Edge Accent -->
  <path d="M420,306 L368,318 L382,314 L414,304 Z" fill="url(#goldGrad)"/>
  <polygon points="388,286 384,274 380,286 368,290 380,294 384,306 388,294 400,290" fill="#ffd700" opacity="0.8"/>

  <!-- Outer Wingtip Cannons -->
  <polygon points="90,300 96,276 100,300 96,312" fill="url(#goldGrad)"/>
  <line x1="96" y1="276" x2="96" y2="260" stroke="#00f0ff" stroke-width="2" stroke-linecap="round"/>
  <polygon points="422,300 416,276 412,300 416,312" fill="url(#goldGrad)"/>
  <line x1="416" y1="276" x2="416" y2="260" stroke="#00f0ff" stroke-width="2" stroke-linecap="round"/>

  <!-- Central Fuselage Prow -->
  <!-- Main Fuselage Body -->
  <polygon points="256,128 284,228 274,348 238,348 228,228" fill="url(#shipHull)" stroke="#162030" stroke-width="2"/>
  
  <!-- Dorsal Armor Spine (Beveled Titanium) -->
  <polygon points="256,134 266,220 262,342 250,342 246,220" fill="#ffffff" opacity="0.2"/>
  <polygon points="256,134 250,220 248,342 256,346" fill="#1c283d" opacity="0.4"/>
  
  <!-- Forward Spear Tip (Keris Nose) -->
  <polygon points="256,112 264,152 256,160 248,152" fill="url(#goldGrad)"/>

  <!-- Cockpit Canopy (Glowing Cyan Energy Core) -->
  <path d="M256,182 Q268,212 264,250 Q256,258 248,250 Q244,212 256,182 Z" fill="url(#cyanGrad)" stroke="#00f0ff" stroke-width="2"/>
  <!-- Cockpit Glint -->
  <ellipse cx="254" cy="206" rx="4" ry="14" fill="#ffffff" opacity="0.75" transform="rotate(-12 254 206)"/>

  <!-- Royal Medallion on Fuselage (Malay Solar Star) -->
  <circle cx="256" cy="286" r="12" fill="url(#goldGrad)" stroke="#ffffff" stroke-width="1.5"/>
  <circle cx="256" cy="286" r="5" fill="#00f0ff"/>

  <!-- Flanking Stars on Crest -->
  <!-- Left Star -->
  <polygon points="76,210 82,192 88,210 106,216 88,222 82,240 76,222 58,216" fill="url(#goldGrad)"/>
  <!-- Right Star -->
  <polygon points="436,210 430,192 424,210 406,216 424,222 430,240 436,222 454,216" fill="url(#goldGrad)"/>
</svg>'''

# =============================================================================
# 2. RASTER LOGO RENDERING (Pure Python SDF & Geometry Rasterizer)
# =============================================================================
def point_in_poly(x, y, poly):
    inside = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i+1)%n]
        if ((y1 > y) != (y2 > y)) and (x < (x2 - x1) * (y - y1) / (y2 - y1 + 1e-9) + x1):
            inside = not inside
    return inside

def dist_to_segment(px, py, x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return math.hypot(px - x1, py - y1)
    t = max(0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / (dx*dx + dy*dy)))
    proj_x = x1 + t * dx
    proj_y = y1 + t * dy
    return math.hypot(px - proj_x, py - proj_y)

def dist_to_poly_outline(x, y, poly):
    min_d = 1e9
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i+1)%n]
        d = dist_to_segment(x, y, x1, y1, x2, y2)
        if d < min_d:
            min_d = d
    return min_d

def render_logo_raster(target_size=512):
    buf = bytearray(target_size * target_size * 4)
    scale = target_size / 512.0

    # Shield polygon (512 space)
    shield_pts = [(256, 20), (470, 98), (470, 350), (256, 490), (42, 350), (42, 98)]
    inner_shield = [(256, 32), (454, 106), (454, 342), (256, 474), (58, 342), (58, 106)]

    for ty in range(target_size):
        y = ty / scale
        for tx in range(target_size):
            x = tx / scale
            
            # Check shield distance
            in_shield = point_in_poly(x, y, shield_pts)
            d_outline = dist_to_poly_outline(x, y, shield_pts)
            in_inner = point_in_poly(x, y, inner_shield)

            if not in_shield and d_outline > 4.0:
                continue

            # Anti-aliased outer edge
            alpha = 1.0
            if not in_shield:
                alpha = max(0.0, 1.0 - d_outline / 3.0)

            # Outer border gradient
            if not in_inner:
                # Beveled border: mix cyan, gold, deep navy
                t_vert = (y - 20) / 470.0
                r = int(min(255, 30 + 180 * t_vert * (1.0 - abs(x - 256) / 256.0)))
                g = int(min(255, 200 * (1.0 - t_vert * 0.5) + 120 * t_vert))
                b = int(min(255, 255 * (1.0 - t_vert * 0.4)))
            else:
                # Space background with radial core glow
                dx = x - 256
                dy = y - 248
                dist_center = math.hypot(dx, dy)
                
                # Dark space void
                r = int(max(8, 28 - dist_center * 0.08))
                g = int(max(14, 44 - dist_center * 0.12))
                b = int(max(24, 75 - dist_center * 0.16))

                # Reticle circle glow (radius ~168 and ~132)
                if abs(dist_center - 168) < 2.0:
                    g = min(255, g + 80)
                    b = min(255, b + 120)
                elif abs(dist_center - 132) < 1.5:
                    r = min(255, r + 90)
                    g = min(255, g + 80)
                elif abs(dist_center - 90) < 2.0:
                    g = min(255, g + 90)
                    b = min(255, b + 140)

                # Nebula core glow
                if dist_center < 140:
                    glow_f = (1.0 - dist_center / 140.0) ** 1.8
                    r = int(min(255, r + 20 * glow_f))
                    g = int(min(255, g + 110 * glow_f))
                    b = int(min(255, b + 180 * glow_f))

                # Thruster flame plume
                if y > 346 and y < 440 and abs(x - 256) < 24:
                    flame_y = (y - 346) / 94.0
                    flame_w = (1.0 - flame_y) * 16.0
                    if abs(x - 256) < flame_w:
                        intense = (1.0 - abs(x - 256) / flame_w) * (1.0 - flame_y)
                        r = int(min(255, r + 180 * intense))
                        g = int(min(255, g + 230 * intense))
                        b = int(min(255, b + 255 * intense))

                # Crossed Keris Blades (Diagonal waves)
                for angle_deg in [-34, 34]:
                    rad = math.radians(angle_deg)
                    cos_a = math.cos(rad)
                    sin_a = math.sin(rad)
                    # Rotate around (256, 248)
                    rx = cos_a * (x - 256) - sin_a * (y - 248) + 256
                    ry = sin_a * (x - 256) + cos_a * (y - 248) + 248
                    # Keris blade runs along rx=256, ry in [80..336]
                    if 80 <= ry <= 336:
                        wave_offset = math.sin((ry - 80) * 0.09) * 7.0
                        blade_dist = abs(rx - (256 + wave_offset))
                        if blade_dist < 6.0:
                            b_alpha = 1.0 - (blade_dist / 6.0)
                            r = int(min(255, r + 70 * b_alpha))
                            g = int(min(255, g + 200 * b_alpha))
                            b = int(min(255, b + 245 * b_alpha))
                    elif 336 < ry <= 346 and abs(rx - 256) < 24: # Ganja guard
                        r = min(255, r + 220)
                        g = min(255, g + 180)
                        b = min(255, b + 30)
                    elif 346 < ry <= 390 and abs(rx - 256) < 9: # Hulu hilt
                        r = min(255, r + 210)
                        g = min(255, g + 160)
                        b = min(255, b + 20)

                # Starship Wings (Swept Wau Bulan foils)
                left_wing = [(256, 220), (160, 260), (92, 306), (144, 318), (212, 298), (240, 344), (256, 348)]
                right_wing = [(256, 220), (352, 260), (420, 306), (368, 318), (300, 298), (272, 344), (256, 348)]
                in_lw = point_in_poly(x, y, left_wing)
                in_rw = point_in_poly(x, y, right_wing)
                if in_lw or in_rw:
                    side_sign = 1.0 if in_rw else -1.0
                    prog = abs(x - 256) / 164.0
                    r = int(40 + 40 * prog)
                    g = int(55 + 65 * prog)
                    b = int(85 + 95 * prog)
                    # Wing gold songket trim
                    if (y > 300 and abs(x - 256) > 80 and abs(x - 256) < 160) or abs(x - 256) > 150:
                        r = min(255, r + 160)
                        g = min(255, g + 130)
                        b = min(255, b + 10)

                # Starship Fuselage & Prow
                fuse_poly = [(256, 112), (284, 228), (274, 348), (238, 348), (228, 228)]
                if point_in_poly(x, y, fuse_poly):
                    fuse_norm = abs(x - 256) / 28.0
                    # Beveled metallic titanium fuselage
                    shade = max(0.0, 1.0 - fuse_norm * 0.8)
                    r = int(70 + 150 * shade)
                    g = int(85 + 150 * shade)
                    b = int(115 + 140 * shade)
                    # Spine highlight
                    if abs(x - 256) < 3.0:
                        r = min(255, r + 80)
                        g = min(255, g + 80)
                        b = min(255, b + 80)

                # Cockpit Canopy (Glowing Cyan Gem)
                dx_c = (x - 256) / 12.0
                dy_c = (y - 216) / 28.0
                if dx_c*dx_c + dy_c*dy_c <= 1.0 and y > 180 and y < 252:
                    canopy_val = 1.0 - math.sqrt(dx_c*dx_c + dy_c*dy_c)
                    r = int(min(255, 60 + 195 * canopy_val))
                    g = int(min(255, 200 + 55 * canopy_val))
                    b = 255

                # Royal Gold Emblem on fuselage
                if math.hypot(x - 256, y - 286) <= 12:
                    r, g, b = 255, 215, 0
                    if math.hypot(x - 256, y - 286) <= 5:
                        r, g, b = 0, 240, 255

            idx = (ty * target_size + tx) * 4
            buf[idx] = r
            buf[idx+1] = g
            buf[idx+2] = b
            buf[idx+3] = int(alpha * 255)

    return buf

# =============================================================================
# 3. ENERGY SHIELD GENERATION (High-tech glowing forcefield)
# =============================================================================
def render_energy_shield(size=128):
    buf = bytearray(size * size * 4)
    center = size / 2.0
    max_r = size * 0.46

    for y in range(size):
        dy = y - center
        for x in range(size):
            dx = x - center
            r = math.hypot(dx, dy)
            if r > max_r + 4.0:
                continue

            # Normalized distance to perimeter
            d_rim = abs(r - max_r)
            alpha = 0.0

            # Outer energy rim
            if d_rim <= 5.0:
                alpha = max(alpha, (1.0 - d_rim / 5.0) * 0.95)

            # Secondary resonant energy ring
            d_mid = abs(r - (max_r * 0.78))
            if d_mid <= 3.5:
                alpha = max(alpha, (1.0 - d_mid / 3.5) * 0.55)

            # Translucent forcefield bubble fill
            if r <= max_r:
                bubble_fill = (r / max_r) ** 2.2 * 0.35
                alpha = max(alpha, bubble_fill)

            # Hexagonal grid pulse simulation
            angle = math.atan2(dy, dx)
            hex_grid = abs(math.sin(angle * 6.0)) * (r / max_r) * 0.22
            alpha = min(1.0, alpha + hex_grid)
            clamp_alpha = max(0.0, min(1.0, alpha))

            factor = max(0.0, 1.0 - d_rim / 6.0)
            cr = int(min(255, max(0, 80 + 175 * factor)))
            cg = int(min(255, max(0, 210 + 45 * factor)))
            cb = 255

            idx = (y * size + x) * 4
            buf[idx] = cr
            buf[idx+1] = cg
            buf[idx+2] = cb
            buf[idx+3] = int(clamp_alpha * 255)

    return buf

def main():
    print("Generating official game logo assets...")
    
    # 1. Update root icon.svg
    svg_data = generate_vector_svg()
    with open("icon.svg", "w", encoding="utf-8") as f:
        f.write(svg_data)
    print("✓ Saved icon.svg (Root Godot Game Icon)")

    # 2. Render 512x512 Master Logo PNG
    tex_dir = "assets/textures"
    os.makedirs(tex_dir, exist_ok=True)
    
    logo_512 = render_logo_raster(512)
    path_512 = os.path.join(tex_dir, "game_logo.png")
    write_png(path_512, 512, 512, logo_512)
    print(f"✓ Saved {path_512} (512x512 Master Game Logo)")

    # Copy to brain artifact directory for user review
    artifact_dir = "/Users/idil/.gemini/antigravity/brain/9f3d5a2c-b21e-4b1a-bad4-0d27db8d68e5"
    if os.path.exists(artifact_dir):
        artifact_path = os.path.join(artifact_dir, "game_logo.png")
        write_png(artifact_path, 512, 512, logo_512)
        print(f"✓ Copied game logo to artifact directory: {artifact_path}")

    # 3. Render 192x192 Launcher Icon (for Android / AppGallery export preset)
    logo_192 = render_logo_raster(192)
    path_192 = os.path.join(tex_dir, "game_logo_192.png")
    write_png(path_192, 192, 192, logo_192)
    print(f"✓ Saved {path_192} (192x192 Launcher Icon)")

    # 4. Render 432x432 Adaptive Foreground Icon
    logo_432 = render_logo_raster(432)
    path_432 = os.path.join(tex_dir, "game_logo_432.png")
    write_png(path_432, 432, 432, logo_432)
    print(f"✓ Saved {path_432} (432x432 Adaptive Icon)")

    # 5. Render dedicated Player Energy Shield Barrier
    shield_128 = render_energy_shield(128)
    shield_path = os.path.join(tex_dir, "energy_shield.png")
    write_png(shield_path, 128, 128, shield_128)
    print(f"✓ Saved {shield_path} (128x128 Energy Shield Barrier)")

if __name__ == "__main__":
    main()
