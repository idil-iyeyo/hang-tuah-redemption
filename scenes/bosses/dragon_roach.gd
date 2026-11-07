extends Area2D

## Minangkabau Ship (Kapal Minangkabau) - Phantom Horned Dreadnought Boss Entity
## Features advanced naval space-combat attack patterns, hazards & mobility maneuvers:
## 1. Twin Horn Prow Battery (upper & lower curved gonjong turrets firing converging pincers)
## 2. Broadside Artillery Cascade (staggered flank cannons firing top-to-bottom waves)
## 3. Thruster Surge (heavy sub-light engine surge compressing player airspace with point-blank salvo)
## 4. Phantom Railgun Stream (dense rapid-fire plasma stream with dynamic player tracking)
## 5. Phantom Solar Laser Ray (unstoppable continuous energy beam with targeting telegraph)
## 6. Armada Bombardment (enraged climax: simultaneous horn pincer + sweeping broadside barrage)

const SoundManager = preload("res://scripts/sound_manager.gd")

signal health_changed(current: int, max_hp: int)
signal boss_defeated
signal boss_reached_player
signal minion_spawn_requested(group_id: int)

enum AttackPattern {
	TWIN_HORN_PINCER,
	BROADSIDE_CASCADE,
	THRUSTER_SURGE,
	RAILGUN_STREAM,
	PHANTOM_LASER,
	ARMADA_BOMBARDMENT
}

# --- Attack Cadence & Balance Tuning Constants ---
const COOLDOWN_NORMAL: float = 2.4
const COOLDOWN_ENRAGED: float = 1.6

const MINION_INTERVAL_NORMAL: float = 10.5
const MINION_INTERVAL_ENRAGED: float = 8.0

# Visual Colors for Minangkabau Ship Projectiles
const COLOR_FLAME_NORMAL: Color = Color(1.0, 0.42, 0.12)
const COLOR_FLAME_ENRAGED: Color = Color(1.0, 0.15, 0.28)
const COLOR_GOLD_ORNATE: Color = Color(1.0, 0.82, 0.22)
const COLOR_CYAN_PLASMA: Color = Color(0.25, 0.85, 1.0)

# --- Export Variables ---
@export var max_health: int = 200
@export var advance_speed: float = 38.0
@export var projectile_scene: PackedScene = preload("res://scenes/enemies/projectile.tscn")
@export var boss_laser_scene: PackedScene = preload("res://scenes/bosses/boss_laser_beam.tscn")
@export var minion_summon: bool = true

# --- State Variables ---
var current_health: int = 200
var elapsed_time: float = 0.0
var attack_cooldown: float = 2.0
var minion_cooldown: float = 4.5
var is_attacking: bool = false
var is_surging: bool = false
var is_enraged: bool = false
var is_dead: bool = false
var next_attack: AttackPattern = AttackPattern.TWIN_HORN_PINCER

# Telegraph & Surge Tuning
var is_telegraphing_surge: bool = false
var surge_target_x: float = 750.0
var _surge_tween: Tween = null
var _ram_damage_cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy_units")
	add_to_group("dragon_roach")
	body_entered.connect(_on_body_entered)

	# Self-healing safeguard: ensure projectile scenes are never null
	if not projectile_scene:
		projectile_scene = load("res://scenes/enemies/projectile.tscn")
	if not boss_laser_scene:
		boss_laser_scene = load("res://scenes/bosses/boss_laser_beam.tscn")

	if max_health <= 0:
		max_health = 200
	if advance_speed <= 0.0:
		advance_speed = 38.0

	current_health = max_health
	health_changed.emit(current_health, max_health)

	# Initial minion greeting spawn if enabled
	if minion_summon:
		var intro_timer: SceneTreeTimer = get_tree().create_timer(1.0)
		intro_timer.timeout.connect(func():
			if not is_dead and minion_summon:
				minion_spawn_requested.emit(0) # Group 0: 2 Tanks, 1 Bile Spewer
		)


