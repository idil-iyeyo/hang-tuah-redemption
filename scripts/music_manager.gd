class_name MusicManager
extends Node

## Music and Audio Management Component for Space Shooter 2D
## Handles dynamic stage music transitions, smooth cross-fading, volume bus routing ("Music" bus),
## and dedicated sound/stage dictionaries for easy customization.

const StageAudioDatabase = preload("res://scripts/stage_audio_database.gd")

enum TrackType {
	NONE,
	MENU,
	INGAME,
	BOSS
}

signal track_changed(track_key: String, title: String)

## Master stage music table incorporating all sectors and boss stages.
## Calibrated to loud, punchy presence (0.0 dB / 0.5 dB); upgraded from legacy quieter -8.0 dB / -7.0 dB defaults.
const DEFAULT_MUSIC_TRACKS: Dictionary = {
	"menu": {
		"title": "Main Menu & Level Select",
		"path": "res://assets/audio/music/menu_theme.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Welcome Screen & Mission Hub"
	},
	"1-4": {
		"title": "Sector 1 (Stages 1-4): Deep Nebula",
		"path": "res://assets/audio/music/stage_1_4.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 1, 2, 3, 4"
	},
	"5": {
		"title": "Boss Encounter 1 (Stage 5): Swarm Vanguard",
		"path": "res://assets/audio/music/boss_stage_5.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stage 5 (Boss)"
	},
	"6-9": {
		"title": "Sector 2 (Stages 6-9): Cosmic Rift",
		"path": "res://assets/audio/music/stage_6_9.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 6, 7, 8, 9"
	},
	"10": {
		"title": "Boss Encounter 2 (Stage 10): Dragon Roach Queen",
		"path": "res://assets/audio/music/boss_stage_10.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stage 10 (Boss)"
	},
	"11-14": {
		"title": "Sector 3 (Stages 11-14): Asteroid Belt",
		"path": "res://assets/audio/music/stage_11_14.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 11, 12, 13, 14"
	},
	"15": {
		"title": "Boss Encounter 3 (Stage 15): Ancient Dreadnought",
		"path": "res://assets/audio/music/boss_stage_15.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stage 15 (Boss)"
	},
	"16-19": {
		"title": "Sector 4 (Stages 16-19): Void Citadel",
		"path": "res://assets/audio/music/stage_16_19.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 16, 17, 18, 19"
	},
	"20": {
		"title": "Final Boss Encounter (Stage 20): Cosmic Overlord",
		"path": "res://assets/audio/music/boss_stage_20.wav",
		"volume_db": 0.5,
		"stream": null,
		"stages": "Stage 20 (Final Boss)"
	},
	# Backward compatibility aliases
	"ingame": {
		"title": "In-Game Normal Combat",
		"path": "res://assets/audio/music/ingame_combat.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 1-4, 6-9, 11-14, 16-19"
	},
	"boss": {
		"title": "Boss Encounter Anthem",
		"path": "res://assets/audio/music/boss_battle.wav",
		"volume_db": 0.0,
		"stream": null,
		"stages": "Stages 5, 10, 15, 20"
	}
}

static var tracks_config: Dictionary = {}
static var active_instance: MusicManager = null

var player_a: AudioStreamPlayer = null
var player_b: AudioStreamPlayer = null
var current_player: AudioStreamPlayer = null
var active_track_key: String = ""
var fade_tween: Tween = null
var is_active: bool = true


func _init() -> void:
	if tracks_config.is_empty():
		reset_tracks()


func _ready() -> void:
	active_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_audio_buses()
	_setup_audio_players()


static func ensure_audio_buses() -> void:
	# Guarantee that "Music" and "SFX" audio buses exist and send to "Master"
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx < 0:
		master_idx = 0

	var music_idx: int = AudioServer.get_bus_index("Music")
	if music_idx == -1:
		music_idx = AudioServer.bus_count
		AudioServer.add_bus(music_idx)
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")

	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		sfx_idx = AudioServer.bus_count
		AudioServer.add_bus(sfx_idx)
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")


func _setup_audio_players() -> void:
	player_a = AudioStreamPlayer.new()
	player_a.name = "MusicPlayerA"
	player_a.bus = "Music"
	player_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player_a)

	player_b = AudioStreamPlayer.new()
	player_b.name = "MusicPlayerB"
	player_b.bus = "Music"
	player_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player_b)

	player_a.finished.connect(func(): _on_player_finished(player_a))
	player_b.finished.connect(func(): _on_player_finished(player_b))


func _on_player_finished(p: AudioStreamPlayer) -> void:
	if p == current_player and is_instance_valid(p) and p.stream != null and is_active:
		p.play(0.0)


## Resolves stage number to stage bracket ("1-4", "5", "6-9", "10", "11-14", "15", "16-19", "20")
static func get_stage_bracket(stage_num: int, is_boss: bool = false) -> String:
	return StageAudioDatabase.get_stage_bracket(stage_num, is_boss)


