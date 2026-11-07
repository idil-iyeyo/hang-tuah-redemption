# Custom Sound Effects Directory & Sound System Guide

Welcome to the **Space Shooter 2D** Sound Effects Repository!
This directory contains dedicated sound effects for UI, waves, weapons, and combat. Every sound in the game is centralized in [`scripts/sound_manager.gd`](file:///Users/idil/GodotProjectFile/new-game-auto/scripts/sound_manager.gd) and can be easily altered or replaced!

---

## 1. Supported Audio Formats
- **WAV** (`.wav`): Recommended for sound effects due to instant zero-latency playback.
- **OGG Vorbis** (`.ogg`): Supported for longer special effect audio clips.
- **MP3** (`.mp3`): Fully supported standard compressed audio.

---

## 2. Centralized Sound Effects Catalog

Every sound effect has an entry in `SoundManager.SOUND_EFFECTS`:

| Sound ID | Sound Name | Category | Default File | Description |
| :---: | :--- | :---: | :--- | :--- |
| **`button_click`** | Button Click | UI | `button_click.wav` | Standard UI button clicks and carousel navigation |
| **`play_start`** | Game Start / Unpause | UI | `play_start.wav` | Ascending chime when launching or resuming game |
| **`modal_chime`** | Modal Open | UI | `modal_chime.wav` | Dual soft chime when opening Settings or Credits |
| **`level_complete`** | Stage Victory | UI | `level_complete.wav` | Fanfare when completing a wave/stage |
| **`purchase`** | Upgrade Purchased | UI | `purchase.wav` | Positive coin chime when buying an upgrade |
| **`wave_start`** | Wave Start Alert | Wave | `wave_start.wav` | Tactical combat alert when wave begins |
| **`wave_clear`** | Wave Cleared | Wave | `wave_clear.wav` | Clear chime when all enemies are defeated |
| **`boss_warning`** | Boss Approaching | Wave | `boss_warning.wav` | Siren alarm when entering a boss battle |
| **`player_hit`** | Ship Hull Impact | Player | `player_hit.wav` | Low crunch when ship takes direct damage |
| **`shield_hit`** | Shield Deflection | Player | `shield_hit.wav` | Harmonic energy ping when shield absorbs hit |
| **`shield_recharge`**| Shield Recharged | Player | `shield_hit.wav` | Shield restoration cue |
| **`player_die`** | Ship Destroyed | Player | `player_die.wav` | Explosive detonation when ship is lost |
| **`laser_shoot`** | Plasma Blaster | Weapons | `laser_shoot.wav` | Swift laser blaster bolt |
| **`cannon_shoot`** | Heavy Cannon | Weapons | `cannon_shoot.wav` | Low explosive punch for Heavy Cannon |
| **`enemy_explode`** | Enemy Destroyed | Combat | `enemy_explode.wav` | Pop-explosion on enemy destruction |

---

## 3. How to Replace Sound Effects

### Method A: Direct File Drop-In (Simplest)
Replace any `.wav` file in `assets/audio/sfx/` with your own sound file of the same name. Godot will automatically use your new sound on next launch!

### Method B: Edit Dictionary in `scripts/sound_manager.gd`
Open [`scripts/sound_manager.gd`](file:///Users/idil/GodotProjectFile/new-game-auto/scripts/sound_manager.gd) and update the `"path"` or `"volume_db"` in `SOUND_EFFECTS`:

```gdscript
"button_click": {
    "name": "My Custom Click",
    "path": "res://assets/audio/sfx/my_mechanical_click.wav",
    "volume_db": -5.0,
    "pitch": 1.0,
    "pitch_range": Vector2(0.95, 1.05)
}
```

### Method C: Runtime Script API
Change any sound effect dynamically at runtime from any script:
```gdscript
# Change sound effect path
SoundManager.set_sound_path("purchase", "res://assets/audio/sfx/my_coin.wav", -4.0)

# Play any sound directly from any script:
SoundManager.play_sfx("button_click")
SoundManager.play_sfx("wave_start")
SoundManager.play_sfx("player_hit")
```