func setup_boss(custom_hp: int = 200, center_y: float = 540.0, speed_multiplier: float = 1.0, can_summon_minions: bool = true) -> void:
	max_health = custom_hp
	current_health = custom_hp
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

	if is_telegraphing_surge:
		queue_redraw()

	# Regular flight advancement is suspended while thruster surge is active
	if not is_surging:
		# Steady serpentine advance towards player line
		var speed: float = advance_speed * (1.18 if is_enraged else 1.0)
		position.x -= speed * delta

		# Sinuous dragon flight oscillation
		var target_y: float = 540.0 + sin(elapsed_time * 1.6) * 330.0
		position.y = lerpf(position.y, target_y, 3.5 * delta)

		# Check for critical arrival at player defensive boundary
		if position.x <= 340.0:
			_trigger_arrival_crash()
			return

	# Attack cadence
	if not is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			attack_cooldown = COOLDOWN_ENRAGED if is_enraged else COOLDOWN_NORMAL
			_trigger_next_ship_attack()

	# Periodic minion set spawner
	if minion_summon and not is_dead:
		minion_cooldown -= delta
		if minion_cooldown <= 0.0:
			minion_cooldown = MINION_INTERVAL_ENRAGED if is_enraged else MINION_INTERVAL_NORMAL
			var group_id: int = randi_range(1, 4)
			minion_spawn_requested.emit(group_id)


# -----------------------------------------------------------------------------
# MULTI-BATTERY MUZZLE SYSTEM & TARGETING HELPERS
# -----------------------------------------------------------------------------

## Returns global position of upper or lower horn tip (Gonjong)
func _get_horn_muzzle(is_upper: bool) -> Vector2:
	return global_position + Vector2(-80.0, -115.0 if is_upper else 115.0)


## Returns global position of the center bow deck cannon
func _get_bow_muzzle(vertical_jitter: float = 0.0) -> Vector2:
	return global_position + Vector2(-115.0, vertical_jitter)


## Backward-compatible wrapper
func _get_muzzle_position(vertical_jitter: float = 0.0) -> Vector2:
	return _get_bow_muzzle(vertical_jitter)


## Returns global position for 1 of 4 broadside flank ports
func _get_broadside_muzzle(port_index: int) -> Vector2:
	var y_offsets: Array = [-90.0, -30.0, 30.0, 90.0]
	var idx: int = clampi(port_index, 0, y_offsets.size() - 1)
	var x_offset: float = -45.0 if (idx == 1 or idx == 2) else -40.0
	return global_position + Vector2(x_offset, y_offsets[idx])


## Returns a normalized aim vector directed at the player (or defensive line if player is absent)
func _get_aim_direction(from_pos: Vector2, angle_offset_deg: float = 0.0) -> Vector2:
	var arena: Node = get_parent()
	var target_pos: Vector2 = Vector2(250.0, 540.0) # Player spawn anchor fallback
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