## Main Orchestration Method: Plays the appropriate music for any stage (normal or boss)
func play_stage_music(stage_num: int, is_boss: bool = false, fade_time: float = 0.5) -> void:
	var bracket: String = get_stage_bracket(stage_num, is_boss)
	play_track(bracket, fade_time)


## Plays the Main Menu theme
func play_menu_music(fade_time: float = 0.5) -> void:
	play_track("menu", fade_time)


## Plays the In-Game Normal enemy stage theme (maps to current sector or default)
func play_ingame_music(stage_or_fade: Variant = 1, fade_time: float = 0.5) -> void:
	if stage_or_fade is float:
		play_track("ingame", float(stage_or_fade))
	elif stage_or_fade is int:
		play_stage_music(int(stage_or_fade), false, fade_time)
	else:
		play_stage_music(1, false, fade_time)


## Plays the dramatic Boss encounter theme (maps to current boss or default)
func play_boss_music(stage_or_fade: Variant = 5, fade_time: float = 0.4) -> void:
	if stage_or_fade is float:
		play_track("boss", float(stage_or_fade))
	elif stage_or_fade is int:
		play_stage_music(int(stage_or_fade), true, fade_time)
	else:
		play_stage_music(5, true, fade_time)


## Switches smoothly to the requested track bracket
func play_track(track_key: String, fade_time: float = 0.5) -> void:
	var canonical_key: String = track_key
	if not tracks_config.has(canonical_key):
		# Fallback resolution
		if canonical_key == "ingame":
			canonical_key = "1-4"
		elif canonical_key == "boss":
			canonical_key = "5"
		else:
			push_warning("MusicManager: Unknown track key '%s', falling back to '1-4'" % track_key)
			canonical_key = "1-4"

	if active_track_key == canonical_key and current_player != null and current_player.playing:
		return # Already playing this track

	var stream: AudioStream = get_track_stream(canonical_key)
	if stream == null:
		push_warning("MusicManager: Could not load stream for '%s', generating fallback tone." % canonical_key)
		stream = _generate_fallback_stream(canonical_key)

	_configure_stream_loop(stream)

	var next_player: AudioStreamPlayer = player_b if current_player == player_a else player_a
	var prev_player: AudioStreamPlayer = current_player

	active_track_key = canonical_key
	current_player = next_player
	is_active = true

	var track_cfg: Dictionary = tracks_config.get(canonical_key, {})
	var target_db: float = float(track_cfg.get("volume_db", 0.0))

	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play(0.0)

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	fade_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(next_player, "volume_db", target_db, fade_time)

	if prev_player and prev_player.playing:
		fade_tween.tween_property(prev_player, "volume_db", -80.0, fade_time)
		fade_tween.chain().tween_callback(func():
			if prev_player != current_player:
				prev_player.stop()
		)

	track_changed.emit(canonical_key, str(track_cfg.get("title", canonical_key)))


## Stops current music with a smooth fade-out
func stop_music(fade_time: float = 0.4) -> void:
	is_active = false
	active_track_key = ""
	if current_player == null:
		return

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(current_player, "volume_db", -80.0, fade_time)
	fade_tween.tween_callback(func():
		if current_player:
			current_player.stop()
	)


func _configure_stream_loop(stream: AudioStream) -> void:
	if stream == null:
		return

	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		var dur: float = wav.get_length()
		var rate: int = wav.mix_rate if wav.mix_rate > 0 else 44100
		var total_frames: int = roundi(dur * float(rate))

		# Configure the stream to play completely through to the end before looping
		wav.loop_begin = 0
		if total_frames > 0:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_end = total_frames
		else:
			# Fallback if frame count cannot be derived: let AudioStreamPlayer play to the end
			# and allow _on_player_finished to loop it from 0.0
			wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
			wav.loop_end = 0

	# Ensure OGG, MP3 and any other stream formats loop from start to finish
	if "loop" in stream:
		stream.set("loop", true)
		if "loop_offset" in stream:
			stream.set("loop_offset", 0.0)
	elif stream.has_method("set_loop"):
		stream.call("set_loop", true)


