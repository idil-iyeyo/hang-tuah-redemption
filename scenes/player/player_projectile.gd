extends Area2D

@export var speed: float = 950.0
@export var damage: int = 1
## Pierce count for continuous laser ray and projectiles.
## For Laser: 1 = stops at 1st target, N = pierces up to N targets, <=0 or >=999 = infinite pierce.
@export var pierce: int = 1:
	set(val):
		pierce = val
		hits_remaining = val
		if is_laser and is_inside_tree():
			_update_laser_beam(0.0)
			queue_redraw()

var direction: Vector2 = Vector2.RIGHT
var hits_remaining: int = 1
var is_cannon: bool = false
var is_gatling: bool = false
var is_laser: bool = false
var hit_targets: Array[Area2D] = []
var hit_targets_list: Array[Area2D] = []
var current_hit_records: Array[Dictionary] = []

# Continuous Laser Ray State (Level 5 Quasar Laser)
# Easily adjust laser dimensions via this centralized dictionary, the exported properties, or set_beam_scale()
const LASER_BEAM_CONFIG: Dictionary = {
	"beam_scale": 3.2,             # Master thickness multiplier (Default 3.2x)
	"outer_aura_width": 42.0,      # Outer translucent neon crimson aura
	"mid_glow_width": 24.0,        # Vibrant mid-beam Quasar core
	"inner_core_width": 11.0,      # Hot pink/white inner laser core
	"center_filament_width": 4.5,  # White-hot razor filament
	"muzzle_flare_radius": 18.0,   # Glowing energy emitter at ship nozzle
	"impact_flare_radius": 24.0,   # Exploding contact flare at target
	"collision_height": 40.0,      # Hitbox vertical thickness
}

@export_group("Laser Beam Sizing")
## Master laser beam size multiplier. Change this value to easily make the laser thicker or thinner!
@export var beam_scale: float = 3.2:
	set(val):
		beam_scale = maxf(0.1, val)
		queue_redraw()

@export var outer_aura_width: float = 42.0
@export var mid_glow_width: float = 24.0
@export var inner_core_width: float = 11.0
@export var center_filament_width: float = 4.5
@export var muzzle_flare_radius: float = 18.0
@export var impact_flare_radius: float = 24.0
@export var collision_height: float = 40.0

