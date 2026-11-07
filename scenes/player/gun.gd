class_name Gun
extends Node2D

## Modular Player Gun Component
## Handles weapon configurations, firing logic, projectile spawning, audio, and barrel visual animations.
##
## All weapon statistics are managed through the centralized GUN_CONFIGS table below.
## Stats can be modified at design-time or at runtime via set_stat() without altering any player or combat logic.

signal gun_fired(level: int, bolt: Area2D)
signal gun_upgraded(new_level: int)
signal gun_level_changed(new_level: int)
signal stat_changed(level: int, stat_name: String, new_val: Variant)

# Visual Alignment Constants
const SCALE_BARREL_STANDARD: Vector2 = Vector2(2.0, 2.0)
const SCALE_CANNON_STANDARD: Vector2 = Vector2(5.0, 5.0)

const POS_BARREL_CENTER: Vector2 = Vector2(7.0, 3.0)
const POS_BARREL_TOP: Vector2 = Vector2(-8.0, -7.0)
const POS_BARREL_BOTTOM: Vector2 = Vector2(-8.0, 13.0)
const POS_CANNON: Vector2 = Vector2(17.0, 10.0)

# Centralized Weapon Configuration Database
# Modify stats here to easily rebalance any gun tier!
const DEFAULT_CONFIGS: Dictionary = {
	0: {
		"name": "Starter Blaster", # "Emergency Blaster"
		"damage": 3,
		"pierce": 1,
		"cooldown": 0.48,
		"speed": 750.0,
		"muzzle_offset": Vector2(28.0, 0.0),
		"is_emergency": true,
		"is_cannon": false,
		"is_gatling": false,
		"is_laser": false,
		"is_alternating": false,
		"sound_type": "laser",
		"sound_pitch": 1.0,
		"barrel_modulate": Color(1.0, 0.75, 0.2), # Amber
		"active_barrels": ["center"],
	},
	1: {
		"name": "Plasma Blaster",
		"damage": 3,
		"pierce": 2,
		"cooldown": 0.35,
		"speed": 950.0,
		"muzzle_offset": Vector2(28.0, 0.0),
		"is_emergency": false,
		"is_cannon": false,
		"is_gatling": false,
		"is_laser": false,
		"is_alternating": false,
		"sound_type": "laser",
		"sound_pitch": 1.0,
		"barrel_modulate": Color(0.2, 0.9, 1.0), # Cyan
		#"active_barrels": ["center"],
	},
	2: {
		"name": "Dual Blaster",
		"damage": 5,
		"pierce": 2,
		"cooldown": 0.22, # Rapid fire rate (faster than Lv 1, slower than gatling)
		"speed": 950.0,
		"muzzle_offset": Vector2(28.0, 0.0),
		"alternating_y_offset": 12.0,
		"is_emergency": false,
		"is_cannon": false,
		"is_gatling": false,
		"is_laser": false,
		"is_alternating": true,
		"sound_type": "laser",
		"sound_pitch": 1.0,
		"barrel_modulate": Color(1.0, 0.85, 0.3), # Gold
		#"active_barrels": ["top", "bottom"],
	},
	3: {
		"name": "Heavy Cannon",
		"damage": 8, # Heavy shell damage
		"pierce": 5, # Pierces through multiple enemies and enemy projectiles
		"cooldown": 0.65, # Heavy cannon cadence
		"speed": 800.0,
		"muzzle_offset": Vector2(37.0, 0.0),
		"is_emergency": false,
		"is_cannon": true,
		"is_gatling": false,
		"is_laser": false,
		"is_alternating": false,
		"sound_type": "cannon",
		"sound_pitch": 1.0,
		"barrel_modulate": Color(1.0, 1.0, 1.0), # Crisp white cannon
		#"active_barrels": ["cannon"],
	},
	4: {
		"name": "Explosive Gatling",
		"damage": 2,
		"pierce": 3,
		"cooldown": 0.12, # Very high rate of fire
		"speed": 1150.0,
		"muzzle_offset": Vector2(32.0, 0.0),
		"is_emergency": false,
		"is_cannon": false,
		"is_gatling": true,
		"is_laser": false,
		"is_alternating": false,
		"sound_type": "laser",
		"sound_pitch_range": Vector2(1.25, 1.45),
		"barrel_modulate": Color(1.0, 0.45, 0.2), # Blazing Gatling orange
		#"active_barrels": ["center", "top", "bottom"],
	},
	5: {
		"name": "Quasar Laser",
		"damage": 2.5,
		"pierce": 5, # Laser pierce targets: 1 = stops at 1st target, 2 = pierces 1 and hits 2nd, -1 or 999 = infinite
		"cooldown": 0.055, # Continuous beam fire rate
		"speed": 2600.0,
		"muzzle_offset": Vector2(42.0, 0.0),
		"beam_scale": null,
		"is_emergency": false,
		"is_cannon": false,
		"is_gatling": false,
		"is_laser": true,
		"is_alternating": false,
		"sound_type": "laser_beam",
		"sound_pitch_range": Vector2(1.7, 1.95),
		"barrel_modulate": Color(1.0, 0.25, 0.4), # Laser crimson glow
		#"active_barrels": ["cannon", "top", "bottom"],
	},
}