## Reusable factory method: instantiates, configures, and registers a projectile in the arena
func _spawn_dragon_projectile(
	spawn_global_pos: Vector2,
	fire_direction: Vector2,
	proj_speed: float,
	movement_type: int = 0,
	damage_amount: int = 20,
	tint_color: Color = COLOR_FLAME_NORMAL,
	proj_scale: Vector2 = Vector2(0.34, 0.34),
	variant_profile: String = "dragon_volley"
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

	bullet.position = spawn_global_pos
	bullet.set("direction", fire_direction.normalized())
	bullet.set("speed", proj_speed)

	var dragon_cfg: Dictionary = EnemyProjectileDatabase.get_projectile_config("dragon_roach", null, variant_profile)
	if bullet.has_method("apply_config"):
		var call_cfg: Dictionary = dragon_cfg.duplicate()
		call_cfg["movement_type"] = movement_type
		call_cfg["speed"] = proj_speed
		call_cfg["damage"] = damage_amount
		call_cfg["modulate"] = tint_color
		call_cfg["scale"] = proj_scale
		bullet.apply_config(call_cfg, fire_direction)
	elif bullet.has_method("setup"):
		bullet.setup(movement_type, proj_speed, fire_direction, damage_amount, 4.5, 45.0, false, false)
		var bullet_sprite: Sprite2D = bullet.get_node_or_null("Sprite2D") as Sprite2D
		if bullet_sprite:
			bullet_sprite.modulate = tint_color
			bullet_sprite.scale = proj_scale

	arena.add_child(bullet)
	return bullet


## Smooth visual flare on the Minangkabau Ship sprite when launching attacks
func _flash_dragon_maw(duration: float = 0.18) -> void:
	if not sprite:
		return
	var flare_color: Color = Color(2.8, 2.1, 1.2) if not is_enraged else Color(3.2, 1.3, 1.4)
	var base_color: Color = Color(1.0, 0.35, 0.15) if is_enraged else Color(1.0, 1.0, 1.0)
	var t: Tween = create_tween()
	t.tween_property(sprite, "modulate", flare_color, duration * 0.4)
	t.tween_property(sprite, "modulate", base_color, duration * 0.6)


# -----------------------------------------------------------------------------
# ATTACK PATTERNS & STATE MACHINE
# -----------------------------------------------------------------------------

func _trigger_next_ship_attack() -> void:
	if is_dead:
		return

	match next_attack:
		AttackPattern.TWIN_HORN_PINCER:
			next_attack = AttackPattern.BROADSIDE_CASCADE
			_launch_twin_horn_pincer()
		AttackPattern.BROADSIDE_CASCADE:
			next_attack = AttackPattern.THRUSTER_SURGE
			_launch_broadside_cascade()
		AttackPattern.THRUSTER_SURGE:
			next_attack = AttackPattern.RAILGUN_STREAM
			_launch_thruster_surge()
		AttackPattern.RAILGUN_STREAM:
			next_attack = AttackPattern.PHANTOM_LASER
			_launch_railgun_stream()
		AttackPattern.PHANTOM_LASER:
			if is_enraged:
				next_attack = AttackPattern.ARMADA_BOMBARDMENT
			else:
				next_attack = AttackPattern.TWIN_HORN_PINCER
			_launch_phantom_laser()
		AttackPattern.ARMADA_BOMBARDMENT:
			next_attack = AttackPattern.TWIN_HORN_PINCER
			_launch_armada_bombardment()


## Attack 1: Twin Horn Prow Battery (Meriam Kembar Minangkabau)
## Dual upper and lower horn turrets fire converging plasma salvos (pincer trap)
func _launch_twin_horn_pincer() -> void:
	is_attacking = true
	_flash_dragon_maw(0.18)
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.18).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	var burst_rounds: int = 3 if is_enraged else 2
	var speed: float = 540.0 if is_enraged else 470.0
	var tint: Color = COLOR_FLAME_ENRAGED if is_enraged else COLOR_GOLD_ORNATE
	var delay: float = 0.14 if is_enraged else 0.18

	for r in range(burst_rounds):
		if is_dead or not is_inside_tree():
			break

		var up_horn: Vector2 = _get_horn_muzzle(true)
		var down_horn: Vector2 = _get_horn_muzzle(false)

		var dir_up: Vector2 = _get_aim_direction(up_horn, 12.0)
		var dir_down: Vector2 = _get_aim_direction(down_horn, -12.0)

		_spawn_dragon_projectile(up_horn, dir_up, speed, 0, 20, tint, Vector2(0.38, 0.38), "dragon_volley")
		_spawn_dragon_projectile(down_horn, dir_down, speed, 0, 20, tint, Vector2(0.38, 0.38), "dragon_volley")

		# If enraged, also shoot a central bow slug
		if is_enraged:
			var bow_pos: Vector2 = _get_bow_muzzle()
			_spawn_dragon_projectile(bow_pos, _get_aim_direction(bow_pos, 0.0), speed * 1.1, 3, 22, COLOR_FLAME_ENRAGED, Vector2(0.34, 0.34), "dragon_stream")

		SoundManager.play_sfx("cannon_shoot")

		if is_inside_tree() and not is_dead:
			await get_tree().create_timer(delay).timeout

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.25).timeout
	is_attacking = false