var ray_length: float = 1920.0
var is_hitting_target: bool = false
var hit_position_world: Vector2 = Vector2.ZERO
var current_hit_target: Area2D = null
var laser_lifetime: float = 0.10
var laser_fade_timer: float = 0.0
var is_fading: bool = false
var laser_current_alpha: float = 1.0
var laser_damage_cooldown: float = 0.055
var laser_tick_timer: float = 0.0
var laser_source_node: Node2D = null
var laser_muzzle_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player_projectiles")
	area_entered.connect(_on_area_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	hits_remaining = pierce
	if is_laser and is_inside_tree():
		_update_laser_beam(0.0)
		queue_redraw()


const TEX_KERIS: Texture2D = preload("res://assets/textures/projectiles/General Bullet - Player.png")
const TEX_BANANA: Texture2D = preload("res://assets/textures/projectiles/General Bullet - Player.png")
const TEX_KARIPAP: Texture2D = preload("res://assets/textures/projectiles/Rocket Bullet - Player.png")


func _apply_sprite_scale_and_rotation(
	spr: Sprite2D,
	tex: Texture2D,
	target_len: float,
	legacy_scale: Vector2,
	legacy_rot_deg: float,
	legacy_modulate: Color = Color.WHITE
) -> void:
	if not spr or not tex:
		return

	var w: float = float(tex.get_width())
	var h: float = float(tex.get_height())
	var path: String = tex.resource_path.to_lower()

	# Detect legacy tiny 24x24 icons vs modern high-resolution custom pixel art
	var is_legacy_icon: bool = (w <= 64.0 and h <= 64.0) or path.ends_with("keris.png") or path.ends_with("banana.png") or path.ends_with("karipap.png")

	if is_legacy_icon:
		spr.scale = legacy_scale
		spr.rotation_degrees = legacy_rot_deg
		spr.modulate = legacy_modulate
	else:
		# Modern high-resolution custom pixel art sprite (e.g. 1408x768, 677x369)
		# Intelligently scale so the bullet's primary visual length matches target_len (~50-60px content)
		var max_dim: float = maxf(w, h)
		var factor: float = clampf(target_len / max_dim, 0.01, 2.0)
		spr.scale = Vector2(factor, factor)

		# Horizontal custom projectiles face forward at 0 degrees (no artificial 45 or 90 deg tilt)
		spr.rotation_degrees = 0.0

		# Preserve 100% true pixel art colors without color modulation
		spr.modulate = Color(1.0, 1.0, 1.0, 1.0)


func setup_projectile(
	dmg: int,
	prc: int,
	spd: float = 950.0,
	cannon: bool = false,
	emergency: bool = false,
	gatling: bool = false,
	laser: bool = false
) -> void:
	damage = dmg
	pierce = prc
	hits_remaining = prc
	speed = spd
	is_cannon = cannon
	is_gatling = gatling
	is_laser = laser

	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

	if spr:
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if is_laser:
		# Quasar Laser: Ancient Keris of Light (Continuous Lightning Ray)
		if spr:
			spr.texture = TEX_KERIS
			_apply_sprite_scale_and_rotation(spr, TEX_KERIS, 100.0, Vector2(2.6, 2.0), 45.0, Color(3.5, 2.2, 0.8, 1.0))
			spr.visible = false # Continuous ray is drawn via custom high-energy _draw()
		laser_lifetime = 0.10
		laser_current_alpha = 1.0
		is_fading = false
		laser_fade_timer = 0.0
		laser_tick_timer = 0.0
		if is_inside_tree():
			_update_laser_beam(0.0)
			queue_redraw()
	elif is_cannon:
		# Heavy Cannon: Rocket / Karipap Bomb
		if spr:
			spr.visible = true
			spr.texture = TEX_KARIPAP
			_apply_sprite_scale_and_rotation(spr, TEX_KARIPAP, 85.0, Vector2(3.0, 3.0), 0.0, Color(1.3, 1.15, 1.0, 1.0))
		if col and col.shape is CircleShape2D:
			col.shape.radius = 26.0
	elif is_gatling:
		# Explosive Gatling: High-Velocity Rapid Salvo
		if spr:
			spr.visible = true
			spr.texture = TEX_BANANA
			_apply_sprite_scale_and_rotation(spr, TEX_BANANA, 80.0, Vector2(2.0, 2.0), 90.0, Color(1.2, 1.2, 1.0, 1.0))
		if col and col.shape is CircleShape2D:
			col.shape.radius = 16.0
	elif emergency:
		# Free Emergency Gun: Small Emergency Bolt
		if spr:
			spr.visible = true
			spr.texture = TEX_BANANA
			_apply_sprite_scale_and_rotation(spr, TEX_BANANA, 70.0, Vector2(1.5, 1.5), 90.0, Color(1.0, 1.0, 1.0, 1.0))
		if col and col.shape is CircleShape2D:
			col.shape.radius = 12.0
	elif dmg >= 2:
		# Level 2 Dual Blaster: Dual Blaster Projectiles
		if spr:
			spr.visible = true
			spr.texture = TEX_KERIS
			_apply_sprite_scale_and_rotation(spr, TEX_KERIS, 100.0, Vector2(2.0, 1.8), 45.0, Color(1.4, 1.3, 1.0, 1.0))
		if col and col.shape is CircleShape2D:
			col.shape.radius = 15.0
	else:
		# Level 1 Blaster: Swift Blaster Projectile
		if spr:
			spr.visible = true
			spr.texture = TEX_KERIS
			_apply_sprite_scale_and_rotation(spr, TEX_KERIS, 85.0, Vector2(1.8, 1.6), 45.0, Color(1.0, 1.0, 1.0, 1.0))
		if col and col.shape is CircleShape2D:
			col.shape.radius = 14.0


func set_emergency_style() -> void:
	setup_projectile(1, 1, 750.0, false, true, false, false)


## Easily adjust laser beam scale multiplier (e.g. 1.0 = normal, 1.6 = big, 2.0 = massive)
func set_beam_scale(new_scale: float) -> void:
	beam_scale = maxf(0.1, new_scale)
	if is_inside_tree():
		queue_redraw()


## Easily configure laser beam visual dimensions via a custom dictionary
func set_laser_config(cfg: Dictionary) -> void:
	if cfg.has("beam_scale"):
		beam_scale = float(cfg.get("beam_scale", 1.6))
	if cfg.has("pierce"):
		set_laser_pierce(int(cfg.get("pierce", 1)))
	if cfg.has("outer_aura_width"):
		outer_aura_width = float(cfg.get("outer_aura_width", 42.0))
	if cfg.has("mid_glow_width"):
		mid_glow_width = float(cfg.get("mid_glow_width", 24.0))
	if cfg.has("inner_core_width"):
		inner_core_width = float(cfg.get("inner_core_width", 11.0))
	if cfg.has("center_filament_width"):
		center_filament_width = float(cfg.get("center_filament_width", 4.5))
	if cfg.has("muzzle_flare_radius"):
		muzzle_flare_radius = float(cfg.get("muzzle_flare_radius", 18.0))
	if cfg.has("impact_flare_radius"):
		impact_flare_radius = float(cfg.get("impact_flare_radius", 24.0))
	if cfg.has("collision_height"):
		collision_height = float(cfg.get("collision_height", 40.0))
	if is_inside_tree():
		queue_redraw()


## Easily adjust laser beam pierce count (1 = single target, N = up to N targets, <=0 or >=999 = infinite)
func set_laser_pierce(new_pierce: int) -> void:
	pierce = new_pierce
	hits_remaining = new_pierce
	if is_laser and is_inside_tree():
		_update_laser_beam(0.0)
		queue_redraw()


## Returns current laser beam pierce count
func get_laser_pierce() -> int:
	return pierce


## Anchors laser origin to the player/gun so moving the ship sweeps the beam seamlessly
func set_source_tracking(source: Node2D, offset: Vector2 = Vector2.ZERO) -> void:
	laser_source_node = source
	laser_muzzle_offset = offset
	if is_instance_valid(source) and is_inside_tree():
		global_position = source.global_position + offset
		_update_laser_beam(0.0)


## Updates laser origin to follow ship muzzle position smoothly
func update_laser_origin(new_origin: Vector2) -> void:
	global_position = new_origin
	if is_laser and is_inside_tree():
		_update_laser_beam(0.0)


## Sustains the active beam continuously when the player holds the firing button
func sustain(new_origin: Vector2, new_dmg: int = -1, new_scale: float = -1.0, new_pierce: int = -9999) -> void:
	if new_dmg > 0:
		damage = new_dmg
	if new_scale > 0.0:
		beam_scale = new_scale
	if new_pierce != -9999:
		pierce = new_pierce
		hits_remaining = new_pierce
	global_position = new_origin
	laser_lifetime = 0.10
	is_fading = false
	laser_fade_timer = 0.0
	laser_current_alpha = 1.0

	# Process immediate damage tick if timer expired
	if laser_tick_timer <= 0.0:
		laser_tick_timer = laser_damage_cooldown
		_apply_beam_damage_all()

	if is_inside_tree():
		_update_laser_beam(0.0)
		queue_redraw()


func _physics_process(delta: float) -> void:
	if is_laser:
		if is_inside_tree():
			_update_laser_beam(delta)
	else:
		position += direction * speed * delta


func _update_laser_beam(delta: float) -> void:
	# Guard: Prevent accessing SceneTree or Viewport when outside active tree
	if not is_inside_tree():
		return

	# 1. Track source position if set
	if is_instance_valid(laser_source_node):
		global_position = laser_source_node.global_position + laser_muzzle_offset

	# 2. Dynamically calculate ray intersection with pierced targets or screen edge
	var hit_info: Dictionary = _calculate_beam_hit()
	ray_length = float(hit_info.get("length", 1920.0))
	is_hitting_target = bool(hit_info.get("is_hitting", false))
	current_hit_target = hit_info.get("target", null) as Area2D
	hit_position_world = hit_info.get("hit_pos", global_position + Vector2(ray_length, 0.0))
	current_hit_records = hit_info.get("hit_records", [])
	hit_targets_list.clear()
	for rec in current_hit_records:
		var n = rec.get("node", null)
		if n is Area2D and is_instance_valid(n):
			hit_targets_list.append(n)

	# 3. Synchronize CollisionShape2D with beam length and scaled thickness
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		if not (col.shape is RectangleShape2D):
			col.shape = RectangleShape2D.new()
		var rect: RectangleShape2D = col.shape as RectangleShape2D
		rect.size = Vector2(ray_length, collision_height * beam_scale)
		col.position = Vector2(ray_length * 0.5, 0.0)

	# 4. Handle periodic damage application to all pierced targets
	laser_tick_timer -= delta
	if laser_tick_timer <= 0.0:
		laser_tick_timer = laser_damage_cooldown
		_apply_beam_damage_all()

	# 5. Handle beam decay and smooth fading when not sustained
	laser_lifetime -= delta
	if laser_lifetime <= 0.0:
		is_fading = true
		laser_fade_timer += delta
		laser_current_alpha = clampf(1.0 - (laser_fade_timer / 0.08), 0.0, 1.0)
		if laser_fade_timer >= 0.08:
			queue_free()
			return
	else:
		is_fading = false
		laser_fade_timer = 0.0
		laser_current_alpha = 1.0

	queue_redraw()


func _calculate_beam_hit() -> Dictionary:
	# Guard: If node is not inside scene tree, return safe default without querying get_tree()
	if not is_inside_tree():
		return {
			"length": 1920.0,
			"target": null,
			"targets": [],
			"hit_records": [],
			"hit_pos": global_position + Vector2(1920.0, 0.0),
			"is_hitting": false
		}

	var screen_max_x: float = 1960.0
	var vp: Viewport = get_viewport()
	if vp:
		var vp_rect: Rect2 = vp.get_visible_rect()
		if vp_rect.size.x > 0.0:
			screen_max_x = vp_rect.size.x + 50.0

	var max_length: float = maxf(50.0, screen_max_x - global_position.x)
	var my_y: float = global_position.y
	var my_x: float = global_position.x
	var beam_tolerance: float = (collision_height * 0.5 * beam_scale)

	var candidates: Array = []
	var tree: SceneTree = get_tree()
	if tree:
		candidates.append_array(tree.get_nodes_in_group("enemy_units"))
		candidates.append_array(tree.get_nodes_in_group("enemy_projectiles"))

	var seen_areas: Dictionary = {}
	var corridor_hits: Array[Dictionary] = []

	for node in candidates:
		if not is_instance_valid(node) or not (node is Area2D):
			continue
		var area: Area2D = node as Area2D
		if seen_areas.has(area):
			continue
		seen_areas[area] = true

		if not area.is_inside_tree() or not area.visible:
			continue

		var target_pos: Vector2 = area.global_position
		# Must be in front of the laser origin
		if target_pos.x < my_x - 10.0:
			continue

		# Determine target horizontal & vertical collision extent
		var half_h: float = 35.0
		var half_w: float = 35.0
		var c_shape: CollisionShape2D = area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if c_shape and c_shape.shape:
			if c_shape.shape is CircleShape2D:
				var r: float = (c_shape.shape as CircleShape2D).radius * c_shape.global_scale.x
				half_h = r
				half_w = r
			elif c_shape.shape is RectangleShape2D:
				var ext: Vector2 = (c_shape.shape as RectangleShape2D).size * 0.5 * c_shape.global_scale
				half_w = ext.x
				half_h = ext.y

		# Vertical corridor check (beam thickness tolerance scaled with beam size)
		if absf(target_pos.y - my_y) <= (half_h + beam_tolerance):
			var dist_front: float = maxf(0.0, (target_pos.x - half_w) - my_x)
			var dist_center: float = maxf(0.0, target_pos.x - my_x)
			var hit_pos: Vector2 = Vector2(target_pos.x - half_w, my_y)
			corridor_hits.append({
				"node": area,
				"dist_front": dist_front,
				"dist_center": dist_center,
				"hit_pos": hit_pos,
				"target_pos": target_pos,
				"half_w": half_w
			})

	# Sort corridor hits from nearest to farthest along X
	corridor_hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["dist_front"]) < float(b["dist_front"])
	)

	var is_infinite: bool = (pierce <= 0 or pierce >= 999)
	var allowed_hits: int = corridor_hits.size() if is_infinite else mini(pierce, corridor_hits.size())
	var hit_records: Array[Dictionary] = []
	var hit_nodes: Array[Area2D] = []

	for i in range(allowed_hits):
		var rec: Dictionary = corridor_hits[i]
		hit_records.append(rec)
		hit_nodes.append(rec["node"])

	var beam_len: float = max_length
	if not is_infinite and corridor_hits.size() >= pierce and pierce > 0:
		# Beam reaches up to the N-th target and terminates at its front surface
		var terminal_rec: Dictionary = corridor_hits[pierce - 1]
		beam_len = maxf(10.0, float(terminal_rec["dist_front"]))
	else:
		# Pierces through all targets present in corridor; beam reaches screen edge
		beam_len = max_length

	var first_target: Area2D = hit_nodes[0] if not hit_nodes.is_empty() else null
	var first_hit_pos: Vector2 = hit_records[0]["hit_pos"] if not hit_records.is_empty() else (global_position + Vector2(beam_len, 0.0))

	return {
		"length": beam_len,
		"target": first_target,
		"targets": hit_nodes,
		"hit_records": hit_records,
		"hit_pos": first_hit_pos,
		"is_hitting": not hit_records.is_empty()
	}