# ==============================================================================
# GUN SOUNDS CUSTOMIZATION DICTIONARY
# Easily change or replace gun sounds across all weapon tiers with your own audio files!
# Supports audio files (.wav, .ogg, .mp3) or direct AudioStream resources.
# If empty or not found, falls back automatically to procedural built-in audio.
# ==============================================================================
const DEFAULT_GUN_SOUNDS: Dictionary = {
	0: {
		"name": "Starter Blaster", # "Emergency Blaster"
		"sound_path": "res://assets/audio/sfx/gun_sfx/Blaster-1.wav",            # e.g. "res://assets/audio/guns/emergency_blaster.wav"
		"stream": null,              # AudioStream resource override
		"pitch": 1.0,
		"pitch_range": Vector2(0.95, 1.05),
		"volume_db": 0.0,
	},
	1: {
		"name": "Plasma Blaster",
		"sound_path": "res://assets/audio/sfx/gun_sfx/Blaster-1.wav",            # e.g. "res://assets/audio/guns/plasma_blaster.wav"
		"stream": null,
		"pitch": 1.0,
		"pitch_range": Vector2(0.95, 1.05),
		"volume_db": 0.0,
	},
	2: {
		"name": "Dual Blaster",
		"sound_path": "res://assets/audio/sfx/gun_sfx/Blaster-1.wav",            # e.g. "res://assets/audio/guns/dual_blaster.wav"
		"stream": null,
		"pitch": 1.0,
		"pitch_range": Vector2(0.95, 1.05),
		"volume_db": 0.0,
	},
	3: {
		"name": "Heavy Cannon",
		"sound_path": "",            # e.g. "res://assets/audio/guns/heavy_cannon.wav"
		"stream": null,
		"pitch": 1.0,
		"pitch_range": Vector2(0.95, 1.05),
		"volume_db": 1.0,
	},
	4: {
		"name": "Explosive Gatling",
		"sound_path": "res://assets/audio/sfx/gun_sfx/Blaster-1.wav",            # e.g. "res://assets/audio/guns/explosive_gatling.wav"
		"stream": null,
		"pitch": 1.35,
		"pitch_range": Vector2(1.25, 1.45),
		"volume_db": 0.0,
	},
	5: {
		"name": "Quasar Laser",
		"sound_path": "res://assets/audio/sfx/gun_sfx/laser3.wav",            # e.g. "res://assets/audio/guns/quasar_laser.wav"
		"stream": null,
		"pitch": 1.0,
		"pitch_range": Vector2(0.98, 1.02),
		"volume_db": 1.0,
	},
}

# Exported Properties
@export var projectile_scene: PackedScene = preload("res://scenes/player/player_projectile.tscn")

@export_group("Gun State")
@export var gun_level: int = 0:
	set(val):
		var old_val: int = gun_level
		gun_level = val
		if old_val != val:
			gun_level_changed.emit(val)
		update_visual()

@export var has_emergency_gun: bool = false:
	set(val):
		has_emergency_gun = val
		update_visual()

var cooldown_timer: float = 0.0
var level2_alt_top: bool = false
var active_laser_beam: Area2D = null

# Runtime configurable copy of configs (enables dynamic tweaks during gameplay)
var runtime_configs: Dictionary = {}
var custom_gun_sounds: Dictionary = {}

# Node References
@onready var gun_mount: Node2D = get_node_or_null("GunMount")
@onready var gun_sprite_center: Sprite2D = get_node_or_null("GunMount/GunSpriteCenter")
@onready var gun_sprite_top: Sprite2D = get_node_or_null("GunMount/GunSpriteTop")
@onready var gun_sprite_bottom: Sprite2D = get_node_or_null("GunMount/GunSpriteBottom")
@onready var gun_sprite_cannon: Sprite2D = get_node_or_null("GunMount/GunSpriteCannon")

