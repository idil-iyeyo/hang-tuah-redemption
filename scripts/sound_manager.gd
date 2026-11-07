class_name SoundManager
extends Node

## Dedicated Sound Effects Management Component for Space Shooter 2D
## Centralizes every sound effect in the game within a single structured Dictionary.
## Provides polyphonic audio pooling on the "SFX" bus, procedural waveform fallbacks,
## volume calibration, pitch variance, and dynamic runtime customization.

signal sound_played(sound_id: String)

const DEFAULT_SOUND_EFFECTS: Dictionary = {
	# --- UI & NAVIGATION ---
	"button_click": {
		"name": "Button Click",
		"category": "ui",
		"path": "res://assets/audio/sfx/button_click.wav",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.96, 1.04),
		"bus": "SFX",
		"stream": null,
		"description": "Standard UI button click and tab switch chime"
	},
	"play_start": {
		"name": "Game Start / Launch",
		"category": "ui",
		"path": "res://assets/audio/sfx/play_start.wav",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(1.0, 1.0),
		"bus": "SFX",
		"stream": null,
		"description": "Rising 3-tone arpeggio when starting game or unpausing"
	},
	"modal_chime": {
		"name": "Modal Open Chime",
		"category": "ui",
		"path": "res://assets/audio/sfx/modal_chime.wav",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.98, 1.02),
		"bus": "SFX",
		"stream": null,
		"description": "Gentle dual chime when opening Settings or Credits modal"
	},
	"level_complete": {
		"name": "Stage Victory Fanfare",
		"category": "ui",
		"path": "res://assets/audio/sfx/level_complete.wav",
		"volume_db": 1.0,
		"pitch": 1.0,
		"pitch_range": Vector2(1.0, 1.0),
		"bus": "SFX",
		"stream": null,
		"description": "Major 4-note ascending fanfare when stage is completed"
	},
	"purchase": {
		"name": "Upgrade Purchased",
		"category": "ui",
		"path": "res://assets/audio/sfx/purchase.wav",
		"volume_db": 0.5,
		"pitch": 1.0,
		"pitch_range": Vector2(0.97, 1.03),
		"bus": "SFX",
		"stream": null,
		"description": "Positive coin/gem chime when purchasing an upgrade"
	},

	# --- WAVE & STAGE ALERTS ---
	"wave_start": {
		"name": "Wave Start Alert",
		"category": "wave",
		"path": "res://assets/audio/sfx/wave_start.wav",
		"volume_db": 0.5,
		"pitch": 1.0,
		"pitch_range": Vector2(1.0, 1.0),
		"bus": "SFX",
		"stream": null,
		"description": "Tactical combat alert played when wave banner appears"
	},
	"wave_clear": {
		"name": "Wave Cleared Horn",
		"category": "wave",
		"path": "res://assets/audio/sfx/wave_clear.wav",
		"volume_db": 0.5,
		"pitch": 1.0,
		"pitch_range": Vector2(1.0, 1.0),
		"bus": "SFX",
		"stream": null,
		"description": "Ascending victory chord played when all enemies in wave are cleared"
	},
	"boss_warning": {
		"name": "Boss Approaching Siren",
		"category": "wave",
		"path": "res://assets/audio/sfx/boss_warning.wav",
		"volume_db": 1.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.98, 1.02),
		"bus": "SFX",
		"stream": null,
		"description": "Urgent pulsing war-siren when entering boss encounter"
	},

	# --- PLAYER & DEFENSE ---
	"player_hit": {
		"name": "Ship Hull Impact",
		"category": "player",
		"path": "res://assets/audio/sfx/player_hit.wav",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.93, 1.07),
		"bus": "SFX",
		"stream": null,
		"description": "Low-frequency crunch when player ship hull takes direct damage"
	},
	"shield_hit": {
		"name": "Shield Deflection",
		"category": "player",
		"path": "res://assets/audio/sfx/shield_hit.ogg",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.95, 1.05),
		"bus": "SFX",
		"stream": null,
		"description": "Resonant harmonic energy chime when shield absorbs damage"
	},
	"shield_recharge": {
		"name": "Shield Recharged",
		"category": "player",
		"path": "res://assets/audio/sfx/shield_hit.wav",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(1.0, 1.0),
		"bus": "SFX",
		"stream": null,
		"description": "High-tech hum when shields replenish"
	},
	"player_die": {
		"name": "Ship Destroyed",
		"category": "player",
		"path": "res://assets/audio/sfx/player_die.wav",
		"volume_db": 1.0,
		"pitch": 0.9,
		"pitch_range": Vector2(0.85, 0.95),
		"bus": "SFX",
		"stream": null,
		"description": "Heavy explosive detonation when player ship is lost"
	},
	"free_gun_equip": {
		"name": "Emergency Gun Equip",
		"category": "player",
		"path": "res://assets/audio/sfx/button_click.wav",
		"volume_db": 0.0,
		"pitch": 1.1,
		"pitch_range": Vector2(1.0, 1.1),
		"bus": "SFX",
		"stream": null,
		"description": "Mechanical weapon reload click when emergency blaster equips"
	},

	# --- WEAPONS / GUNS ---
	"laser_shoot": {
		"name": "Plasma / Blaster Shot",
		"category": "weapons",
		"path": "res://assets/audio/sfx/gun_sfx/Blaster-1.wav",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.95, 1.05),
		"bus": "SFX",
		"stream": null,
		"description": "Swift high-frequency plasma blaster bolt"
	},
	"cannon_shoot": {
		"name": "Heavy Cannon Shot",
		"category": "weapons",
		"path": "res://assets/audio/sfx/cannon_shoot.wav",
		"volume_db": 1.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.92, 1.05),
		"bus": "SFX",
		"stream": null,
		"description": "Deep explosive boom for Heavy Cannon"
	},
	"gatling_shoot": {
		"name": "Explosive Gatling Salvo",
		"category": "weapons",
		"path": "res://assets/audio/sfx/laser_shoot.wav",
		"volume_db": 0.0,
		"pitch": 1.35,
		"pitch_range": Vector2(1.25, 1.45),
		"bus": "SFX",
		"stream": null,
		"description": "High-tempo plasma salvo"
	},
	"laser_beam": {
		"name": "Quasar Laser Beam Hum",
		"category": "weapons",
		"path": "res://assets/audio/sfx/gun_sfx/laser3.wav",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.98, 1.02),
		"bus": "SFX",
		"stream": null,
		"description": "Continuous resonant beam hum for Tier 5 Quasar Laser"
	},

	# --- ENEMIES & COMBAT ---
	"enemy_hit": {
		"name": "Enemy Hit",
		"category": "combat",
		"path": "res://assets/audio/sfx/player_hit.wav",
		"volume_db": -0.5,
		"pitch": 1.2,
		"pitch_range": Vector2(1.1, 1.3),
		"bus": "SFX",
		"stream": null,
		"description": "Light impact squish/crunch when enemy is damaged"
	},
	"enemy_explode": {
		"name": "Enemy Destroyed",
		"category": "combat",
		"path": "res://assets/audio/sfx/enemy_explode.wav",
		"volume_db": 0.0,
		"pitch": 1.0,
		"pitch_range": Vector2(0.9, 1.1),
		"bus": "SFX",
		"stream": null,
		"description": "Pop-explosion when standard enemy or projectile is destroyed"
	},
	"heavy_explode": {
		"name": "Heavy Enemy Destroyed",
		"category": "combat",
		"path": "res://assets/audio/sfx/player_die.wav",
		"volume_db": 1.0,
		"pitch": 0.85,
		"pitch_range": Vector2(0.8, 0.9),
		"bus": "SFX",
		"stream": null,
		"description": "Heavy bass rumble when a tank or breeder explodes"
	},
	"boss_explode": {
		"name": "Boss Destroyed Climax",
		"category": "combat",
		"path": "res://assets/audio/sfx/player_die.wav",
		"volume_db": 2.0,
		"pitch": 0.75,
		"pitch_range": Vector2(0.7, 0.8),
		"bus": "SFX",
		"stream": null,
		"description": "Massive multi-stage explosive detonation for boss defeat"
	}
}

