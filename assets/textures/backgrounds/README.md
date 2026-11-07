# Space Shooter 2D: Campaign Background Arts Guide
## Gameplay Background Arts Master System

This directory houses the modular, high-definition background textures for the 20-stage campaign. The game automatically divides stages into 4 themed Sectors and loops each background infinitely and smoothly across the horizontal axis.

---

## 1. Fast Track: Replace Any Background with Your Own PNG

You can replace any background in two easy ways:

### Option A: Overwrite Existing PNGs (Zero Code Required)
Simply save your custom PNG image using the standard sector filenames in this folder:
* **Stages 1 to 5:** `bg_sector_1.png`
* **Stages 6 to 10:** `bg_sector_2.png`
* **Stages 11 to 15:** `bg_sector_3.png`
* **Stages 16 to 20:** `bg_sector_4.png`

The engine will immediately display your new background when you launch or enter that stage range!

### Option B: Add a New File & Point Dictionary in Inspector or Code
1. Drop your PNG file anywhere in `assets/textures/backgrounds/` (e.g. `my_nebula.png`).
2. Open `scenes/environment/starfield_background.gd` (or select `StarfieldCanvas` in the Godot Inspector).
3. In `background_sectors`, change the `texture_path` property for that sector:
   ```gdscript
   "texture_path": "res://assets/textures/backgrounds/my_nebula.png"
   ```

---

## 2. Sector Mapping Reference Table

| Sector | Stages | Default Texture File | Theme / Atmosphere | Default Scroll Speed |
| :---: | :---: | :--- | :--- | :---: |
| **Sector 1** | **Stages 1 – 5** | `res://assets/textures/backgrounds/bg_sector_1.png` | Deep Space Nebula (Cyan / Azure) | $40.0\text{ px/s}$ |
| **Sector 2** | **Stages 6 – 10** | `res://assets/textures/backgrounds/bg_sector_2.png` | Solar Hazard & Cosmic Rift (Amber / Flare) | $55.0\text{ px/s}$ |
| **Sector 3** | **Stages 11 – 15** | `res://assets/textures/backgrounds/bg_sector_3.png` | Asteroid Perimeter (Deep Teal / Jade) | $70.0\text{ px/s}$ |
| **Sector 4** | **Stages 16 – 20** | `res://assets/textures/backgrounds/bg_sector_4.png` | Alien Void Citadel (Dark Matter Violet) | $90.0\text{ px/s}$ |

---

## 3. Recommended PNG Specifications

* **Target Resolution:** $1920 \times 1080\text{ px}$ (Native viewport).
  * *Note: The engine automatically scales any image height to fit the screen height ($1080\text{ px}$), so $2560\times 1440$, $3840\times 1080$, or $1280\times 720$ also work seamlessly.*
* **Format:** Standard PNG (24-bit RGB or 32-bit RGBA).
* **Seamless Repeating:** For an invisible loop, ensure the leftmost pixel column ($x=0$) matches or blends into the rightmost pixel column ($x=W-1$).
* **Leftmost Edge Wraparound:** The engine calculates:
  $$X_{\text{offset}} = \text{fmod}(X_{\text{offset}} - \text{speed} \times \Delta t, W_{\text{display}})$$
  drawing continuous adjacent tiles so there are never any black gaps or stutter when wrapping.

---

## 4. Moving Stars and Meteors Control

If your custom background art already has detailed stars or an atmospheric look, you can easily adjust or disable the procedural stars and shooting stars:

* **Per-Sector in Dictionary:**
  ```gdscript
  "enable_stars": false,           # Turns off passing white stars for this sector
  "enable_shooting_stars": false,  # Turns off shooting star meteors for this sector
  "star_alpha": 0.40,              # Subtle dim stars (0.0 to 1.0)
  ```
* **Globally in Inspector or Script:**
  * Toggle `enable_stars = false` on `StarfieldCanvas`.
  * Toggle `enable_shooting_stars = false` on `StarfieldCanvas`.
  * Toggle `enable_background_texture = false` if you only want vector stars.

---

## 5. Sector Transition & Cinematic Warp Customization

When moving from one sector to another (e.g. Stage 5 to Stage 6), the engine performs an S-curve dissolve (`smoothstep`) with dual-texture continuous scrolling and speed blending:

* **Adjust Transition Duration:**
  In `starfield_background.gd` or Inspector:
  ```gdscript
  @export var transition_duration: float = 1.4  # Time in seconds for the cross-dissolve
  ```
* **Warp Speed Surge:**
  Toggles a subtle speed surge peaking at the midpoint of the transition:
  ```gdscript
  @export var enable_warp_surge: bool = true
  @export var warp_surge_intensity: float = 0.35
  ```

---

## 6. Crash-Proof Safeguards

* If a PNG file path has a typo or is temporarily missing, the engine logs a friendly notice to the console and gracefully displays a deep space procedural void. The game will **never crash** or halt.
