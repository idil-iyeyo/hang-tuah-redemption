extends Area2D

## Waurior (Wau Monarch) - Ancient Autonomous War-Kite Titan Boss Entity
## Features aerodynamic, wind-shearing attack sets & dynamic flight mobility:
##
## ATTACK SET ARCHITECTURE:
## - SET 1 (Aero Vanguard Assault): Bulan Crescent Arc -> Slicing Dart Barrage -> Extended Aero-Swoop Dive
## - SET 2 (Wind-Shear Cross Sweep): Wind-Shear Cross Gusts -> Bulan Crescent Arc
## - SET 3 (CQC Sky Dive Ambush): Extended Aero-Swoop Dive -> Center Slicing Darts
## - SET 4 (Gale Cataclysm - Enraged): Gale Storm -> Slicing Dart Barrage -> Extended Aero-Swoop Dive
##
## ATOMIC WEAPONRY:
## 1. Bulan Crescent Arc (expanding crescent volley with central piercing dart)
## 2. Wind-Shear Cross Gusts (alternating wingtip criss-crossing wind lines)
## 3. Slicing Dart Barrage (rapid aerodynamic high-velocity needle bursts)
## 4. High-G Aero-Swoop (parabolic dive-bomb deep through player flight corridor)
## 5. Gale Storm (enraged climax: wide crescent wave + dual-wing converging wake)

const SoundManager = preload("res://scripts/sound_manager.gd")

signal health_changed(current: int, max_hp: int)
signal boss_defeated
signal boss_reached_player
signal minion_spawn_requested(group_id: int)

enum AttackPattern {
	CRESCENT_ARC,
	CROSS_GUSTS,
	DART_BARRAGE,
	AERO_SWOOP,
	GALE_STORM
}

enum AttackSet {
	SET_1_AERO_ASSAULT,     # Crescent Arc -> Dart Barrage -> Extended Aero-Swoop Dive
	SET_2_CROSS_SHEAR,      # Wind-Shear Cross Gusts -> Crescent Arc
	SET_3_CQC_DIVE,         # Extended Aero-Swoop Dive -> Center Dart Barrage
	SET_4_GALE_CATACLYSM    # Enraged: Gale Storm -> Dart Barrage -> Extended Aero-Swoop Dive
}

# --- Attack Cadence & Balance Tuning Constants ---
const COOLDOWN_NORMAL: float = 2.0
const COOLDOWN_ENRAGED: float = 1.35

const MINION_INTERVAL_NORMAL: float = 9.0
const MINION_INTERVAL_ENRAGED: float = 6.5

# Visual tint colors for Waurior
const COLOR_WAU_GOLD: Color = Color(1.0, 0.88, 0.35)
const COLOR_WAU_CYAN: Color = Color(0.35, 0.90, 1.0)
const COLOR_WAU_ENRAGED: Color = Color(1.0, 0.28, 0.38)

# --- Export Variables ---
@export var max_health: int = 200
@export var advance_speed: float = 45.0
@export var minion_summon: bool = false
@export var projectile_scene: PackedScene = preload("res://scenes/enemies/projectile.tscn")

# --- State Variables ---
var current_health: int = 200
var elapsed_time: float = 0.0
var attack_timer: float = 1.8
var minion_timer: float = 4.5
var is_enraged: bool = false
var is_dead: bool = false
var is_attacking: bool = false
var is_swooping: bool = false
var next_attack: AttackPattern = AttackPattern.CRESCENT_ARC

# Attack Set Combo State
var is_executing_set: bool = false
var current_attack_set: AttackSet = AttackSet.SET_1_AERO_ASSAULT
var last_attack_set: int = -1

# Telegraph & Swoop State
var is_telegraphing_swoop: bool = false
var swoop_target_apex: Vector2 = Vector2.ZERO
var _swoop_tween: Tween = null
var _ram_damage_cooldown: float = 0.0