func _apply_beam_damage_all() -> void:
	if current_hit_records.is_empty():
		if is_hitting_target and is_instance_valid(current_hit_target):
			_apply_beam_damage(current_hit_target, hit_position_world)
		return
	for rec in current_hit_records:
		var target: Area2D = rec.get("node", null) as Area2D
		var hit_pt: Vector2 = rec.get("hit_pos", Vector2.ZERO)
		if is_instance_valid(target) and target.is_inside_tree():
			_apply_beam_damage(target, hit_pt)


func _apply_beam_damage(target: Area2D, impact_pt: Vector2) -> void:
	if not is_instance_valid(target):
		return

	if target.is_in_group("enemy_projectiles"):
		if target.has_method("hit_by_player_projectile"):
			target.hit_by_player_projectile()
		elif target.has_method("take_damage"):
			target.take_damage(damage)
	elif target.is_in_group("heavy_enemies") or target.is_in_group("bile_spewers") or target.is_in_group("boss") or target.is_in_group("enemy_units") or target.has_method("take_damage"):
		target.take_damage(damage)

	_trigger_laser_impact(impact_pt)


func _draw() -> void:
	if not is_laser or ray_length <= 0.0:
		return

	var a: float = laser_current_alpha
	if a <= 0.01:
		return

	var start_pt: Vector2 = Vector2.ZERO
	var end_pt: Vector2 = Vector2(ray_length, 0.0)

	# High-frequency procedural energy hum flicker
	var time_ms: float = float(Time.get_ticks_msec())
	var pulse: float = 1.0 + sin(time_ms * 0.04) * 0.12
	var s: float = beam_scale

	# 1. Outer Neon Aura / Halo (Enlarged & punchy)
	draw_line(start_pt, end_pt, Color(1.0, 0.15, 0.35, 0.22 * a), outer_aura_width * s * pulse)

	# 2. Vibrant Mid-Beam Glow (Quasar Crimson / Magenta)
	draw_line(start_pt, end_pt, Color(1.0, 0.28, 0.50, 0.68 * a), mid_glow_width * s * pulse)

	# 3. Inner High-Energy Core
	draw_line(start_pt, end_pt, Color(1.0, 0.85, 0.92, 0.95 * a), inner_core_width * s)

	# 4. White-Hot Center Filament
	draw_line(start_pt, end_pt, Color(1.0, 1.0, 1.0, 1.0 * a), center_filament_width * s)

	# 5. Muzzle Emitter Flare (at ship nozzle)
	draw_circle(start_pt, muzzle_flare_radius * s * pulse, Color(1.0, 0.25, 0.45, 0.80 * a))
	draw_circle(start_pt, (muzzle_flare_radius * 0.45) * s * pulse, Color(1.0, 0.95, 0.95, 1.0 * a))

	# 6. Multi-Target Impact Flares & Crackling Energy Spikes
	if is_hitting_target:
		var drawn_points: Array[float] = []
		for rec in current_hit_records:
			var hit_dist: float = float(rec.get("dist_front", 0.0))
			# If penetrated target is well before the beam terminus, draw flare at target center
			if hit_dist < ray_length - 15.0:
				hit_dist = float(rec.get("dist_center", hit_dist))
			hit_dist = clampf(hit_dist, 0.0, ray_length)

			# Avoid duplicate overlapping flares
			var too_close: bool = false
			for dp in drawn_points:
				if absf(dp - hit_dist) < 12.0:
					too_close = true
					break
			if too_close:
				continue
			drawn_points.append(hit_dist)

			var flare_pt: Vector2 = Vector2(hit_dist, 0.0)
			var flare_r: float = (impact_flare_radius * 0.85) * s * pulse
			draw_circle(flare_pt, flare_r, Color(1.0, 0.28, 0.50, 0.85 * a))
			draw_circle(flare_pt, (flare_r * 0.45), Color(1.0, 0.98, 0.98, 1.0 * a))
			var spike_l: float = flare_r * 0.9
			draw_line(flare_pt - Vector2(spike_l, 0.0), flare_pt + Vector2(spike_l, 0.0), Color(1.0, 1.0, 1.0, 0.92 * a), 2.5 * s)
			draw_line(flare_pt - Vector2(0.0, spike_l), flare_pt + Vector2(0.0, spike_l), Color(1.0, 1.0, 1.0, 0.92 * a), 2.5 * s)

		# Ensure terminal impact flare is drawn at beam terminus if terminated at a target
		var has_end_flare: bool = false
		for dp in drawn_points:
			if absf(dp - ray_length) < 15.0:
				has_end_flare = true
				break
		if not has_end_flare and (ray_length < 1920.0 or drawn_points.is_empty()):
			draw_circle(end_pt, impact_flare_radius * s * pulse, Color(1.0, 0.28, 0.50, 0.85 * a))
			draw_circle(end_pt, (impact_flare_radius * 0.45) * s * pulse, Color(1.0, 0.98, 0.98, 1.0 * a))
			var spike_len: float = (impact_flare_radius * 0.9) * s * pulse
			draw_line(end_pt - Vector2(spike_len, 0.0), end_pt + Vector2(spike_len, 0.0), Color(1.0, 1.0, 1.0, 0.92 * a), 2.5 * s)
			draw_line(end_pt - Vector2(0.0, spike_len), end_pt + Vector2(0.0, spike_len), Color(1.0, 1.0, 1.0, 0.92 * a), 2.5 * s)