static var sfx_config: Dictionary = {}
static var active_instance: SoundManager = null

var pool_size: int = 12
var player_pool: Array[AudioStreamPlayer] = []
var next_pool_idx: int = 0


## Ensures the master sounds dictionary is populated before any access
static func _ensure_initialized() -> void:
	if sfx_config.is_empty():
		reset_all_sounds()


func _init() -> void:
	_ensure_initialized()


func _ready() -> void:
	active_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_pool()


func _init_pool() -> void:
	# Clean up any prior children in case of reload
	for child in get_children():
		if child is AudioStreamPlayer and child.name.begins_with("SFXPlayer_"):
			child.queue_free()
	player_pool.clear()

	for i in range(pool_size):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		player_pool.append(p)


## Normalizes sound ID strings and aliases to canonical keys
static func normalize_sound_id(raw_id: String) -> String:
	_ensure_initialized()
	var clean: String = raw_id.strip_edges().to_lower()
	match clean:
		"btn_click", "click", "button":
			return "button_click"
		"start", "start_game", "launch":
			return "play_start"
		"chime", "modal", "settings_open":
			return "modal_chime"
		"complete", "victory", "stage_clear":
			return "level_complete"
		"buy", "shop_purchase", "upgrade":
			return "purchase"
		"intro", "wave_intro", "start_wave":
			return "wave_start"
		"clear", "wave_cleared", "wave_won":
			return "wave_clear"
		"siren", "boss_alert", "warning":
			return "boss_warning"
		"hit", "hull_hit", "damage":
			return "player_hit"
		"shield", "shield_deflect", "shield_block":
			return "shield_hit"
		"die", "death", "game_over", "destroyed":
			return "player_die"
		"laser", "blaster", "shoot":
			return "laser_shoot"
		"cannon", "heavy_shot", "heavy_cannon":
			return "cannon_shoot"
		"gatling", "gatling_salvo":
			return "gatling_shoot"
		"beam", "quasar", "quasar_laser":
			return "laser_beam"
		"explode", "explosion":
			return "enemy_explode"
		_:
			return clean