var target_center_y: float = 540.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy_units")
	add_to_group("boss_waurior")
	body_entered.connect(_on_body_entered)

	if not projectile_scene:
		projectile_scene = load("res://scenes/enemies/projectile.tscn")

	current_health = max_health
	health_changed.emit(current_health, max_health)

	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0)

	if minion_summon:
		var intro_timer: SceneTreeTimer = get_tree().create_timer(1.0)
		intro_timer.timeout.connect(func():
			if not is_dead and minion_summon:
				minion_spawn_requested.emit(0)
		)


func setup_boss(custom_hp: int = 200, center_y: float = 540.0, speed_multiplier: float = 1.0, can_summon_minions: bool = false) -> void:
	max_health = custom_hp
	current_health = custom_hp
	target_center_y = center_y
	advance_speed = advance_speed * speed_multiplier
	position.y = center_y
	minion_summon = can_summon_minions
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	elapsed_time += delta
	if _ram_damage_cooldown > 0.0:
		_ram_damage_cooldown -= delta

	if is_telegraphing_swoop:
		queue_redraw()

	# Periodic minion summoning if enabled
	if minion_summon:
		minion_timer -= delta
		if minion_timer <= 0.0:
			minion_timer = MINION_INTERVAL_ENRAGED if is_enraged else MINION_INTERVAL_NORMAL
			var group_id: int = randi_range(1, 4)
			minion_spawn_requested.emit(group_id)

	# Standard flight motion is suspended during high-G swoop maneuvers
	if not is_swooping:
		# Advance slowly towards the player line
		var speed: float = advance_speed * (1.2 if is_enraged else 1.0)
		position.x -= speed * delta

		# Smooth vertical hovering around assigned center_y
		var target_y: float = target_center_y + sin(elapsed_time * 1.5) * 220.0
		position.y = lerpf(position.y, target_y, 4.0 * delta)

		# Check for critical arrival at player defensive boundary
		if position.x <= 340.0:
			_trigger_arrival_crash()
			return

	# Attack pattern cadence
	if not is_attacking and not is_executing_set:
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = COOLDOWN_ENRAGED if is_enraged else COOLDOWN_NORMAL
			_trigger_next_attack()


# -----------------------------------------------------------------------------
# MULTI-POINT MUZZLE SYSTEM & TARGETING HELPERS
# -----------------------------------------------------------------------------

## Returns global position of the center beak / prow
func _get_center_muzzle() -> Vector2:
	return global_position + Vector2(-105.0, 0.0)


## Returns global position of the top crescent wingtip
func _get_upper_wing_muzzle() -> Vector2:
	return global_position + Vector2(-55.0, -95.0)


## Returns global position of the bottom crescent wingtip
func _get_lower_wing_muzzle() -> Vector2:
	return global_position + Vector2(-55.0, 95.0)


## Returns a normalized aim direction toward the player (or fallback)
func _get_aim_direction(from_pos: Vector2, angle_offset_deg: float = 0.0) -> Vector2:
	var arena: Node = get_parent()
	var target_pos: Vector2 = Vector2(250.0, 540.0)
	if arena:
		var player_node: Node2D = arena.get_node_or_null("Player") as Node2D
		if player_node and is_instance_valid(player_node) and player_node.visible:
			target_pos = player_node.global_position

	var base_dir: Vector2 = (target_pos - from_pos).normalized()
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.LEFT

	if absf(angle_offset_deg) > 0.001:
		var base_angle: float = base_dir.angle()
		return Vector2.from_angle(base_angle + deg_to_rad(angle_offset_deg))
	return base_dir


## Visual telegraph flare across Waurior's wings before attacks
func _telegraph_wings(duration: float = 0.16) -> void:
	if not sprite:
		return
	var flare_color: Color = Color(3.0, 2.4, 1.2) if not is_enraged else Color(3.2, 1.4, 1.6)
	var base_color: Color = Color(1.2, 0.8, 0.8) if is_enraged else Color(1.0, 1.0, 1.0)
	var t: Tween = create_tween()
	t.tween_property(sprite, "modulate", flare_color, duration * 0.4)
	t.tween_property(sprite, "modulate", base_color, duration * 0.6)


