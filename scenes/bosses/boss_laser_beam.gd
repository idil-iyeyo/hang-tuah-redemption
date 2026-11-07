extends Area2D

## BossLaserBeam - Unstoppable Solar Plasma Laser Ray
## Fired by the Minangkabau Ship (Kapal Minangkabau).
## Mirrors the multi-layered visual fidelity of the Player's Level 5 Quasar Laser Ray,
## scaled down to balanced dimensions (~30-40% size) with clear airspace for evasion.
##
## CANNOT BE COUNTER-SHOT:
## - Immune to player projectiles and player laser interception.
## - Does not implement destructible projectile logic.
## - Features a pre-fire telegraph targeting tracer for fair reaction time.

const SoundManager = preload("res://scripts/sound_manager.gd")

enum BeamState {
	TELEGRAPH, # Thin warning tracer line showing the firing lane
	FIRING,    # Full multi-layered procedural laser ray
	FADING     # Smooth decay and cleanup
}

# --- Beam Visual & Collision Sizing (Smaller to balance out vs Player's 3.2x Ray) ---
@export_group("Laser Sizing")
@export var beam_scale: float = 1.0
@export var outer_aura_width: float = 30.0
@export var mid_glow_width: float = 16.0
@export var inner_core_width: float = 7.0
@export var center_filament_width: float = 2.8
@export var muzzle_flare_radius: float = 16.0
@export var impact_flare_radius: float = 20.0
@export var collision_height: float = 22.0

# --- Attack Timers ---
@export_group("Cadence & Damage")
@export var telegraph_duration: float = 0.65
@export var firing_duration: float = 1.75
@export var fade_duration: float = 0.15
@export var damage_per_tick: int = 25
@export var tick_interval: float = 0.20

# --- State Variables ---
var current_state: BeamState = BeamState.TELEGRAPH
var state_timer: float = 0.0
var tick_timer: float = 0.0
var ray_length: float = 1920.0
var current_alpha: float = 1.0
var is_enraged: bool = false

var source_node: Node2D = null
var source_offset: Vector2 = Vector2.ZERO

var is_hitting_player: bool = false
var hit_player_world_pos: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("boss_hazard")
	add_to_group("boss_laser")
	# Deliberately NOT added to "enemy_projectiles" so player fire cannot intercept it

	state_timer = telegraph_duration
	tick_timer = 0.0
	current_alpha = 1.0
	_update_ray_length()
	queue_redraw()


## Setup method called when instantiated by the Minangkabau Ship
func setup_beam(source: Node2D, offset: Vector2 = Vector2.ZERO, dmg: int = 40, enraged: bool = false) -> void:
	source_node = source
	source_offset = offset
	damage_per_tick = dmg
	is_enraged = enraged

	if is_instance_valid(source):
		global_position = source.global_position + offset

	if is_enraged:
		beam_scale = 2.50
		damage_per_tick = int(dmg * 35)
		firing_duration = 2.50

	_update_ray_length()
	# Play telegraph audio cue
	SoundManager.play_sfx("laser_shoot", 1.6)


func _physics_process(delta: float) -> void:
	# 1. Anchor to ship muzzle as the ship hovers vertically
	if is_instance_valid(source_node):
		global_position = source_node.global_position + source_offset

	_update_ray_length()

	# 2. State Machine Execution
	match current_state:
		BeamState.TELEGRAPH:
			state_timer -= delta
			if state_timer <= 0.0:
				current_state = BeamState.FIRING
				state_timer = firing_duration
				SoundManager.play_sfx("laser_beam")

		BeamState.FIRING:
			state_timer -= delta
			_check_player_collision_and_damage(delta)
			if state_timer <= 0.0:
				current_state = BeamState.FADING
				state_timer = fade_duration
				is_hitting_player = false

		BeamState.FADING:
			state_timer -= delta
			current_alpha = clampf(state_timer / fade_duration, 0.0, 1.0)
			if state_timer <= 0.0:
				queue_free()
				return

	# 3. Synchronize Collision Shape
	if collision_shape:
		if not (collision_shape.shape is RectangleShape2D):
			collision_shape.shape = RectangleShape2D.new()
		var rect: RectangleShape2D = collision_shape.shape as RectangleShape2D
		rect.size = Vector2(ray_length, collision_height * beam_scale)
		collision_shape.position = Vector2(-ray_length * 0.5, 0.0)

	queue_redraw()


## Dynamically calculates beam length spanning from ship's bow past screen left boundary
func _update_ray_length() -> void:
	# Screen left boundary with slight margin
	var min_x: float = -60.0
	ray_length = maxf(100.0, global_position.x - min_x)


## Detects if the player is within the horizontal laser corridor and applies tick damage
func _check_player_collision_and_damage(delta: float) -> void:
	is_hitting_player = false
	var arena: Node = get_parent()
	if not arena:
		return

	var player: Node2D = arena.get_node_or_null("Player") as Node2D
	if not player or not is_instance_valid(player) or not player.visible:
		return

	var p_pos: Vector2 = player.global_position
	# Check X axis: player must be in front of the beam (between -60 and ship's bow + 20)
	if p_pos.x > global_position.x + 20.0 or p_pos.x < -60.0:
		return

	# Check Y axis corridor with beam tolerance
	var half_h: float = 40.0
	var p_col: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if p_col and p_col.shape:
		if p_col.shape is RectangleShape2D:
			half_h = (p_col.shape as RectangleShape2D).size.y * 0.5 * p_col.global_scale.y
		elif p_col.shape is CircleShape2D:
			half_h = (p_col.shape as CircleShape2D).radius * p_col.global_scale.y

	var corridor_tolerance: float = half_h + (collision_height * 0.5 * beam_scale)
	if absf(p_pos.y - global_position.y) <= corridor_tolerance:
		is_hitting_player = true
		hit_player_world_pos = Vector2(p_pos.x, global_position.y)

		tick_timer -= delta
		if tick_timer <= 0.0:
			tick_timer = tick_interval
			if player.has_method("take_damage"):
				player.take_damage(damage_per_tick)