## Primary Universal Playback Method:
## Can be called from anywhere in the codebase: SoundManager.play_sfx("button_click")
static func play_sfx(sound_id: String, explicit_pitch: float = -1.0, volume_offset_db: float = 0.0) -> AudioStreamPlayer:
	_ensure_initialized()
	var canonical_id: String = normalize_sound_id(sound_id)
	if not sfx_config.has(canonical_id):
		push_warning("SoundManager: Unknown sound ID '%s'" % sound_id)
		return null

	var stream: AudioStream = get_sound_stream(canonical_id)
	if stream == null:
		return null

	var cfg: Dictionary = sfx_config[canonical_id]
	var base_db: float = float(cfg.get("volume_db", -3.0))
	var final_db: float = base_db + volume_offset_db

	var final_pitch: float = 1.0
	if explicit_pitch > 0.0:
		final_pitch = explicit_pitch
	else:
		var p_range: Vector2 = cfg.get("pitch_range", Vector2(1.0, 1.0))
		final_pitch = randf_range(p_range.x, p_range.y) * float(cfg.get("pitch", 1.0))

	# If active instance is ready in tree, use the polyphonic pool
	if is_instance_valid(active_instance) and not active_instance.player_pool.is_empty():
		return active_instance._play_from_pool(canonical_id, stream, final_db, final_pitch)

	# Standalone fallback if active_instance is not yet attached to scene tree
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var temp_player: AudioStreamPlayer = AudioStreamPlayer.new()
		temp_player.bus = "SFX"
		temp_player.process_mode = Node.PROCESS_MODE_ALWAYS
		temp_player.stream = stream
		temp_player.volume_db = final_db
		temp_player.pitch_scale = final_pitch
		tree.root.add_child(temp_player)
		temp_player.finished.connect(temp_player.queue_free)
		temp_player.play()
		return temp_player

	return null