func _on_area_entered(area: Area2D) -> void:
	if is_laser:
		return # Laser handles hits continuously via line-of-sight ray query & damage ticks

	if area in hit_targets or not is_instance_valid(area):
		return
	hit_targets.append(area)

	var hit_valid: bool = false
	if area.is_in_group("enemy_projectiles"):
		if area.has_method("hit_by_player_projectile"):
			area.hit_by_player_projectile()
		hit_valid = true
	elif area.is_in_group("heavy_enemies") or area.is_in_group("bile_spewers") or area.is_in_group("boss") or area.has_method("take_damage"):
		area.take_damage(damage)
		hit_valid = true

	if hit_valid:
		if is_cannon:
			_trigger_cannon_explosion(area.global_position)
		elif is_gatling:
			_trigger_gatling_explosion(area.global_position)
		elif is_laser:
			_trigger_laser_impact(area.global_position)

		hits_remaining -= 1
		if hits_remaining <= 0:
			queue_free()
		else:
			# Piercing punch-through visual pulse
			var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
			if spr:
				var tween: Tween = create_tween()
				tween.tween_property(spr, "scale", spr.scale * 1.25, 0.04)
				tween.tween_property(spr, "scale", spr.scale, 0.04)


## Procedural Radial Explosion using draw_circle() to replace raster icon.svg graphics
class RadialExplosionEffect extends Node2D:
	var current_radius: float = 12.0
	var alpha_factor: float = 1.0
	var core_color: Color = Color(1.0, 0.95, 0.85, 1.0)
	var mid_color: Color = Color(1.0, 0.60, 0.15, 0.85)
	var ring_color: Color = Color(1.0, 0.25, 0.10, 0.60)
	var has_shockwave_ring: bool = true
	var ring_thickness: float = 3.5

	func _draw() -> void:
		var r: float = current_radius
		var a: float = clampf(alpha_factor, 0.0, 1.0)
		if r <= 0.5 or a <= 0.005:
			return

		# 1. Outer Shockwave Ring (translucent expanding circle outline)
		if has_shockwave_ring and r > 8.0:
			var ring_col: Color = ring_color
			ring_col.a = ring_color.a * a * 0.75
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, ring_col, ring_thickness)

		# 2. Main Blast Wave Fill (semi-transparent fiery radial circle)
		var fill_col: Color = mid_color
		fill_col.a = mid_color.a * a * 0.55
		draw_circle(Vector2.ZERO, r * 0.85, fill_col)

		# 3. Secondary Radiant Plasma Glow
		var glow_col: Color = mid_color
		glow_col.a = mid_color.a * a * 0.85
		draw_circle(Vector2.ZERO, r * 0.55, glow_col)

		# 4. Dense High-Energy Core
		var core_col: Color = core_color
		core_col.a = core_color.a * a
		draw_circle(Vector2.ZERO, r * 0.28, core_col)

	func update_explosion(new_radius: float, new_alpha: float) -> void:
		current_radius = new_radius
		alpha_factor = new_alpha
		queue_redraw()