## Universal bullet spawner for Waurior
func _spawn_boss_bullet(
	spawn_pos: Vector2,
	dir: Vector2,
	movement_type: int = 0,
	spd: float = 440.0,
	variant_profile: String = "boss_direct",
	damage_val: int = 20,
	tint_color: Color = Color.WHITE,
	proj_scale: Vector2 = Vector2(0.35, 0.35)
) -> Area2D:
	if not projectile_scene:
		projectile_scene = load("res://scenes/enemies/projectile.tscn")
	if not projectile_scene or is_dead:
		return null

	var arena: Node = get_parent()
	if not arena:
		return null

	var bullet: Area2D = projectile_scene.instantiate() as Area2D
	if not bullet:
		return null

	bullet.position = spawn_pos
	bullet.set("direction", dir.normalized())
	bullet.set("speed", spd)

	var proj_cfg: Dictionary = EnemyProjectileDatabase.get_projectile_config("boss", null, variant_profile)
	if bullet.has_method("apply_config"):
		var call_cfg: Dictionary = proj_cfg.duplicate()
		call_cfg["movement_type"] = movement_type
		call_cfg["speed"] = spd
		call_cfg["damage"] = damage_val
		call_cfg["modulate"] = tint_color
		call_cfg["scale"] = proj_scale
		bullet.apply_config(call_cfg, dir)
	elif bullet.has_method("setup"):
		bullet.setup(movement_type, spd, dir, damage_val, 4.8, 45.0, false)
		var bullet_sprite: Sprite2D = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if bullet_sprite:
			bullet_sprite.modulate = tint_color
			bullet_sprite.scale = proj_scale

	arena.add_child(bullet)
	return bullet


# -----------------------------------------------------------------------------
# RANDOMIZED ATTACK SET SYSTEM
# -----------------------------------------------------------------------------

## Selects and executes a randomized aerodynamic attack set
func _trigger_next_attack() -> void:
	if is_dead or is_executing_set:
		return

	var available_sets: Array[AttackSet] = []
	if is_enraged:
		available_sets = [
			AttackSet.SET_1_AERO_ASSAULT,
			AttackSet.SET_1_AERO_ASSAULT,
			AttackSet.SET_3_CQC_DIVE,
			AttackSet.SET_4_GALE_CATACLYSM
		]
	else:
		available_sets = [
			AttackSet.SET_1_AERO_ASSAULT,
			AttackSet.SET_1_AERO_ASSAULT,
			AttackSet.SET_2_CROSS_SHEAR,
			AttackSet.SET_3_CQC_DIVE
		]

	var candidate_pool: Array[AttackSet] = available_sets
	if available_sets.size() > 1:
		var distinct: Array[AttackSet] = []
		for s in available_sets:
			if s != last_attack_set:
				distinct.append(s)
		if not distinct.is_empty():
			candidate_pool = distinct

	var chosen: AttackSet = candidate_pool[randi() % candidate_pool.size()]
	last_attack_set = chosen
	current_attack_set = chosen
	_execute_attack_set(chosen)


## Backward-compatibility wrapper for external callers
func _execute_boss_attack() -> void:
	_trigger_next_attack()


## Executes the designated aerodynamic attack set
func _execute_attack_set(set_type: AttackSet) -> void:
	if is_dead:
		return

	is_executing_set = true
	is_attacking = true

	match set_type:
		AttackSet.SET_1_AERO_ASSAULT:
			await _execute_attack_set_1()
		AttackSet.SET_2_CROSS_SHEAR:
			await _execute_attack_set_2()
		AttackSet.SET_3_CQC_DIVE:
			await _execute_attack_set_3()
		AttackSet.SET_4_GALE_CATACLYSM:
			await _execute_attack_set_4()

	is_executing_set = false
	is_attacking = false


## Attack Set 1 (Aero Vanguard Assault):
## 1. Bulan Crescent Arc
## 2. Slicing Dart Barrage
## 3. High-G Aero-Swoop Dive Bomb close to player
func _execute_attack_set_1() -> void:
	if is_dead or not is_inside_tree():
		return

	await _execute_crescent_arc()
	if is_dead or not is_inside_tree():
		return

	await get_tree().create_timer(0.25).timeout
	if is_dead or not is_inside_tree():
		return

	await _execute_dart_barrage()
	if is_dead or not is_inside_tree():
		return

	await get_tree().create_timer(0.20).timeout
	if is_dead or not is_inside_tree():
		return

	await _execute_aero_swoop()