## Attack 2: Broadside Artillery Cascade (Serangan Lambung Kapal)
## Cascading cannon fire across the 4 vertical flank ports creating a rhythmic wave
func _launch_broadside_cascade() -> void:
	is_attacking = true
	_flash_dragon_maw(0.20)
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.20).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	var port_indices: Array = [0, 1, 2, 3]
	if is_enraged:
		port_indices = [0, 1, 2, 3, 2, 1, 0] # Sweep down and sweep back up!

	var delay: float = 0.07 if is_enraged else 0.09
	var speed: float = 510.0 if is_enraged else 450.0
	var tint: Color = COLOR_FLAME_ENRAGED if is_enraged else COLOR_FLAME_NORMAL

	for port_idx in port_indices:
		if is_dead or not is_inside_tree():
			break

		var muzzle: Vector2 = _get_broadside_muzzle(int(port_idx))
		# 2-bullet mini spread from each broadside gun port
		var dir1: Vector2 = _get_aim_direction(muzzle, -6.0)
		var dir2: Vector2 = _get_aim_direction(muzzle, 6.0)

		_spawn_dragon_projectile(muzzle, dir1, speed, 0, 18, tint, Vector2(0.32, 0.32), "dragon_volley")
		_spawn_dragon_projectile(muzzle, dir2, speed, 0, 18, tint, Vector2(0.32, 0.32), "dragon_volley")

		SoundManager.play_sfx("laser_shoot")

		if is_inside_tree() and not is_dead:
			await get_tree().create_timer(delay).timeout

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.30).timeout
	is_attacking = false


## Attack 3: Thruster Surge & Ramming Reposition (Lajakan Haluan)
## Cosmic warship ignites its sub-light plasma thrusters, surging forward to compress player airspace,
## unleashes a point-blank dual horn salvo, then reverses smoothly back to firing distance.
func _launch_thruster_surge() -> void:
	if is_dead:
		return
	is_attacking = true
	is_surging = true

	var start_pos: Vector2 = position
	surge_target_x = clampf(start_pos.x - 650.0, 680.0, 960.0)

	# 1. Engine flare & Charge Telegraph Phase (visual danger corridor warning)
	is_telegraphing_surge = true
	queue_redraw()
	_flash_dragon_maw(0.55)
	SoundManager.play_sfx("cannon_shoot", 0.65)

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.55).timeout
	is_telegraphing_surge = false
	queue_redraw()

	if is_dead or not is_inside_tree():
		is_surging = false
		is_attacking = false
		return

	# 2. Smooth Thruster Surge Execution via chained tween
	if _surge_tween and _surge_tween.is_valid():
		_surge_tween.kill()

	_surge_tween = create_tween()
	# Step A: Sub-light forward acceleration
	_surge_tween.tween_callback(func():
		if not is_dead:
			SoundManager.play_sfx("cannon_shoot", 1.1)
	)
	_surge_tween.tween_property(self, "position:x", surge_target_x, 0.78).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# Step B: Point-blank salvo at apex
	_surge_tween.tween_callback(func():
		if not is_dead and is_surging:
			SoundManager.play_sfx("cannon_shoot")
			var up_horn: Vector2 = _get_horn_muzzle(true)
			var down_horn: Vector2 = _get_horn_muzzle(false)
			_spawn_dragon_projectile(up_horn, _get_aim_direction(up_horn, 10.0), 520.0, 0, 20, COLOR_GOLD_ORNATE, Vector2(0.38, 0.38))
			_spawn_dragon_projectile(down_horn, _get_aim_direction(down_horn, -10.0), 520.0, 0, 20, COLOR_GOLD_ORNATE, Vector2(0.38, 0.38))
			if is_enraged:
				var bow_pos: Vector2 = _get_bow_muzzle()
				_spawn_dragon_projectile(bow_pos, _get_aim_direction(bow_pos, 0.0), 580.0, 3, 24, COLOR_FLAME_ENRAGED, Vector2(0.38, 0.38))
	)
	_surge_tween.tween_interval(0.18)

	# Step C: Smooth reverse repositioning back to station
	_surge_tween.tween_property(self, "position:x", start_pos.x, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Step D: Conclude surge
	_surge_tween.tween_callback(func():
		is_surging = false
		is_attacking = false
	)

	# Safety watchdog timer: guarantees state resets even under unexpected interruptions
	var watchdog: SceneTreeTimer = get_tree().create_timer(3.2)
	watchdog.timeout.connect(func():
		if is_surging:
			is_surging = false
			is_attacking = false
	)


## Attack 5: Phantom Railgun Stream (Bedil Laksamana)
## High-velocity rapid fire from center bow with live vertical tracking
func _launch_railgun_stream() -> void:
	is_attacking = true
	_flash_dragon_maw(0.25)
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.20).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	var shot_count: int = 24 if is_enraged else 16
	var delay: float = 0.048 if is_enraged else 0.062
	var speed: float = 590.0 if is_enraged else 520.0
	var move_type: int = 3 if is_enraged else 0 # FAST_DART when enraged
	var tint: Color = COLOR_FLAME_ENRAGED if is_enraged else COLOR_CYAN_PLASMA

	for i in range(shot_count):
		if is_dead or not is_inside_tree():
			break

		var y_jitter: float = randf_range(-14.0, 14.0)
		var angle_jitter: float = randf_range(-3.0, 3.0)
		var muzzle_pos: Vector2 = _get_bow_muzzle(y_jitter)
		var fire_dir: Vector2 = _get_aim_direction(muzzle_pos, angle_jitter)

		_spawn_dragon_projectile(muzzle_pos, fire_dir, speed, move_type, 20, tint, Vector2(0.34, 0.34), "dragon_stream")

		if i % 4 == 0:
			SoundManager.play_sfx("laser_shoot")

		if is_inside_tree() and not is_dead:
			await get_tree().create_timer(delay).timeout

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.25).timeout
	is_attacking = false