func _trigger_cannon_explosion(epicenter: Vector2) -> void:
	var parent_node: Node = get_parent()
	if not parent_node:
		return

	# 1. Shockwave Explosion Visual Effect (Procedural draw_circle radial explosion)
	var explosion: RadialExplosionEffect = RadialExplosionEffect.new()
	explosion.position = epicenter
	explosion.core_color = Color(1.0, 0.95, 0.85, 1.0)
	explosion.mid_color = Color(1.0, 0.55, 0.15, 0.85)
	explosion.ring_color = Color(1.0, 0.25, 0.10, 0.70)
	explosion.current_radius = 14.0
	explosion.alpha_factor = 1.0
	explosion.ring_thickness = 4.0
	parent_node.add_child(explosion)

	var tween: Tween = parent_node.create_tween()
	tween.tween_method(
		func(progress: float):
			if is_instance_valid(explosion):
				var r: float = lerpf(14.0, 105.0, progress)
				var a: float = pow(1.0 - progress, 1.4)
				explosion.update_explosion(r, a),
		0.0,
		1.0,
		0.22
	)
	tween.tween_callback(func():
		if is_instance_valid(explosion):
			explosion.queue_free()
	)

	# 2. Area-Of-Effect (AOE) Splash Damage (Radius 95 px)
	var blast_radius: float = 95.0
	for child in parent_node.get_children():
		if not is_instance_valid(child) or child == self:
			continue
		if child is Area2D:
			var dist: float = epicenter.distance_to(child.global_position)
			if dist <= blast_radius:
				if child.is_in_group("enemy_projectiles"):
					if child.has_method("hit_by_player_projectile"):
						child.hit_by_player_projectile()
				elif child.is_in_group("enemy_units") or child.has_method("take_damage"):
					# Deal 4 AOE explosion damage to adjacent enemies caught in the blast
					child.take_damage(4)


