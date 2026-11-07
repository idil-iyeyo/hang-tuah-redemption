# Custom Gun Sounds Directory

This folder is the dedicated repository for custom weapon audio sound effects.
You can place your own audio files here and easily assign them in `scenes/player/gun.gd`!

---

## 1. Supported Audio Formats
Godot 4 natively supports the following standard audio formats:
- **WAV** (`.wav`): Recommended for crisp, low-latency weapon shots.
- **OGG Vorbis** (`.ogg`): Recommended for continuous beam hums or longer audio clips.
- **MP3** (`.mp3`): Fully supported for general sound effects.

---

## 2. Weapon Tier Reference

| Tier ID | Weapon Name | Default Sound Type | Description |
| :---: | :--- | :--- | :--- |
| **0** | **Emergency Blaster** | Procedural Blaster | Light emergency shot |
| **1** | **Plasma Blaster** | Procedural Blaster | Standard swift blaster bolt |
| **2** | **Dual Blaster** | Procedural Blaster | Rapid alternating twin bolts |
| **3** | **Heavy Cannon** | Procedural Cannon | Heavy low-frequency explosive boom |
| **4** | **Explosive Gatling** | Procedural Gatling | High-frequency rapid plasma salvo |
| **5** | **Quasar Laser** | Continuous Beam Hum | High-energy continuous laser ray |

---

## 3. How to Replace Gun Sounds

### Method A: Edit the Dictionary in `scenes/player/gun.gd`
Open `scenes/player/gun.gd` and locate `DEFAULT_GUN_SOUNDS`.
Simply set `"sound_path"` to your audio file path:

```gdscript
const DEFAULT_GUN_SOUNDS: Dictionary = {
    0: {
        "name": "Emergency Blaster",
        "sound_path": "res://assets/audio/guns/my_emergency.wav",
        "pitch": 1.0,
        "volume_db": 0.0,
    },
    5: {
        "name": "Quasar Laser",
        "sound_path": "res://assets/audio/guns/my_laser_beam.wav",
        "pitch": 1.0,
        "volume_db": 1.0,
    },
}
```

### Method B: Change at Runtime via Code
You can also change any gun's sound on the fly from another script:
```gdscript
# Set sound path for Level 5 Quasar Laser
gun.set_gun_sound_path(5, "res://assets/audio/guns/my_laser.wav", 1.0, 0.0)

# Or set sound path for Level 3 Heavy Cannon
gun.set_gun_sound_path(3, "res://assets/audio/guns/my_cannon.wav", 1.0, 2.0)
```