## Attack Set 2 (Wind-Shear Cross Sweep):
## 1. Wind-Shear Cross Gusts
## 2. Bulan Crescent Arc
func _execute_attack_set_2() -> void:
	if is_dead or not is_inside_tree():
		return

	await _execute_cross_gusts()
	if is_dead or not is_inside_tree():
		return

	await get_tree().create_timer(0.25).timeout
	if is_dead or not is_inside_tree():
		return

	await _execute_crescent_arc()


## Attack Set 3 (Close-Quarters Dive Ambush):
## 1. Aero-Swoop Dive close to player
## 2. Point-blank Dart Barrage
func _execute_attack_set_3() -> void:
	if is_dead or not is_inside_tree():
		return

	await _execute_aero_swoop()
	if is_dead or not is_inside_tree():
		return

	await get_tree().create_timer(0.25).timeout
	if is_dead or not is_inside_tree():
		return

	await _execute_dart_barrage()


## Attack Set 4 (Gale Cataclysm - Enraged Climax):
## 1. Gale Storm Climax
## 2. Rapid Needle Dart Barrage
## 3. Extended Aero-Swoop Dive
func _execute_attack_set_4() -> void:
	if is_dead or not is_inside_tree():
		return

	await _execute_gale_storm()
	if is_dead or not is_inside_tree():
		return

	await get_tree().create_timer(0.25).timeout
	if is_dead or not is_inside_tree():
		return

	await _execute_dart_barrage()
	if is_dead or not is_inside_tree():
		return

	await get_tree().create_timer(0.20).timeout
	if is_dead or not is_inside_tree():
		return

	await _execute_aero_swoop()


# -----------------------------------------------------------------------------
# ATOMIC ATTACK PATTERNS (Directly Callable & Reusable)
# -----------------------------------------------------------------------------

## Pattern 1: Bulan Crescent Arc (Kerambit Bulan)
## Expanding fan wave evoking the crescent wings of the Wau Bulan
func _execute_crescent_arc() -> void:
	is_attacking = true
	_telegraph_wings(0.18)
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.18).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	SoundManager.play_sfx("cannon_shoot")

	var muzzle_pos: Vector2 = _get_center_muzzle()
	var bullet_count: int = 7 if is_enraged else 5
	var total_arc: float = 46.0 if is_enraged else 34.0
	var speed: float = 490.0 if is_enraged else 440.0
	var tint: Color = COLOR_WAU_ENRAGED if is_enraged else COLOR_WAU_GOLD

	var step_deg: float = total_arc / float(maxi(1, bullet_count - 1))
	var start_deg: float = -total_arc * 0.5

	for i in range(bullet_count):
		if is_dead:
			break
		var offset_deg: float = start_deg + float(i) * step_deg
		var fire_dir: Vector2 = _get_aim_direction(muzzle_pos, offset_deg)
		_spawn_boss_bullet(muzzle_pos, fire_dir, 0, speed, "boss_direct", 20, tint, Vector2(0.36, 0.36))

	# If enraged, also shoot a piercing fast dart through the center
	if is_enraged and not is_dead:
		var center_dir: Vector2 = _get_aim_direction(muzzle_pos, 0.0)
		_spawn_boss_bullet(muzzle_pos, center_dir, 3, 580.0, "boss_dart", 22, Color(1.2, 0.3, 0.3), Vector2(0.40, 0.26))

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.25).timeout
	is_attacking = false