# -----------------------------------------------------------------------------
# PROCEDURAL DRAWING PIPELINE (MIRRORS LEVEL 5 QUASAR LASER)
# -----------------------------------------------------------------------------

func _draw() -> void:
	if ray_length <= 0.0:
		return

	var start_pt: Vector2 = Vector2.ZERO
	# Laser fires HORIZONTALLY TO THE LEFT towards player line
	var end_pt: Vector2 = Vector2(-ray_length, 0.0)

	# 1. TELEGRAPH STATE: Faint targeting guideline
	if current_state == BeamState.TELEGRAPH:
		var time_ms: float = float(Time.get_ticks_msec())
		var flicker: float = 0.35 + sin(time_ms * 0.03) * 0.15
		var t_color: Color = Color(1.0, 0.35, 0.2, flicker) if not is_enraged else Color(1.0, 0.2, 0.4, flicker)
		draw_line(start_pt, end_pt, t_color, 2.0)
		draw_circle(start_pt, 6.0 + sin(time_ms * 0.02) * 2.0, Color(t_color.r, t_color.g, t_color.b, 0.65))
		return

	# 2. FIRING & FADING STATES: Full multi-layer energy ray
	var a: float = current_alpha
	if a <= 0.01:
		return

	var time_ms: float = float(Time.get_ticks_msec())
	var pulse: float = 1.0 + sin(time_ms * 0.04) * 0.12
	var s: float = beam_scale

	# Color scheme configuration: Solar Gold (normal) vs Cosmic Nova (enraged)
	var col_aura: Color = Color(1.0, 0.40, 0.10, 0.24 * a) if not is_enraged else Color(1.0, 0.15, 0.30, 0.28 * a)
	var col_mid: Color = Color(1.0, 0.68, 0.18, 0.72 * a) if not is_enraged else Color(1.0, 0.28, 0.45, 0.78 * a)
	var col_core: Color = Color(1.0, 0.95, 0.65, 0.95 * a) if not is_enraged else Color(1.0, 0.88, 0.92, 0.95 * a)
	var col_filament: Color = Color(1.0, 1.0, 1.0, 1.0 * a)

	# Layer 1: Outer Neon Aura / Halo
	draw_line(start_pt, end_pt, col_aura, outer_aura_width * s * pulse)

	# Layer 2: Vibrant Mid-Beam Glow (Solar Gold / Crimson)
	draw_line(start_pt, end_pt, col_mid, mid_glow_width * s * pulse)

	# Layer 3: Inner High-Energy Core
	draw_line(start_pt, end_pt, col_core, inner_core_width * s)

	# Layer 4: White-Hot Razor Center Filament
	draw_line(start_pt, end_pt, col_filament, center_filament_width * s)

	# Layer 5: Muzzle Emitter Flare (at the ship's bow)
	var flare_r: float = muzzle_flare_radius * s * pulse
	draw_circle(start_pt, flare_r, Color(col_mid.r, col_mid.g, col_mid.b, 0.85 * a))
	draw_circle(start_pt, flare_r * 0.45, Color(1.0, 0.98, 0.95, 1.0 * a))

	# Layer 6: Player Contact Flare & Energy Discharge Spikes
	if is_hitting_player:
		var hit_local_x: float = hit_player_world_pos.x - global_position.x
		var contact_pt: Vector2 = Vector2(hit_local_x, 0.0)
		var impact_r: float = (impact_flare_radius * 0.9) * s * pulse

		draw_circle(contact_pt, impact_r, Color(col_mid.r, col_mid.g, col_mid.b, 0.85 * a))
		draw_circle(contact_pt, impact_r * 0.45, Color(1.0, 0.98, 0.98, 1.0 * a))

		# Energy discharge spikes
		var spike_len: float = impact_r * 0.9
		draw_line(contact_pt - Vector2(spike_len, 0.0), contact_pt + Vector2(spike_len, 0.0), Color(1.0, 1.0, 1.0, 0.92 * a), 2.2 * s)
		draw_line(contact_pt - Vector2(0.0, spike_len), contact_pt + Vector2(0.0, spike_len), Color(1.0, 1.0, 1.0, 0.92 * a), 2.2 * s)


# -----------------------------------------------------------------------------
# UNSTOPPABLE BEAM CONTRACT: IMMUNE TO COUNTER-SHOTS & INTERCEPTIONS
# -----------------------------------------------------------------------------

## Explicitly a no-op: player weapons cannot pop, intercept, or destroy this laser ray!
func hit_by_player_projectile() -> void:
	pass


## Explicitly a no-op: beam cannot take damage
func take_damage(_amount: int = 0) -> void:
	pass


## Explicitly a no-op: area contacts from player projectiles do not destroy the beam
func _on_area_entered(_area: Area2D) -> void:
	pass