@onready var shoot_sound_player: AudioStreamPlayer = get_node_or_null("ShootSoundPlayer")
@onready var cannon_sound_player: AudioStreamPlayer = get_node_or_null("CannonSoundPlayer")
@onready var laser_sound_player: AudioStreamPlayer = get_node_or_null("LaserSoundPlayer")
@onready var custom_sound_player: AudioStreamPlayer = get_node_or_null("CustomSoundPlayer")


func _ready() -> void:
	_init_runtime_configs()
	_init_sounds()
	update_visual()


func _init_runtime_configs() -> void:
	runtime_configs = DEFAULT_CONFIGS.duplicate(true)
	custom_gun_sounds = DEFAULT_GUN_SOUNDS.duplicate(true)


func process_cooldown(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	# Keep continuous laser ray anchored seamlessly to ship muzzle during movement
	if is_instance_valid(active_laser_beam):
		if active_laser_beam.has_method("update_laser_origin"):
			var cfg: Dictionary = get_active_config()
			var base_origin: Vector2 = global_position
			var muzzle_offset: Vector2 = cfg.get("muzzle_offset", Vector2(42.0, 0.0))
			active_laser_beam.update_laser_origin(base_origin + muzzle_offset)


func can_shoot() -> bool:
	return cooldown_timer <= 0.0


## Fire the active weapon. Spawns projectile(s) into parent_node and resets cooldown.
func shoot(parent_node: Node = null, origin_pos: Vector2 = Vector2.ZERO, dir: Vector2 = Vector2.RIGHT) -> Area2D:
	if not can_shoot() or projectile_scene == null:
		return null

	var target_parent: Node = parent_node
	if target_parent == null:
		target_parent = get_parent()
		if target_parent and target_parent.get_parent():
			target_parent = target_parent.get_parent()

	if target_parent == null:
		return null

	var cfg: Dictionary = get_active_config()
	if cfg.is_empty():
		return null

	# Set fire rate cooldown
	cooldown_timer = float(cfg.get("cooldown", 0.35))

	# Compute spawn position
	var base_origin: Vector2 = origin_pos if origin_pos != Vector2.ZERO else global_position
	var muzzle_offset: Vector2 = cfg.get("muzzle_offset", Vector2(28.0, 0.0))
	var spawn_pos: Vector2 = base_origin + muzzle_offset

	# Handle alternating dual barrels (Level 2)
	if bool(cfg.get("is_alternating", false)):
		var y_offset: float = float(cfg.get("alternating_y_offset", 12.0))
		spawn_pos.y += -y_offset if level2_alt_top else y_offset
		level2_alt_top = not level2_alt_top

	var bolt: Area2D = null
	var is_laser_tier: bool = bool(cfg.get("is_laser", false))

	if is_laser_tier:
		var cfg_scale = cfg.get("beam_scale", null)
		var custom_scale: float = float(cfg_scale) if (cfg_scale != null and float(cfg_scale) > 0.0) else -1.0
		var custom_pierce: int = int(cfg.get("pierce", 2))

		# Level 5 Quasar Laser: Continuous Ray with zero gaps
		if is_instance_valid(active_laser_beam) and active_laser_beam.has_method("sustain"):
			active_laser_beam.sustain(spawn_pos, int(cfg.get("damage", 7)), custom_scale, custom_pierce)
			bolt = active_laser_beam
		else:
			bolt = spawn_blaster_bolt(
				spawn_pos,
				dir,
				int(cfg.get("damage", 7)),
				custom_pierce,
				float(cfg.get("speed", 2600.0)),
				false,
				false,
				false,
				true,
				target_parent
			)
			active_laser_beam = bolt
			if bolt and bolt.has_method("set_source_tracking"):
				bolt.set_source_tracking(self, muzzle_offset)
			if bolt and bolt.has_method("set_beam_scale") and custom_scale > 0.0:
				bolt.set_beam_scale(custom_scale)
			if bolt and bolt.has_method("set_laser_pierce"):
				bolt.set_laser_pierce(custom_pierce)
	else:
		# Discrete Projectile Tiers (0, 1, 2, 3, 4)
		bolt = spawn_blaster_bolt(
			spawn_pos,
			dir,
			int(cfg.get("damage", 1)),
			int(cfg.get("pierce", 1)),
			float(cfg.get("speed", 950.0)),
			bool(cfg.get("is_cannon", false)),
			bool(cfg.get("is_emergency", false)),
			bool(cfg.get("is_gatling", false)),
			false,
			target_parent
		)

	# Play appropriate weapon audio
	_play_weapon_sound(cfg)

	gun_fired.emit(gun_level, bolt)
	return bolt


## Spawns a configured projectile bolt into the scene tree
func spawn_blaster_bolt(
	spawn_pos: Vector2,
	dir: Vector2,
	dmg: int,
	prc: int,
	spd: float,
	is_cannon: bool = false,
	is_emergency: bool = false,
	is_gatling: bool = false,
	is_laser: bool = false,
	parent_override: Node = null
) -> Area2D:
	if projectile_scene == null:
		return null

	var target_parent: Node = parent_override
	if target_parent == null:
		target_parent = get_parent()

	if target_parent == null:
		return null

	var bolt: Area2D = projectile_scene.instantiate() as Area2D
	if bolt:
		bolt.position = spawn_pos
		bolt.set("direction", dir)
		# Add to target parent before setup_projectile to ensure is_inside_tree() is true
		target_parent.add_child(bolt)
		if bolt.has_method("setup_projectile"):
			bolt.setup_projectile(dmg, prc, spd, is_cannon, is_emergency, is_gatling, is_laser)
		elif is_emergency and bolt.has_method("set_emergency_style"):
			bolt.set_emergency_style()

	return bolt


func _play_weapon_sound(cfg: Dictionary) -> void:
	var active_lvl: int = clampi(gun_level, 0, 5)
	var sound_cfg: Dictionary = get_gun_sound_config(active_lvl)

	# 1. Custom User Audio Override
	var custom_stream: AudioStream = sound_cfg.get("stream", null) as AudioStream
	var custom_path: String = String(sound_cfg.get("sound_path", ""))
	if custom_stream == null and not custom_path.is_empty() and ResourceLoader.exists(custom_path):
		custom_stream = load(custom_path) as AudioStream
		if custom_gun_sounds.has(active_lvl):
			custom_gun_sounds[active_lvl]["stream"] = custom_stream

	if custom_stream != null:
		if custom_sound_player == null:
			custom_sound_player = get_node_or_null("CustomSoundPlayer")
			if custom_sound_player == null:
				custom_sound_player = AudioStreamPlayer.new()
				custom_sound_player.name = "CustomSoundPlayer"
				add_child(custom_sound_player)
		custom_sound_player.stream = custom_stream
		custom_sound_player.volume_db = float(sound_cfg.get("volume_db", 0.0))
		var custom_pitch: float = float(sound_cfg.get("pitch", 1.0))
		if sound_cfg.has("pitch_range"):
			var p_range: Vector2 = sound_cfg.get("pitch_range", Vector2(1.0, 1.0))
			custom_sound_player.pitch_scale = randf_range(p_range.x, p_range.y) * custom_pitch
		else:
			custom_sound_player.pitch_scale = custom_pitch
		custom_sound_player.play()
		return

	# 2. Built-in Procedural Audio Fallback
	var sound_type: String = String(cfg.get("sound_type", "laser"))
	var is_laser_tier: bool = bool(cfg.get("is_laser", false))

	if sound_type == "cannon" and cannon_sound_player:
		cannon_sound_player.pitch_scale = float(cfg.get("sound_pitch", 1.0))
		cannon_sound_player.play()
	elif is_laser_tier or sound_type == "laser_beam":
		if laser_sound_player:
			if not laser_sound_player.playing:
				laser_sound_player.pitch_scale = randf_range(0.98, 1.02)
				laser_sound_player.play()
		elif shoot_sound_player:
			shoot_sound_player.pitch_scale = randf_range(1.65, 1.85)
			shoot_sound_player.play()
	elif shoot_sound_player:
		if cfg.has("sound_pitch_range"):
			var pitch_range: Vector2 = cfg.get("sound_pitch_range", Vector2(1.0, 1.0))
			shoot_sound_player.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
		else:
			shoot_sound_player.pitch_scale = float(cfg.get("sound_pitch", 1.0))
		shoot_sound_player.play()


## Updates visual appearance of gun barrels based on current weapon tier
func update_visual() -> void:
	if not gun_mount:
		return

	# Reset all gun sprites to default positions, standard uniform scales, and hidden visibility
	if gun_sprite_center:
		gun_sprite_center.visible = false
		gun_sprite_center.scale = SCALE_BARREL_STANDARD
		gun_sprite_center.position = POS_BARREL_CENTER
		gun_sprite_center.modulate = Color.WHITE

	if gun_sprite_top:
		gun_sprite_top.visible = false
		gun_sprite_top.scale = SCALE_BARREL_STANDARD
		gun_sprite_top.position = POS_BARREL_TOP
		gun_sprite_top.modulate = Color.WHITE

	if gun_sprite_bottom:
		gun_sprite_bottom.visible = false
		gun_sprite_bottom.scale = SCALE_BARREL_STANDARD
		gun_sprite_bottom.position = POS_BARREL_BOTTOM
		gun_sprite_bottom.modulate = Color.WHITE

	if gun_sprite_cannon:
		gun_sprite_cannon.visible = false
		gun_sprite_cannon.scale = SCALE_CANNON_STANDARD
		gun_sprite_cannon.position = POS_CANNON
		gun_sprite_cannon.modulate = Color.WHITE

	var cfg: Dictionary = get_active_config()
	if cfg.is_empty():
		return

	# If transitioning away from laser tier, clean up any active continuous laser beam
	if not bool(cfg.get("is_laser", false)) and is_instance_valid(active_laser_beam):
		active_laser_beam.queue_free()
		active_laser_beam = null

	var active_barrels: Array = cfg.get("active_barrels", [])
	var mod_color: Color = cfg.get("barrel_modulate", Color.WHITE)

	for barrel_id in active_barrels:
		match String(barrel_id):
			"center":
				if gun_sprite_center:
					gun_sprite_center.visible = true
					gun_sprite_center.modulate = mod_color
			"top":
				if gun_sprite_top:
					gun_sprite_top.visible = true
					gun_sprite_top.modulate = mod_color
			"bottom":
				if gun_sprite_bottom:
					gun_sprite_bottom.visible = true
					gun_sprite_bottom.modulate = mod_color
			"cannon":
				if gun_sprite_cannon:
					gun_sprite_cannon.visible = true
					gun_sprite_cannon.modulate = mod_color


## Upgrades the gun to the next tier up to max level (5)
func upgrade_gun() -> bool:
	if gun_level < 5:
		gun_level += 1
		has_emergency_gun = false
		update_visual()
		gun_upgraded.emit(gun_level)
		return true
	return false


## Equips the free emergency gun if player has no active gun
func equip_free_emergency_gun() -> void:
	if gun_level <= 0:
		has_emergency_gun = true
		update_visual()


func set_gun_level(new_level: int) -> void:
	gun_level = new_level
	if gun_level > 0:
		has_emergency_gun = false
	update_visual()


## Returns configuration dictionary for currently equipped weapon
func get_active_config() -> Dictionary:
	var active_lvl: int = clampi(gun_level, 0, 5)
	return get_gun_config(active_lvl)


## Returns configuration dictionary for a given level
func get_gun_config(level: int) -> Dictionary:
	if runtime_configs.has(level):
		return runtime_configs[level]
	if DEFAULT_CONFIGS.has(level):
		return DEFAULT_CONFIGS[level]
	return {}


## Gets a specific stat value for a given level (or active level if level == -1)
func get_stat(stat_name: String, default_val = null, level: int = -1):
	var cfg: Dictionary = get_gun_config(level) if level >= 0 else get_active_config()
	return cfg.get(stat_name, default_val)


## Sets a specific stat value for a level, making runtime rebalancing effortless
func set_stat(stat_name: String, value, level: int = -1) -> void:
	var target_lvl: int = level if level >= 0 else gun_level
	if not runtime_configs.has(target_lvl):
		runtime_configs[target_lvl] = DEFAULT_CONFIGS.get(target_lvl, {}).duplicate(true)

	runtime_configs[target_lvl][stat_name] = value
	stat_changed.emit(target_lvl, stat_name, value)
	if target_lvl == gun_level:
		update_visual()


## Easily set or override a custom gun sound path for any weapon tier (0-5)
func set_gun_sound_path(level: int, file_path: String, pitch: float = 1.0, volume_db: float = 0.0) -> bool:
	if not custom_gun_sounds.has(level):
		custom_gun_sounds[level] = DEFAULT_GUN_SOUNDS.get(level, {}).duplicate(true)
	custom_gun_sounds[level]["sound_path"] = file_path
	custom_gun_sounds[level]["pitch"] = pitch
	custom_gun_sounds[level]["volume_db"] = volume_db
	if not file_path.is_empty() and ResourceLoader.exists(file_path):
		var res: AudioStream = load(file_path) as AudioStream
		if res:
			custom_gun_sounds[level]["stream"] = res
			return true
	return false


## Easily set an AudioStream resource directly for any weapon tier (0-5)
func set_gun_sound_stream(level: int, stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not custom_gun_sounds.has(level):
		custom_gun_sounds[level] = DEFAULT_GUN_SOUNDS.get(level, {}).duplicate(true)
	custom_gun_sounds[level]["stream"] = stream
	custom_gun_sounds[level]["pitch"] = pitch
	custom_gun_sounds[level]["volume_db"] = volume_db


## Get the sound configuration dictionary for a given level (or currently active weapon tier)
func get_gun_sound_config(level: int = -1) -> Dictionary:
	var target_lvl: int = level if level >= 0 else clampi(gun_level, 0, 5)
	if custom_gun_sounds.has(target_lvl):
		return custom_gun_sounds[target_lvl]
	if DEFAULT_GUN_SOUNDS.has(target_lvl):
		return DEFAULT_GUN_SOUNDS[target_lvl]
	return {}


## Reset custom gun sounds back to default configuration
func reset_gun_sounds() -> void:
	custom_gun_sounds = DEFAULT_GUN_SOUNDS.duplicate(true)


# Procedural Sound Generators (Completely self-contained audio)
func _init_sounds() -> void:
	if shoot_sound_player:
		shoot_sound_player.bus = "SFX"
		if shoot_sound_player.stream == null:
			shoot_sound_player.stream = _generate_laser_audio()
	if cannon_sound_player:
		cannon_sound_player.bus = "SFX"
		if cannon_sound_player.stream == null:
			cannon_sound_player.stream = _generate_cannon_audio()
	if laser_sound_player == null:
		laser_sound_player = get_node_or_null("LaserSoundPlayer")
		if laser_sound_player == null:
			laser_sound_player = AudioStreamPlayer.new()
			laser_sound_player.name = "LaserSoundPlayer"
			laser_sound_player.bus = "SFX"
			add_child(laser_sound_player)
	if laser_sound_player:
		laser_sound_player.bus = "SFX"
		if laser_sound_player.stream == null:
			laser_sound_player.stream = _generate_laser_beam_audio()
	if custom_sound_player == null:
		custom_sound_player = get_node_or_null("CustomSoundPlayer")
		if custom_sound_player == null:
			custom_sound_player = AudioStreamPlayer.new()
			custom_sound_player.name = "CustomSoundPlayer"
			custom_sound_player.bus = "SFX"
			add_child(custom_sound_player)
	if custom_sound_player:
		custom_sound_player.bus = "SFX"


func _generate_laser_beam_audio() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	# 0.22s looping energy beam hum
	var sample_count: int = int(22050.0 * 0.22)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase1: float = 0.0
	var phase2: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		phase1 += 440.0 / 22050.0
		phase2 += 880.0 / 22050.0

		var wave1: float = sin(phase1 * TAU)
		var wave2: float = sin(phase2 * TAU) * 0.35
		var buzz: float = randf_range(-0.15, 0.15)
		var combined: float = (wave1 + wave2 + buzz) * 0.75

		var edge_env: float = 1.0
		if progress < 0.05:
			edge_env = progress / 0.05
		elif progress > 0.95:
			edge_env = (1.0 - progress) / 0.05

		var sample_val: int = clampi(int(128.0 + combined * edge_env * 85.0), 0, 255)
		data[i] = sample_val

	stream.data = data
	return stream


func _generate_laser_audio() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * 0.12)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var freq: float = lerpf(880.0, 240.0, progress)
		phase += freq / 22050.0

		var wave: float = sin(phase * TAU)
		var env: float = pow(1.0 - progress, 1.8)
		var sample_val: int = clampi(int(128.0 + wave * env * 95.0), 0, 255)
		data[i] = sample_val

	stream.data = data
	return stream


func _generate_cannon_audio() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var sample_count: int = int(22050.0 * 0.28)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)

	var phase: float = 0.0
	for i in range(sample_count):
		var progress: float = float(i) / float(sample_count)
		var freq: float = lerpf(160.0, 35.0, progress)
		phase += freq / 22050.0

		var sine_wave: float = sin(phase * TAU)
		var punch_noise: float = randf_range(-1.0, 1.0) * pow(1.0 - progress, 4.0)
		var mixed: float = sine_wave * 0.75 + punch_noise * 0.25

		var env: float = pow(1.0 - progress, 1.6)
		var sample_val: int = clampi(int(128.0 + mixed * env * 115.0), 0, 255)
		data[i] = sample_val

	stream.data = data
	return stream