## Pattern 2: Wind-Shear Cross Gusts (Ribut Silang)
## Criss-crossing bursts from the upper and lower wingtips forcing vertical movement
func _execute_cross_gusts() -> void:
	is_attacking = true
	_telegraph_wings(0.15)
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.15).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	var shot_pairs: int = 3 if is_enraged else 2
	var delay: float = 0.10 if is_enraged else 0.14
	var speed: float = 480.0 if is_enraged else 420.0
	var tint: Color = COLOR_WAU_ENRAGED if is_enraged else COLOR_WAU_CYAN
	var move_type: int = 1 if is_enraged else 0 # Sinusoidal wavy motion when enraged

	for pair in range(shot_pairs):
		if is_dead or not is_inside_tree():
			break

		# Upper wing tip fires downward-angled wind dart
		var up_pos: Vector2 = _get_upper_wing_muzzle()
		var up_dir: Vector2 = _get_aim_direction(up_pos, 14.0)
		_spawn_boss_bullet(up_pos, up_dir, move_type, speed, "boss_wavy" if move_type == 1 else "boss_direct", 20, tint, Vector2(0.34, 0.34))
		SoundManager.play_sfx("laser_shoot")

		if is_inside_tree() and not is_dead:
			await get_tree().create_timer(delay).timeout
		if is_dead or not is_inside_tree():
			break

		# Lower wing tip fires upward-angled wind dart
		var down_pos: Vector2 = _get_lower_wing_muzzle()
		var down_dir: Vector2 = _get_aim_direction(down_pos, -14.0)
		_spawn_boss_bullet(down_pos, down_dir, move_type, speed, "boss_wavy" if move_type == 1 else "boss_direct", 20, tint, Vector2(0.34, 0.34))
		SoundManager.play_sfx("laser_shoot")

		if is_inside_tree() and not is_dead:
			await get_tree().create_timer(delay).timeout

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.20).timeout
	is_attacking = false


## Pattern 3: Slicing Dart Barrage (Tusukan Layang)
## High-speed aerodynamic needle volley aimed directly at player
func _execute_dart_barrage() -> void:
	is_attacking = true
	_telegraph_wings(0.20)
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.20).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	var count: int = 5 if is_enraged else 3
	var delay: float = 0.08 if is_enraged else 0.12
	var speed: float = 580.0 if is_enraged else 520.0
	var tint: Color = Color(1.2, 0.4, 0.4) if is_enraged else Color(1.0, 0.9, 0.4)
	var muzzle_pos: Vector2 = _get_center_muzzle()

	for i in range(count):
		if is_dead or not is_inside_tree():
			break

		var fire_dir: Vector2 = _get_aim_direction(muzzle_pos, randf_range(-2.5, 2.5))
		_spawn_boss_bullet(muzzle_pos, fire_dir, 3, speed, "boss_dart", 20, tint, Vector2(0.38, 0.24))
		SoundManager.play_sfx("gatling_shoot")

		if is_inside_tree() and not is_dead:
			await get_tree().create_timer(delay).timeout

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.25).timeout
	is_attacking = false