func _play_from_pool(sound_id: String, stream: AudioStream, volume_db: float, pitch: float) -> AudioStreamPlayer:
	# Look for an idle player
	var chosen_player: AudioStreamPlayer = null
	for p: AudioStreamPlayer in player_pool:
		if is_instance_valid(p) and not p.playing:
			chosen_player = p
			break

	# If all busy, round-robin reuse
	if chosen_player == null and not player_pool.is_empty():
		chosen_player = player_pool[next_pool_idx % player_pool.size()]
		next_pool_idx = (next_pool_idx + 1) % player_pool.size()

	if chosen_player != null:
		chosen_player.stream = stream
		chosen_player.volume_db = volume_db
		chosen_player.pitch_scale = pitch
		chosen_player.play(0.0)
		sound_played.emit(sound_id)
		return chosen_player

	return null


## Retrieves the AudioStream resource for a given sound ID (checks override, disk file, or procedural fallback)
static func get_sound_stream(sound_id: String) -> AudioStream:
	var canonical_id: String = normalize_sound_id(sound_id)
	if not sfx_config.has(canonical_id):
		return null

	var cfg: Dictionary = sfx_config[canonical_id]
	if cfg.get("stream", null) is AudioStream:
		return cfg["stream"] as AudioStream

	var path: String = str(cfg.get("path", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			cfg["stream"] = res
			return res as AudioStream

	# Fallback procedural synthesis
	var fallback_stream: AudioStreamWAV = _generate_procedural_sound(canonical_id)
	cfg["stream"] = fallback_stream
	return fallback_stream


## Assigns a custom audio file path to any sound ID
static func set_sound_path(sound_id: String, file_path: String, volume_db: float = 0.0) -> bool:
	var canonical_id: String = normalize_sound_id(sound_id)
	if not sfx_config.has(canonical_id):
		sfx_config[canonical_id] = {
			"name": "Custom %s" % canonical_id.capitalize(),
			"category": "custom",
			"path": file_path,
			"volume_db": volume_db,
			"pitch": 1.0,
			"pitch_range": Vector2(1.0, 1.0),
			"bus": "SFX",
			"stream": null
		}
	else:
		sfx_config[canonical_id]["path"] = file_path
		sfx_config[canonical_id]["volume_db"] = volume_db
		sfx_config[canonical_id]["stream"] = null

	if not file_path.is_empty() and ResourceLoader.exists(file_path):
		var res = load(file_path)
		if res is AudioStream:
			sfx_config[canonical_id]["stream"] = res
			return true
	return false


## Assigns an AudioStream resource directly to any sound ID
static func set_sound_stream(sound_id: String, stream: AudioStream, volume_db: float = 0.0) -> void:
	var canonical_id: String = normalize_sound_id(sound_id)
	if not sfx_config.has(canonical_id):
		sfx_config[canonical_id] = {
			"name": "Custom %s" % canonical_id.capitalize(),
			"category": "custom",
			"path": "",
			"volume_db": volume_db,
			"pitch": 1.0,
			"pitch_range": Vector2(1.0, 1.0),
			"bus": "SFX",
			"stream": stream
		}
	else:
		sfx_config[canonical_id]["stream"] = stream
		sfx_config[canonical_id]["volume_db"] = volume_db


## Sets volume_db for a specific sound ID
static func set_sound_volume(sound_id: String, volume_db: float) -> void:
	var canonical_id: String = normalize_sound_id(sound_id)
	if sfx_config.has(canonical_id):
		sfx_config[canonical_id]["volume_db"] = volume_db


## Returns a copy of the configuration dictionary for a given sound ID
static func get_sound_config(sound_id: String) -> Dictionary:
	var canonical_id: String = normalize_sound_id(sound_id)
	return sfx_config.get(canonical_id, {}).duplicate(true)


## Returns all sound effects configurations
static func get_all_sounds() -> Dictionary:
	return sfx_config.duplicate(true)


## Retrieves all sound configs for a specific category ("ui", "wave", "player", "weapons", "combat")
static func get_sounds_by_category(category: String) -> Dictionary:
	var results: Dictionary = {}
	for k: String in sfx_config.keys():
		if sfx_config[k].get("category", "") == category:
			results[k] = sfx_config[k].duplicate(true)
	return results


## Resets a specific sound back to default configuration
static func reset_sound(sound_id: String) -> void:
	var canonical_id: String = normalize_sound_id(sound_id)
	if DEFAULT_SOUND_EFFECTS.has(canonical_id):
		sfx_config[canonical_id] = DEFAULT_SOUND_EFFECTS[canonical_id].duplicate(true)


## Resets all sounds back to default configuration
static func reset_all_sounds() -> void:
	sfx_config = DEFAULT_SOUND_EFFECTS.duplicate(true)


## Guarantees that the "SFX" audio bus exists and routes to Master
static func ensure_audio_buses() -> void:
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx < 0:
		master_idx = 0

	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		sfx_idx = AudioServer.bus_count
		AudioServer.add_bus(sfx_idx)
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")


## Applies SFX volume to the "SFX" bus in AudioServer (0.0 to 1.0)
static func apply_sfx_volume(linear_vol: float) -> void:
	ensure_audio_buses()
	var bus_idx: int = AudioServer.get_bus_index("SFX")
	if bus_idx < 0:
		return

	linear_vol = clampf(linear_vol, 0.0, 1.0)
	if linear_vol <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		var db_vol: float = linear_to_db(linear_vol)
		AudioServer.set_bus_volume_db(bus_idx, db_vol)


# -----------------------------------------------------------------------------
# PROCEDURAL WAVEFORM FALLBACK SYNTHESIZER
# Guarantees that audio never goes silent even if external files are missing
# -----------------------------------------------------------------------------

static func _generate_procedural_sound(sound_id: String) -> AudioStreamWAV:
	match sound_id:
		"button_click":
			return _gen_tone_sequence([850.0, 1100.0], 0.085, 68.0)
		"play_start":
			return _gen_tone_sequence([440.0, 660.0, 880.0], 0.22, 50.0)
		"modal_chime":
			return _gen_tone_sequence([523.0, 659.0], 0.14, 45.0)
		"level_complete":
			return _gen_tone_sequence([523.0, 659.0, 784.0, 1046.0], 0.36, 50.0)
		"purchase":
			return _gen_tone_sequence([523.0, 659.0, 784.0], 0.24, 48.0)
		"wave_start":
			return _gen_tone_sequence([330.0, 440.0], 0.22, 48.0)
		"wave_clear":
			return _gen_tone_sequence([440.0, 554.0, 659.0], 0.32, 48.0)
		"boss_warning":
			return _gen_siren(300.0, 500.0, 0.45, 52.0)
		"player_hit":
			return _gen_crunch(170.0, 45.0, 0.16, 55.0)
		"shield_hit", "shield_recharge":
			return _gen_resonance(440.0, 880.0, 0.20, 50.0)
		"player_die", "heavy_explode", "boss_explode":
			return _gen_explosion(0.40, 60.0)
		"laser_shoot", "gatling_shoot":
			return _gen_laser_bolt(950.0, 180.0, 0.12, 50.0)
		"cannon_shoot":
			return _gen_cannon_boom(280.0, 35.0, 0.28, 55.0)
		"laser_beam":
			return _gen_beam_hum(22050, 0.22)
		_:
			return _gen_tone_sequence([440.0], 0.1, 40.0)


static func _gen_tone_sequence(frequencies: Array[float], duration: float, amplitude: float = 48.0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	var note_count: int = frequencies.size()

	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var note_idx: int = clampi(int(progress * float(note_count)), 0, note_count - 1)
		var freq: float = frequencies[note_idx]

		phase += freq / 22050.0
		var tone: float = sin(phase * TAU)
		var env: float = pow(1.0 - progress, 1.3)
		var sample_val: int = clampi(int(128.0 + tone * env * amplitude), 0, 255)
		data[i] = sample_val

	stream.data = data
	return stream


static func _gen_siren(start_f: float, end_f: float, duration: float, amplitude: float = 50.0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / 22050.0
		var freq: float = start_f + (end_f - start_f) * (0.5 + 0.5 * sin(TAU * 4.0 * t))
		phase += freq / 22050.0
		var env: float = min(1.0, t / 0.05) * (1.0 - (t / duration))
		var tone: float = sin(phase * TAU) * env * amplitude
		data[i] = clampi(int(128.0 + tone), 0, 255)

	stream.data = data
	return stream


static func _gen_crunch(start_f: float, end_f: float, duration: float, amplitude: float = 55.0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var freq: float = lerpf(start_f, end_f, progress)
		phase += freq / 22050.0
		var wave_val: float = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		var noise: float = randf_range(-1.0, 1.0)
		var mixed: float = wave_val * 0.6 + noise * 0.4
		var env: float = pow(1.0 - progress, 2.2)
		data[i] = clampi(int(128.0 + mixed * env * amplitude), 0, 255)

	stream.data = data
	return stream


static func _gen_resonance(start_f: float, end_f: float, duration: float, amplitude: float = 50.0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var freq: float = lerpf(start_f, end_f, progress)
		phase += freq / 22050.0
		var wave_val: float = sin(phase * TAU) * 0.7 + sin(phase * TAU * 1.5) * 0.3
		var env: float = sin(progress * PI)
		data[i] = clampi(int(128.0 + wave_val * env * amplitude), 0, 255)

	stream.data = data
	return stream


static func _gen_explosion(duration: float, amplitude: float = 60.0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / 22050.0
		var freq: float = 140.0 * exp(-t * 12.0) + 30.0
		phase += freq / 22050.0
		var sub: float = sin(phase * TAU)
		var noise: float = randf_range(-1.0, 1.0)
		var env: float = exp(-t * 7.0)
		data[i] = clampi(int(128.0 + (sub * 0.5 + noise * 0.5) * env * amplitude), 0, 255)

	stream.data = data
	return stream


static func _gen_laser_bolt(start_f: float, end_f: float, duration: float, amplitude: float = 50.0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var freq: float = lerpf(start_f, end_f, progress)
		phase += freq / 22050.0
		var env: float = exp(-progress * 5.0)
		data[i] = clampi(int(128.0 + sin(phase * TAU) * env * amplitude), 0, 255)

	stream.data = data
	return stream


static func _gen_cannon_boom(start_f: float, end_f: float, duration: float, amplitude: float = 55.0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var freq: float = lerpf(start_f, end_f, progress)
		phase += freq / 22050.0
		var env: float = exp(-progress * 4.5)
		var punch: float = sin(phase * TAU) * 0.7 + randf_range(-0.3, 0.3) * 0.3
		data[i] = clampi(int(128.0 + punch * env * amplitude), 0, 255)

	stream.data = data
	return stream


static func _gen_beam_hum(mix_rate: int, duration: float) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var sample_count: int = int(float(mix_rate) * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var f1: float = 120.0
		var f2: float = 240.0
		var f3: float = 480.0
		var s1: float = sin(TAU * f1 * t) * 0.4
		var s2: float = sin(TAU * f2 * t) * 0.25
		var s3: float = sin(TAU * f3 * t) * 0.15
		var noise: float = randf_range(-0.06, 0.06)
		var val_f: float = clampf(s1 + s2 + s3 + noise, -1.0, 1.0)
		data[i] = int(clampi(int(round((val_f + 1.0) * 127.5)), 0, 255))

	stream.data = data
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