## Attack 6: Phantom Solar Laser Ray (Pancaran Meriam Surya)
## Fires an unstoppable, continuous high-energy laser beam from the ship's bow across the screen.
## Mirrors the multi-layered visual fidelity of the player's Quasar Laser (scaled smaller for balance).
## Cannot be counter-shot or intercepted by player weapons.
func _launch_phantom_laser() -> void:
	is_attacking = true
	_flash_dragon_maw(0.30)

	var arena: Node = get_parent()
	if not arena:
		is_attacking = false
		return

	if not boss_laser_scene:
		boss_laser_scene = load("res://scenes/bosses/boss_laser_beam.tscn")
	if not boss_laser_scene or is_dead:
		is_attacking = false
		return

	var bow_pos: Vector2 = _get_bow_muzzle()
	var beam: Area2D = boss_laser_scene.instantiate() as Area2D
	if not beam:
		is_attacking = false
		return

	beam.position = bow_pos
	arena.add_child(beam)

	var bow_local_offset: Vector2 = Vector2(-115.0, 0.0)
	if beam.has_method("setup_beam"):
		beam.setup_beam(self, bow_local_offset, 15, is_enraged)

	# Telegraph (0.65s) + Firing (1.25s) + Fade (0.15s) = ~2.05s
	var total_duration: float = 2.1
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(total_duration).timeout

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.35).timeout
	is_attacking = false


## Attack 7: Armada Bombardment (Amukan Kapal Perang) - Enraged Climax
## Coordinated full-ship assault: simultaneous horn crossfire + deck artillery
func _launch_armada_bombardment() -> void:
	is_attacking = true
	_flash_dragon_maw(0.28)
	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.25).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	SoundManager.play_sfx("cannon_shoot")

	# 1. Dual horn crossfire
	var up_horn: Vector2 = _get_horn_muzzle(true)
	var down_horn: Vector2 = _get_horn_muzzle(false)
	for offset_deg in [-10.0, 0.0, 10.0]:
		_spawn_dragon_projectile(up_horn, _get_aim_direction(up_horn, offset_deg + 12.0), 520.0, 0, 20, COLOR_GOLD_ORNATE, Vector2(0.36, 0.36), "dragon_volley")
		_spawn_dragon_projectile(down_horn, _get_aim_direction(down_horn, offset_deg - 12.0), 520.0, 0, 20, COLOR_GOLD_ORNATE, Vector2(0.36, 0.36), "dragon_volley")

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.18).timeout
	if is_dead or not is_inside_tree():
		is_attacking = false
		return

	# 2. Synchronized full broadside from all 4 flank ports
	SoundManager.play_sfx("cannon_shoot")
	for p in range(4):
		var port_pos: Vector2 = _get_broadside_muzzle(p)
		var dir: Vector2 = _get_aim_direction(port_pos, 0.0)
		_spawn_dragon_projectile(port_pos, dir, 480.0, 1, 20, COLOR_FLAME_ENRAGED, Vector2(0.38, 0.38), "dragon_volley")

	if is_inside_tree() and not is_dead:
		await get_tree().create_timer(0.35).timeout
	is_attacking = false