## Pattern 4: Extended High-G Aero-Swoop & Wind Dive (Junaman Badai)
## Waurior displays a flight trajectory telegraph warning line, then executes a smooth aerodynamic
## dive-bomb deep into the player flight corridor, dropping trailing wind darts before sweeping back to station.
func _execute_aero_swoop() -> void:
	if is_dead:
		return
	is_attacking = true
	is_swooping = true

	var start_pos: Vector2 = position
	var arena: Node = get_parent()
	var player_node: Node2D = arena.get_node_or_null("Player") as Node2D if arena else null
	var player_pos: Vector2 = Vector2(250.0, 540.0)
	if player_node and is_instance_valid(player_node) and player_node.visible:
		player_pos = player_node.global_position

	# Extended dive apex: reaches close to player location (within ~140px), safe minimum 360px
	var dive_apex: Vector2 = Vector2(clampf(player_pos.x + 140.0, 360.0, 920.0), clampf(player_pos.y, 180.0, 900.0))
	swoop_target_apex = dive_apex

	# 1. Pre-charge Visual & Audio Telegraph Warning Phase
	is_telegraphing_swoop = true
	queue_redraw()
	_telegraph_wings(0.55)
	SoundManager.play_sfx("laser_shoot", 0.65)

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.55).timeout
	is_telegraphing_swoop = false
	queue_redraw()

	if is_dead or not is_inside_tree():
		is_swooping = false
		is_attacking = false
		return

	# 2. Smooth Aerodynamic Swoop Execution via single chained tween
	if _swoop_tween and _swoop_tween.is_valid():
		_swoop_tween.kill()

	_swoop_tween = create_tween()

	# Step A: Fluid pull-back anticipation
	_swoop_tween.tween_property(self, "position", start_pos + Vector2(65.0, -35.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Step B: Aerodynamic forward dive to apex
	_swoop_tween.tween_callback(func():
		if not is_dead:
			SoundManager.play_sfx("cannon_shoot", 1.25)
	)
	_swoop_tween.tween_property(self, "position", dive_apex, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Mid-dive payload: spawn trailing wind darts
	_swoop_tween.tween_callback(func():
		if not is_dead and is_swooping:
			var m_center: Vector2 = _get_center_muzzle()
			var m_up: Vector2 = _get_upper_wing_muzzle()
			var m_down: Vector2 = _get_lower_wing_muzzle()
			_spawn_boss_bullet(m_center, Vector2.LEFT, 1, 440.0, "boss_wavy", 20, COLOR_WAU_CYAN, Vector2(0.35, 0.35))
			_spawn_boss_bullet(m_up, Vector2(-1.0, -0.22).normalized(), 3, 510.0, "boss_dart", 20, COLOR_WAU_GOLD, Vector2(0.36, 0.24))
			_spawn_boss_bullet(m_down, Vector2(-1.0, 0.22).normalized(), 3, 510.0, "boss_dart", 20, COLOR_WAU_GOLD, Vector2(0.36, 0.24))
	)

	# Step C: Smooth looping return arc back to hover station
	var return_pos: Vector2 = Vector2(start_pos.x, target_center_y)
	_swoop_tween.tween_property(self, "position", return_pos, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Step D: Conclude swoop
	_swoop_tween.tween_callback(func():
		is_swooping = false
		is_attacking = false
	)

	# Watchdog timer: If anything interrupts or pauses the tween, reset state after 3.0s
	var watchdog: SceneTreeTimer = get_tree().create_timer(3.0)
	watchdog.timeout.connect(func():
		if is_swooping:
			is_swooping = false
			is_attacking = false
	)

	await _swoop_tween.finished


## Pattern 5: Gale Storm (Badai Monarch) - Enraged Climax
## High-impact combo: broad crescent arc followed by dual-wing converging wake
func _execute_gale_storm() -> void:
	is_attacking = true
	_telegraph_wings(0.22)
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.22).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	SoundManager.play_sfx("cannon_shoot")

	# 1. Broad crescent arc
	var center_pos: Vector2 = _get_center_muzzle()
	for angle_offset in [-24.0, -12.0, 0.0, 12.0, 24.0]:
		var dir: Vector2 = _get_aim_direction(center_pos, angle_offset)
		_spawn_boss_bullet(center_pos, dir, 0, 480.0, "boss_direct", 20, COLOR_WAU_ENRAGED, Vector2(0.36, 0.36))

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.18).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	# 2. Dual wing converging wavy darts
	var up_pos: Vector2 = _get_upper_wing_muzzle()
	var down_pos: Vector2 = _get_lower_wing_muzzle()
	_spawn_boss_bullet(up_pos, _get_aim_direction(up_pos, 8.0), 1, 460.0, "boss_wavy", 20, COLOR_WAU_CYAN, Vector2(0.36, 0.36))
	_spawn_boss_bullet(down_pos, _get_aim_direction(down_pos, -8.0), 1, 460.0, "boss_wavy", 20, COLOR_WAU_CYAN, Vector2(0.36, 0.36))
	SoundManager.play_sfx("laser_shoot")

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.30).timeout
	is_attacking = false


# -----------------------------------------------------------------------------
# DAMAGE, COLLISION & LIFECYCLE
# -----------------------------------------------------------------------------

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)

	# Phase 2 Enrage check
	if not is_enraged and current_health <= int(max_health * 0.5):
		is_enraged = true

	# Impact visual flash
	if sprite:
		var flash_color: Color = Color(2.5, 1.4, 0.9) if is_enraged else Color(2.2, 1.8, 1.8)
		var base_color: Color = Color(1.2, 0.8, 0.8) if is_enraged else Color(1.0, 1.0, 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", flash_color, 0.06)
		tween.tween_property(sprite, "modulate", base_color, 0.10)

	if current_health <= 0:
		die()


func _trigger_arrival_crash() -> void:
	is_dead = true
	is_attacking = false
	is_swooping = false
	is_executing_set = false
	if _swoop_tween and _swoop_tween.is_valid():
		_swoop_tween.kill()
	set_physics_process(false)
	boss_reached_player.emit()

	var main_node: Node = get_parent()
	if main_node:
		var player_node: Node = main_node.get_node_or_null("Player")
		if player_node and player_node.has_method("take_damage"):
			player_node.take_damage(100)

	# Clean explosion and cleanup so boss never remains a frozen zombie
	die()


func die() -> void:
	is_dead = true
	is_attacking = false
	is_swooping = false
	is_executing_set = false
	if _swoop_tween and _swoop_tween.is_valid():
		_swoop_tween.kill()
	is_telegraphing_swoop = false
	queue_redraw()
	set_physics_process(false)
	boss_defeated.emit()

	# Death explosion sequence
	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(3.0, 2.5, 1.5), 0.25)
		tween.parallel().tween_property(sprite, "scale", sprite.scale * 1.35, 0.25)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if is_swooping:
			# Lethal Aero-Swoop Dive: Instantly destroys player even with shields!
			SoundManager.play_sfx("boss_explode", 1.6)
			if body.has_method("lethal_hit"):
				body.lethal_hit()
			elif body.has_method("take_damage"):
				body.take_damage(999999, true)
			elif body.has_method("die"):
				body.die()
			return
		if body.has_method("take_damage"):
			body.take_damage(100)
		_trigger_arrival_crash()