## Retrieves the AudioStream resource for a given track, checking stream override, then disk file, then fallback
static func get_track_stream(track_key: String) -> AudioStream:
	if not tracks_config.has(track_key):
		return null

	var cfg: Dictionary = tracks_config[track_key]
	if cfg.get("stream", null) is AudioStream:
		return cfg["stream"] as AudioStream

	var path: String = str(cfg.get("path", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded_res = load(path)
		if loaded_res is AudioStream:
			cfg["stream"] = loaded_res
			return loaded_res as AudioStream

	return null


## Customizer API: Swap any stage bracket's music with a custom file path ("res://..." or user path)
static func set_track_path(track_key: String, file_path: String, volume_db: float = 0.0) -> bool:
	if not tracks_config.has(track_key):
		tracks_config[track_key] = {
			"title": "Custom %s" % track_key,
			"path": file_path,
			"volume_db": volume_db,
			"stream": null,
			"stages": "Custom Bracket %s" % track_key
		}
	else:
		tracks_config[track_key]["path"] = file_path
		tracks_config[track_key]["volume_db"] = volume_db
		tracks_config[track_key]["stream"] = null

	if not file_path.is_empty() and ResourceLoader.exists(file_path):
		var res = load(file_path)
		if res is AudioStream:
			tracks_config[track_key]["stream"] = res
			return true
	return false


## Customizer API: Swap any stage bracket's music directly with an AudioStream resource
static func set_track_stream(track_key: String, stream: AudioStream, volume_db: float = 0.0) -> void:
	if not tracks_config.has(track_key):
		tracks_config[track_key] = {
			"title": "Custom %s" % track_key,
			"path": "",
			"volume_db": volume_db,
			"stream": stream,
			"stages": "Custom Bracket %s" % track_key
		}
	else:
		tracks_config[track_key]["stream"] = stream
		tracks_config[track_key]["volume_db"] = volume_db


## Assigns a custom path or stream to a stage bracket ("1-4", "5", "6-9", etc.)
static func set_stage_track(bracket: String, path_or_stream: Variant, volume_db: float = 0.0) -> bool:
	if path_or_stream is AudioStream:
		set_track_stream(bracket, path_or_stream as AudioStream, volume_db)
		return true
	elif path_or_stream is String:
		return set_track_path(bracket, str(path_or_stream), volume_db)
	return false


## Returns the active track configuration dictionary
static func get_track_config(track_key: String) -> Dictionary:
	return tracks_config.get(track_key, {}).duplicate(true)


## Returns all available tracks
static func get_all_tracks() -> Dictionary:
	return tracks_config.duplicate(true)


## Returns the default stage music slots
static func get_default_stage_music_slots() -> Dictionary:
	return StageAudioDatabase.get_default_stage_music_slots()


## Returns the default sound effects slots
static func get_default_sound_slots() -> Dictionary:
	return StageAudioDatabase.get_default_sound_slots()


## Resets all tracks back to default configuration, synchronizing with StageAudioDatabase
static func reset_tracks() -> void:
	tracks_config = DEFAULT_MUSIC_TRACKS.duplicate(true)
	var stage_slots: Dictionary = StageAudioDatabase.get_default_stage_music_slots()
	for k in stage_slots.keys():
		tracks_config[k] = stage_slots[k].duplicate(true)


## Returns currently playing track key
func get_current_track_key() -> String:
	return active_track_key


## Applies music volume to the "Music" bus in AudioServer (0.0 to 1.0)
static func apply_music_volume(linear_vol: float) -> void:
	ensure_audio_buses()
	var bus_idx: int = AudioServer.get_bus_index("Music")
	if bus_idx < 0:
		return

	linear_vol = clampf(linear_vol, 0.0, 1.0)
	if linear_vol <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		var db_vol: float = linear_to_db(linear_vol)
		AudioServer.set_bus_volume_db(bus_idx, db_vol)


## Generates a procedural waveform backup stream if an audio file is ever missing
static func _generate_fallback_stream(track_key: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var base_freq: float = 293.66 # D4
	var sample_duration: float = 1.0
	match track_key:
		"menu":
			base_freq = 293.66
			sample_duration = 2.0
		"1-4", "ingame":
			base_freq = 220.0 # A3
			sample_duration = 1.0
		"5", "boss":
			base_freq = 196.0 # G3
			sample_duration = 0.8
		"6-9":
			base_freq = 246.94 # B3
			sample_duration = 1.0
		"10":
			base_freq = 130.81 # C3
			sample_duration = 0.8
		"11-14":
			base_freq = 164.81 # E3
			sample_duration = 1.0
		"15":
			base_freq = 174.61 # F3
			sample_duration = 0.8
		"16-19":
			base_freq = 246.94 # B3
			sample_duration = 1.0
		"20":
			base_freq = 146.83 # D3
			sample_duration = 0.8

	var sample_count: int = int(22050.0 * sample_duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	for i in range(sample_count):
		var t: float = float(i) / 22050.0
		# Gentle fallback tone (~0.25 amplitude)
		var tone: float = sin(TAU * base_freq * t) * 0.25
		var harm: float = sin(TAU * base_freq * 1.5 * t) * 0.12
		var val_f: float = clampf((tone + harm), -1.0, 1.0)
		var byte_val: int = int(clampi(int(round((val_f + 1.0) * 127.5)), 0, 255))
		data[i] = byte_val

	stream.data = data
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
