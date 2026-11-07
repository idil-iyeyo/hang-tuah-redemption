class_name StageAudioDatabase
extends RefCounted

## Dedicated Sound & Music Configuration Database
## Houses centralized dictionaries for:
## 1. Stage-based background music across all normal sectors and boss stages.
## 2. In-game sound effect slots and stage-specific audio mappings.
##
## Stage Music Brackets:
## - "menu": Main Menu, Mission Select & Upgrade Hangar
## - "1-4": Sector 1 Normal Enemy Waves (Deep Nebula)
## - "5": Boss Encounter 1 (Swarm Vanguard)
## - "6-9": Sector 2 Normal Enemy Waves (Cosmic Rift)
## - "10": Boss Encounter 2 (Dragon Roach Queen)
## - "11-14": Sector 3 Normal Enemy Waves (Asteroid Belt)
## - "15": Boss Encounter 3 (Ancient Dreadnought)
## - "16-19": Sector 4 Normal Enemy Waves (Void Citadel)
## - "20": Boss Encounter 4 (Cosmic Overlord - Final Boss)
##
## Designed for 1-click swapping: users can change paths in the dictionary
## or assign AudioStream resources directly without touching engine code.

const STAGE_BRACKETS: Array[String] = [
	"menu",
	"1-4",
	"5",
	"6-9",
	"10",
	"11-14",
	"15",
	"16-19",
	"20"
]

const DEFAULT_STAGE_MUSIC_SLOTS: Dictionary = {
	"menu": {
		"title": "Main Menu & Level Select",
		"path": "res://assets/audio/music/music/main-menu.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Welcome Screen & Mission Hub"
	},
	"1-4": {
		"title": "Sector 1 (Stages 1-4): Deep Nebula",
		"path": "res://assets/audio/music/music/Cyberpunk-1(Trimmed2).wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 1, 2, 3, 4"
	},  
	"5": {
		"title": "Boss Encounter 1 (Stage 5): Swarm Vanguard",
		"path": "res://assets/audio/music/music/Asian-1.ogg",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stage 5 (Boss)"
	},
	"6-9": {
		"title": "Sector 2 (Stages 6-9): Cosmic Rift",
		"path": "res://assets/audio/music/music/Cyberpunk-1(Trimmed).wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 6, 7, 8, 9"
	},
	"10": {
		"title": "Boss Encounter 2 (Stage 10): Dragon Roach Queen",
		"path": "res://assets/audio/music/music/boss-asian-2.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stage 10 (Boss)"
	},
	"11-14": {
		"title": "Sector 3 (Stages 11-14): Asteroid Belt",
		"path": "res://assets/audio/music/music/chapter-3.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 11, 12, 13, 14"
	},
	"15": {
		"title": "Boss Encounter 3 (Stage 15): Ancient Dreadnought",
		"path": "res://assets/audio/music/music/boss-epic-1.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stage 15 (Boss)"
	},
	"16-19": {
		"title": "Sector 4 (Stages 16-19): Void Citadel",
		"path": "res://assets/audio/music/music/chapter4-old-asian.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 16, 17, 18, 19"
	},
	"20": {
		"title": "Final Boss Encounter (Stage 20): Cosmic Overlord",
		"path": "res://assets/audio/music/music/boss-asian-3.wav",
		"volume_db": 0.5,
		"stream": null,
		"stages": "Stage 20 (Final Boss)"
	}
}

const DEFAULT_SOUND_SLOTS: Dictionary = {
	"wave_start": {
		"name": "Wave Start Alert",
		"path": "",
		"volume_db": -6.0,
		"stream": null
	},
	"wave_clear": {
		"name": "Wave Victory Chime",
		"path": "",
		"volume_db": -6.0,
		"stream": null
	},
	"purchase": {
		"name": "Upgrade Purchased Chime",
		"path": "",
		"volume_db": -6.0,
		"stream": null
	},
	"button_click": {
		"name": "UI Button Click",
		"path": "",
		"volume_db": -6.0,
		"stream": null
	},
	"boss_warning": {
		"name": "Boss Approaching Siren",
		"path": "",
		"volume_db": -5.0,
		"stream": null
	}
}


## Returns a fresh copy of the default stage music slots dictionary
static func get_default_stage_music_slots() -> Dictionary:
	return DEFAULT_STAGE_MUSIC_SLOTS.duplicate(true)


## Returns a fresh copy of the default sound effects slots dictionary
static func get_default_sound_slots() -> Dictionary:
	return DEFAULT_SOUND_SLOTS.duplicate(true)


## Converts a stage number and boss flag into its canonical stage bracket key
static func get_stage_bracket(stage_num: int, is_boss: bool = false) -> String:
	if is_boss or stage_num in [5, 10, 15, 20]:
		if stage_num <= 5:
			return "5"
		elif stage_num <= 10:
			return "10"
		elif stage_num <= 15:
			return "15"
		else:
			return "20"

	if stage_num <= 4:
		return "1-4"
	elif stage_num <= 9:
		return "6-9"
	elif stage_num <= 14:
		return "11-14"
	else:
		return "16-19"


## Resolves the music track dictionary for a given stage number
static func resolve_stage_track(slots: Dictionary, stage_num: int, is_boss: bool = false) -> Dictionary:
	var bracket: String = get_stage_bracket(stage_num, is_boss)
	if slots.has(bracket):
		return slots[bracket]
	# Fallback if custom slots dictionary is incomplete
	if DEFAULT_STAGE_MUSIC_SLOTS.has(bracket):
		return DEFAULT_STAGE_MUSIC_SLOTS[bracket]
	return DEFAULT_STAGE_MUSIC_SLOTS["1-4"]


## Assigns a custom audio file path to a stage bracket
static func set_stage_track_path(slots: Dictionary, bracket: String, file_path: String, volume_db: float = -8.0) -> bool:
	if not slots.has(bracket):
		slots[bracket] = {
			"title": "Custom %s" % bracket,
			"path": file_path,
			"volume_db": volume_db,
			"stream": null,
			"stages": "Custom Bracket %s" % bracket
		}
	else:
		slots[bracket]["path"] = file_path
		slots[bracket]["volume_db"] = volume_db
		slots[bracket]["stream"] = null

	if not file_path.is_empty() and ResourceLoader.exists(file_path):
		var res = load(file_path)
		if res is AudioStream:
			slots[bracket]["stream"] = res
			return true
	return false


## Assigns an AudioStream resource directly to a stage bracket
static func set_stage_track_stream(slots: Dictionary, bracket: String, stream: AudioStream, volume_db: float = -8.0) -> void:
	if not slots.has(bracket):
		slots[bracket] = {
			"title": "Custom %s" % bracket,
			"path": "",
			"volume_db": volume_db,
			"stream": stream,
			"stages": "Custom Bracket %s" % bracket
		}
	else:
		slots[bracket]["stream"] = stream
		slots[bracket]["volume_db"] = volume_db
