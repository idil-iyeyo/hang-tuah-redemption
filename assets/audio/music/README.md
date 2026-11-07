# Stage Music & Sound Configuration Guide

Welcome to the **Space Shooter 2D** Dedicated Audio System!
This folder houses the background music tracks for every stage sector and boss encounter in the game. You can easily swap and customize the music used for any individual stage group or boss fight.

---

## 1. Supported Audio Formats
Godot natively supports:
- **WAV** (`.wav`): Crisp, uncompressed 16-bit PCM audio. Perfect for seamless, click-free looping.
- **OGG Vorbis** (`.ogg`): Lightweight, superior compression for long soundtracks.
- **MP3** (`.mp3`): Fully supported standard compressed audio format.

---

## 2. Dedicated Stage Music Dictionary

The game uses a structured stage bracket dictionary configured in [`scripts/stage_audio_database.gd`](file:///Users/idil/GodotProjectFile/new-game-auto/scripts/stage_audio_database.gd) and managed by [`scripts/music_manager.gd`](file:///Users/idil/GodotProjectFile/new-game-auto/scripts/music_manager.gd):

| Bracket Key | Scene / Stage Context | Default File | Default Vol | Description |
| :---: | :--- | :--- | :---: | :--- |
| **`menu`** | **Main Menu & Level Select** | `menu_theme.wav` | -8.0 dB | Ambient synth theme for Welcome screen, mission select carousel & hangar |
| **`1-4`** | **Sector 1 (Stages 1–4)** | `stage_1_4.wav` | -8.0 dB | Gentle synthwave combat groove in D minor (Deep Nebula) |
| **`5`** | **Boss 1 (Stage 5)** | `boss_stage_5.wav` | -7.0 dB | Tense battle pulse with war-drums in G minor (Swarm Vanguard) |
| **`6-9`** | **Sector 2 (Stages 6–9)** | `stage_6_9.wav` | -8.0 dB | Driving electro-bass combat theme in A minor (Cosmic Rift) |
| **`10`** | **Boss 2 (Stage 10)** | `boss_stage_10.wav` | -7.0 dB | Heavy industrial combat battle in C minor (Dragon Roach Queen) |
| **`11-14`** | **Sector 3 (Stages 11–14)** | `stage_11_14.wav` | -8.0 dB | Rapid cosmic rhythm in E minor (Asteroid Belt) |
| **`15`** | **Boss 3 (Stage 15)** | `boss_stage_15.wav` | -7.0 dB | Menacing brass stabs in F minor (Ancient Dreadnought) |
| **`16-19`** | **Sector 4 (Stages 16–19)** | `stage_16_19.wav` | -8.0 dB | Hyperdrive synth action in B minor (Void Citadel) |
| **`20`** | **Final Boss (Stage 20)** | `boss_stage_20.wav` | -6.5 dB | Climactic battle symphony in D minor (Cosmic Overlord) |

*Backwards-compatibility mirrors:*
- `ingame_combat.wav` mirrors `stage_1_4.wav`
- `boss_battle.wav` mirrors `boss_stage_10.wav`

---

## 3. How to Replace & Customize Stage Music

### Method A: Direct File Drop-In
Replace any file in `assets/audio/music/` with your own audio file matching the filename (e.g. replace `stage_6_9.wav` or `boss_stage_5.wav`). When the game launches, Godot automatically loads your new audio track!

### Method B: Godot Inspector Override on Main Scene
1. Open the Godot Editor and select the `Main` node in `scenes/main/main.tscn`.
2. Locate the **Stage Music Slots** dictionary in the Inspector.
3. Replace the `"path"` string of any bracket (`"1-4"`, `"5"`, `"6-9"`, etc.) with your custom file (`"res://assets/audio/music/my_track.mp3"`).

### Method C: Dedicated Script Configuration
Open [`scripts/stage_audio_database.gd`](file:///Users/idil/GodotProjectFile/new-game-auto/scripts/stage_audio_database.gd) and customize `DEFAULT_STAGE_MUSIC_SLOTS`:

```gdscript
const DEFAULT_STAGE_MUSIC_SLOTS: Dictionary = {
    "1-4": {
        "title": "My Custom Sector 1",
        "path": "res://assets/audio/music/custom_nebula.ogg",
        "volume_db": -8.0,
        "stream": null,
        "stages": "Stages 1, 2, 3, 4"
    },
    "5": {
        "title": "My Custom Boss Fight",
        "path": "res://assets/audio/music/epic_boss_5.wav",
        "volume_db": -7.0,
        "stream": null,
        "stages": "Stage 5 (Boss)"
    },
    # ...
}
```

### Method D: Dynamic Runtime Script API
Change any stage's music on the fly from any script:
```gdscript
# Change music for Stages 6-9
MusicManager.set_stage_track("6-9", "res://assets/audio/music/cyberpunk_rift.mp3", -8.0)

# Change music for Stage 20 Final Boss directly with an AudioStream
var final_stream = load("res://assets/audio/music/orchestral_climax.ogg")
MusicManager.set_stage_track("20", final_stream, -6.0)
```

---

## 4. Balanced, Calibrated Sound Mix
- **Quieter Music Output**: Default volume across all background music tracks is calibrated between `-8.0 dB` and `-6.5 dB` with gentle 0.45 peak normalization so it never overpowers combat or laser shots.
- **SFX & UI Tones**: Weapon sounds and UI alert tones are smoothly balanced on the dedicated `"SFX"` audio bus at comfortable levels.
- **In-Game Music Slider**: Players can adjust the music slider independently at any time from the Main Menu Settings or in-game via `⏸ PAUSE -> ⚙ SETTINGS`.