# -----------------------------------------------------------------------------
# PROCEDURAL DRAWING PIPELINE (AERO-SWOOP TELEGRAPH TRAJECTORY)
# -----------------------------------------------------------------------------

func _draw() -> void:
	if not is_telegraphing_swoop:
		return

	# Draw telegraph danger path from boss beak to dive apex
	var local_start: Vector2 = to_local(_get_center_muzzle())
	var local_target: Vector2 = to_local(swoop_target_apex)

	var time_ms: float = float(Time.get_ticks_msec())
	var pulse: float = 0.40 + sin(time_ms * 0.025) * 0.25
	var warning_color: Color = Color(1.0, 0.25, 0.25, pulse) if is_enraged else Color(1.0, 0.85, 0.25, pulse)
	var glow_color: Color = Color(warning_color.r, warning_color.g, warning_color.b, pulse * 0.35)

	# 1. Outer warning glow corridor
	draw_line(local_start, local_target, glow_color, 8.0)
	# 2. Sharp central trajectory line
	draw_line(local_start, local_target, warning_color, 2.5)

	# 3. Target landing reticle / danger circle at apex
	var reticle_radius: float = 16.0 + sin(time_ms * 0.02) * 3.0
	draw_arc(local_target, reticle_radius, 0.0, TAU, 24, warning_color, 2.0)
	draw_circle(local_target, 4.0, warning_color)

	# 4. Animated chevron hazard markers along the swoop line
	var dir_to_target: Vector2 = (local_target - local_start).normalized()
	var total_dist: float = local_start.distance_to(local_target)
	var step: float = 40.0
	var offset: float = fmod(time_ms * 0.06, step)
	var normal: Vector2 = Vector2(-dir_to_target.y, dir_to_target.x)

	var d: float = offset
	while d < total_dist - 15.0:
		var pt: Vector2 = local_start + dir_to_target * d
		var wing_left: Vector2 = pt - dir_to_target * 6.0 + normal * 6.0
		var wing_right: Vector2 = pt - dir_to_target * 6.0 - normal * 6.0
		draw_line(pt, wing_left, warning_color, 1.8)
		draw_line(pt, wing_right, warning_color, 1.8)
		d += step