## Backward-compatible aliases for legacy callers
func _launch_spread_volley() -> void:
	_launch_twin_horn_pincer()


func _launch_stream_burst() -> void:
	_launch_railgun_stream()


# -----------------------------------------------------------------------------
# DAMAGE, COLLISION & LIFECYCLE
# -----------------------------------------------------------------------------

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)

	if not is_enraged and current_health <= int(max_health * 0.5):
		is_enraged = true

	# Impact visual flash
	if sprite:
		var flash_color: Color = Color(2.5, 2.0, 1.2)
		var base_color: Color = Color(1.0, 0.35, 0.15) if is_enraged else Color(1.0, 1.0, 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", flash_color, 0.06)
		tween.tween_property(sprite, "modulate", base_color, 0.10)

	if current_health <= 0:
		die()


func _trigger_arrival_crash() -> void:
	is_dead = true
	is_attacking = false
	is_surging = false
	if _surge_tween and _surge_tween.is_valid():
		_surge_tween.kill()
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
	is_surging = false
	if _surge_tween and _surge_tween.is_valid():
		_surge_tween.kill()
	is_telegraphing_surge = false
	queue_redraw()
	set_physics_process(false)
	boss_defeated.emit()

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(3.0, 2.5, 1.0), 0.25)
		tween.parallel().tween_property(sprite, "scale", sprite.scale * 1.4, 0.25)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.35)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if is_surging:
			# During sub-light thruster surge, deal collision ram damage to player without triggering arrival crash
			if _ram_damage_cooldown <= 0.0:
				_ram_damage_cooldown = 0.5
				if body.has_method("take_damage"):
					body.take_damage(35)
				SoundManager.play_sfx("boss_explode", 1.4)
			return
		if body.has_method("take_damage"):
			body.take_damage(100)
		_trigger_arrival_crash()


# -----------------------------------------------------------------------------
# PROCEDURAL DRAWING PIPELINE (THRUSTER SURGE TELEGRAPH CORRIDOR)
# -----------------------------------------------------------------------------

func _draw() -> void:
	if not is_telegraphing_surge:
		return

	# Draw horizontal naval dreadnought charge corridor to surge_target_x
	var local_bow: Vector2 = to_local(_get_bow_muzzle())
	var local_apex_x: float = to_local(Vector2(surge_target_x, global_position.y)).x

	var time_ms: float = float(Time.get_ticks_msec())
	var pulse: float = 0.40 + sin(time_ms * 0.025) * 0.25
	var alert_color: Color = Color(1.0, 0.20, 0.25, pulse) if is_enraged else Color(1.0, 0.55, 0.15, pulse)
	var lane_fill_color: Color = Color(alert_color.r, alert_color.g, alert_color.b, pulse * 0.18)

	var half_h: float = 38.0
	var min_x: float = minf(local_bow.x, local_apex_x)
	var width_x: float = absf(local_bow.x - local_apex_x)

	# 1. Translucent danger corridor fill
	draw_rect(Rect2(Vector2(min_x, -half_h), Vector2(width_x, half_h * 2.0)), lane_fill_color)

	# 2. Upper and lower boundary warning lines
	draw_line(Vector2(local_bow.x, -half_h), Vector2(local_apex_x, -half_h), alert_color, 2.2)
	draw_line(Vector2(local_bow.x, half_h), Vector2(local_apex_x, half_h), alert_color, 2.2)

	# 3. Target stopping line & vertical bracket at apex
	draw_line(Vector2(local_apex_x, -half_h - 10.0), Vector2(local_apex_x, half_h + 10.0), alert_color, 3.0)

	# 4. Animated chevrons pointing LEFT towards the player
	var step: float = 35.0
	var offset: float = fmod(time_ms * 0.08, step)
	var curr_x: float = local_bow.x - offset
	while curr_x > local_apex_x + 10.0:
		var tip: Vector2 = Vector2(curr_x, 0.0)
		var top_wing: Vector2 = Vector2(curr_x + 12.0, -18.0)
		var bot_wing: Vector2 = Vector2(curr_x + 12.0, 18.0)
		draw_line(tip, top_wing, alert_color, 2.0)
		draw_line(tip, bot_wing, alert_color, 2.0)
		curr_x -= step