func _trigger_gatling_explosion(epicenter: Vector2) -> void:
	var parent_node: Node = get_parent()
	if not parent_node:
		return

	# 1. Compact Explosion Visual Burst (Procedural draw_circle radial explosion)
	var explosion: RadialExplosionEffect = RadialExplosionEffect.new()
	explosion.position = epicenter
	explosion.core_color = Color(1.0, 0.98, 0.90, 1.0)
	explosion.mid_color = Color(1.0, 0.70, 0.20, 0.85)
	explosion.ring_color = Color(1.0, 0.40, 0.15, 0.65)
	explosion.current_radius = 8.0
	explosion.alpha_factor = 1.0
	explosion.ring_thickness = 2.5
	parent_node.add_child(explosion)

	var tween: Tween = parent_node.create_tween()
	tween.tween_method(
		func(progress: float):
			if is_instance_valid(explosion):
				var r: float = lerpf(8.0, 52.0, progress)
				var a: float = pow(1.0 - progress, 1.5)
				explosion.update_explosion(r, a),
		0.0,
		1.0,
		0.14
	)
	tween.tween_callback(func():
		if is_instance_valid(explosion):
			explosion.queue_free()
	)

	# 2. Small Area Damage (Radius 48 px, deals 2 splash damage)
	var blast_radius: float = 48.0
	for child in parent_node.get_children():
		if not is_instance_valid(child) or child == self:
			continue
		if child is Area2D:
			var dist: float = epicenter.distance_to(child.global_position)
			if dist <= blast_radius:
				if child.is_in_group("enemy_projectiles"):
					if child.has_method("hit_by_player_projectile"):
						child.hit_by_player_projectile()
				elif child.is_in_group("enemy_units") or child.has_method("take_damage"):
					child.take_damage(2)


func _trigger_laser_impact(epicenter: Vector2) -> void:
	var parent_node: Node = get_parent()
	if not parent_node:
		return

	# Laser impact flash (Procedural draw_circle radial spark)
	var explosion: RadialExplosionEffect = RadialExplosionEffect.new()
	explosion.position = epicenter
	explosion.core_color = Color(1.0, 1.0, 1.0, 1.0)
	explosion.mid_color = Color(1.0, 0.25, 0.40, 0.90)
	explosion.ring_color = Color(1.0, 0.15, 0.30, 0.70)
	explosion.current_radius = 6.0
	explosion.alpha_factor = 1.0
	explosion.ring_thickness = 2.0
	parent_node.add_child(explosion)

	var tween: Tween = parent_node.create_tween()
	tween.tween_method(
		func(progress: float):
			if is_instance_valid(explosion):
				var r: float = lerpf(6.0, 28.0, progress)
				var a: float = pow(1.0 - progress, 1.6)
				explosion.update_explosion(r, a),
		0.0,
		1.0,
		0.09
	)
	tween.tween_callback(func():
		if is_instance_valid(explosion):
			explosion.queue_free()
	)


func _on_screen_exited() -> void:
	if not is_laser:
		queue_free()
