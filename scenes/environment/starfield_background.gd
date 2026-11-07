extends Control

const SaveManager = preload("res://scripts/save_manager.gd")

## Gameplay Background Arts Engine for Space Shooter 2D
## Supports 4-Sector campaign backgrounds configured via Dictionary:
## - Sector 1 (Stages 1-5): Deep Nebula Frontier (KlccBackground.png)
## - Sector 2 (Stages 6-10): Solar Hazard & Cosmic Rift (KotaAFamosaBackground.png)
## - Sector 3 (Stages 11-15): Asteroid Perimeter (RumahMinangKabauxIstanaAwanBackground.png)
## - Sector 4 (Stages 16-20): Alien Void Citadel (LembahKerisXGunungLedang.png)
## Features mathematically seamless horizontal infinite repeating, smooth cinematic
## sector crossfades, dynamic warp acceleration surges, and modular atmospheric effects.

class Star:
	var x: float
	var y: float
	var speed: float
	var size: float
	var base_alpha: float
	var current_alpha: float
	var twinkle_phase: float
	var twinkle_speed: float
	var layer: int # 0: distant, 1: mid
	var streak_len: float

class ShootingStar:
	var pos: Vector2
	var vel: Vector2
	var length: float
	var life: float
	var max_life: float
	var width: float

## Master Dictionary defining background configurations for all 4 campaign sectors.
## To replace a background with your own PNG:
## 1. Drop your PNG into res://assets/textures/backgrounds/ (or any res:// path)
## 2. Update the "texture_path" in this Dictionary below to point to your new PNG
## 3. The engine automatically loads, scales, and repeats it seamlessly!
const BACKGROUND_DICTIONARY: Dictionary = {
	1: {
		"name": "Sector 1: Kuala Lumpur Cyberpunk(Stages 1-5)",
		"stage_min": 1,
		"stage_max": 5,
		"texture_path": "res://assets/textures/backgrounds/KlccBackground.png",
		"scroll_speed": 40.0,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"enable_stars": true,
		"enable_shooting_stars": false,
		"star_alpha": 0.85
	},
	2: {
		"name": "Sector 2: Kota A Famosa Cyberpunk(Stages 6-10)",
		"stage_min": 6,
		"stage_max": 10,
		"texture_path": "res://assets/textures/backgrounds/KotaAFamosaBackground.png",
		"scroll_speed": 55.0,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"enable_stars": true,
		"enable_shooting_stars": false,
		"star_alpha": 0.75
	},
	3: {
		"name": "Sector 3: Minangkabao Blackwall(Stages 11-15)",
		"stage_min": 11,
		"stage_max": 15,
		"texture_path": "res://assets/textures/backgrounds/RumahMinangKabauxIstanaAwanBackground.png",
		"scroll_speed": 70.0,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"enable_stars": true,
		"enable_shooting_stars": true,
		"star_alpha": 0.65
	},
	4: {
		"name": "Sector 4: Keris Sanctuary (Stages 16-20)",
		"stage_min": 16,
		"stage_max": 20,
		"texture_path": "res://assets/textures/backgrounds/LembahKerisXGunungLedang.png",
		"scroll_speed": 90.0,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"enable_stars": true,
		"enable_shooting_stars": true,
		"star_alpha": 0.50
	}
}

@export_group("Background System")
## Exported dictionary allowing Inspector customization without altering code.
@export var background_sectors: Dictionary = BACKGROUND_DICTIONARY.duplicate(true)
## Toggle background texture rendering.
@export var enable_background_texture: bool = true
## Base speed scale applied to both background textures and stars.
@export var speed_scale: float = 1.0

@export_group("Sector Transitions")
## Duration of the smooth crossfade transition between sectors in seconds.
@export var transition_duration: float = 1.4
## Enable dynamic warp acceleration surge during sector transitions.
@export var enable_warp_surge: bool = true
## Intensity of the warp speed surge curve (0.0 = no surge, 0.4 = moderate surge).
@export var warp_surge_intensity: float = 0.35

@export_group("Atmospheric Effects")
## Toggle moving procedural white stars.
@export var enable_stars: bool = true
## Toggle shooting stars / meteors.
@export var enable_shooting_stars: bool = true
@export var distant_star_count: int = 130
@export var mid_star_count: int = 70

# Runtime state
var current_stage: int = 1
var current_sector_index: int = 1
var current_texture: Texture2D = null
var current_scroll_speed: float = 40.0
var current_tint: Color = Color.WHITE
var current_star_alpha_multiplier: float = 1.0
var sector_enable_stars: bool = true
var sector_enable_shooting_stars: bool = true

# Smooth crossfade transition runtime state
var previous_texture: Texture2D = null
var prev_scroll_offset_x: float = 0.0
var prev_scroll_speed: float = 40.0
var previous_tint: Color = Color.WHITE
var prev_star_alpha_multiplier: float = 1.0
var target_scroll_speed: float = 40.0
var target_tint: Color = Color.WHITE
var target_star_alpha_multiplier: float = 1.0
var transition_progress: float = 1.0 # 1.0 = transition complete, < 1.0 = actively crossfading

# Seamless infinite horizontal repeating state
var bg_scroll_offset_x: float = 0.0
var _texture_cache: Dictionary = {}

# Starfield & Meteor arrays
var stars: Array[Star] = []
var shooting_stars: Array[ShootingStar] = []
var shooting_star_timer: float = 0.0
var next_shooting_star_interval: float = 5.0
var nebula_spots: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_stars()
	var initial_stage: int = 1
	if SaveManager:
		initial_stage = SaveManager.get_last_played_level()
	transition_to_stage(initial_stage, true)


func _init_stars() -> void:
	stars.clear()
	var vp: Vector2 = _get_screen_size()
	var s: Star = null

	# Layer 0: Distant slow tiny stars
	for i in range(distant_star_count):
		s = Star.new()
		s.x = randf_range(0.0, vp.x)
		s.y = randf_range(0.0, vp.y)
		s.speed = randf_range(45.0, 95.0)
		s.size = randf_range(1.0, 1.8)
		s.base_alpha = randf_range(0.35, 0.65)
		s.current_alpha = s.base_alpha
		s.twinkle_phase = randf_range(0.0, TAU)
		s.twinkle_speed = randf_range(1.5, 3.5)
		s.layer = 0
		s.streak_len = 0.0
		stars.append(s)

	# Layer 1: Mid-field stars (steady white stars)
	for i in range(mid_star_count):
		s = Star.new()
		s.x = randf_range(0.0, vp.x)
		s.y = randf_range(0.0, vp.y)
		s.speed = randf_range(160.0, 290.0)
		s.size = randf_range(2.0, 2.9)
		s.base_alpha = randf_range(0.65, 0.90)
		s.current_alpha = s.base_alpha
		s.twinkle_phase = randf_range(0.0, TAU)
		s.twinkle_speed = randf_range(2.0, 4.5)
		s.layer = 1
		s.streak_len = randf_range(1.5, 3.5)
		stars.append(s)


func _get_screen_size() -> Vector2:
	var s: Vector2 = size
	if (s.x <= 10.0 or s.y <= 10.0) and is_inside_tree():
		s = get_viewport_rect().size
	if s.x <= 10.0 or s.y <= 10.0:
		s = Vector2(1920.0, 1080.0)
	return s


## Sets the current campaign stage (1 to 20) with smooth cinematic crossfade transition between sectors.
func set_stage(stage_num: int) -> void:
	transition_to_stage(stage_num, false)


## Transitions to target stage with optional instant override (useful on cold boot or reset).
func transition_to_stage(stage_num: int, force_instant: bool = false) -> void:
	var target_stage: int = clampi(stage_num, 1, 20)
	var config: Dictionary = get_sector_config_for_stage(target_stage)
	var new_texture: Texture2D = _load_sector_texture(config)

	var target_speed: float = float(config.get("scroll_speed", 50.0))
	var target_c_tint: Color = config.get("tint", Color.WHITE)
	var target_s_alpha: float = float(config.get("star_alpha", 1.0))
	sector_enable_stars = bool(config.get("enable_stars", true))
	sector_enable_shooting_stars = bool(config.get("enable_shooting_stars", true))

	# 1. Cold boot or forced instant change
	if force_instant or current_texture == null:
		current_stage = target_stage
		current_texture = new_texture
		previous_texture = null
		transition_progress = 1.0
		current_scroll_speed = target_speed
		target_scroll_speed = target_speed
		current_tint = target_c_tint
		target_tint = target_c_tint
		current_star_alpha_multiplier = target_s_alpha
		target_star_alpha_multiplier = target_s_alpha
		queue_redraw()
		return

	# 2. Same texture / same sector (e.g. Stage 1 -> Stage 2): continue smoothly with zero interruption
	if new_texture == current_texture:
		current_stage = target_stage
		target_scroll_speed = target_speed
		target_tint = target_c_tint
		target_star_alpha_multiplier = target_s_alpha
		if transition_progress >= 1.0:
			current_scroll_speed = target_speed
			current_tint = target_c_tint
			current_star_alpha_multiplier = target_s_alpha
		queue_redraw()
		return

	# 3. Inter-sector transition (e.g. Stage 5 in Sector 1 -> Stage 6 in Sector 2):
	# Initiate cinematic cross-dissolve & warp surge!
	current_stage = target_stage
	previous_texture = current_texture
	prev_scroll_offset_x = bg_scroll_offset_x
	prev_scroll_speed = current_scroll_speed
	previous_tint = current_tint
	prev_star_alpha_multiplier = current_star_alpha_multiplier

	current_texture = new_texture
	# Synchronize incoming offset to maintain smooth continuous visual motion
	bg_scroll_offset_x = prev_scroll_offset_x

	target_scroll_speed = target_speed
	target_tint = target_c_tint
	target_star_alpha_multiplier = target_s_alpha
	transition_progress = 0.0

	queue_redraw()


## Looks up the sector configuration Dictionary matching the requested stage number.
func get_sector_config_for_stage(stage_num: int) -> Dictionary:
	# 1. Search by stage_min / stage_max range
	for key in background_sectors:
		var item: Variant = background_sectors[key]
		if item is Dictionary:
			var s_min: int = int(item.get("stage_min", 0))
			var s_max: int = int(item.get("stage_max", 0))
			if s_min > 0 and s_max >= s_min and stage_num >= s_min and stage_num <= s_max:
				return item

	# 2. Key mapping by sector index (1 to 4)
	var sector_idx: int = clampi(((stage_num - 1) / 5) + 1, 1, 4)
	if background_sectors.has(sector_idx) and background_sectors[sector_idx] is Dictionary:
		return background_sectors[sector_idx]

	# 3. String key mapping ("sector_1", "1-5", etc.)
	var str_key: String = "sector_%d" % sector_idx
	if background_sectors.has(str_key) and background_sectors[str_key] is Dictionary:
		return background_sectors[str_key]

	# 4. Fallback to Sector 1 default
	if background_sectors.has(1) and background_sectors[1] is Dictionary:
		return background_sectors[1]
	return BACKGROUND_DICTIONARY[1]


## Allows dynamic runtime replacement of any sector's background texture.
func set_custom_background(sector_key: Variant, texture_or_path: Variant) -> void:
	if not background_sectors.has(sector_key):
		printerr("[BackgroundMaster] Unknown sector key: ", sector_key)
		return

	if texture_or_path is Texture2D:
		background_sectors[sector_key]["texture"] = texture_or_path
	elif texture_or_path is String:
		background_sectors[sector_key]["texture_path"] = texture_or_path
		if _texture_cache.has(texture_or_path):
			_texture_cache.erase(texture_or_path)

	# Re-apply if modifying currently active sector
	set_stage(current_stage)


func _load_sector_texture(config: Dictionary) -> Texture2D:
	if config.has("texture") and config["texture"] is Texture2D:
		return config["texture"]

	var path: String = str(config.get("texture_path", ""))
	if path.is_empty():
		return null

	if _texture_cache.has(path):
		return _texture_cache[path]

	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			_texture_cache[path] = tex
			return tex

	print("[BackgroundMaster] Notice: Background texture '%s' not found. Using procedural cosmic void." % path)
	return null


func _process(delta: float) -> void:
	var vp: Vector2 = _get_screen_size()

	# 1. Update smooth sector transition progress and interpolated parameters
	var warp_factor: float = 1.0
	if transition_progress < 1.0:
		transition_progress = minf(1.0, transition_progress + delta / maxf(transition_duration, 0.01))
		var blend: float = smoothstep(0.0, 1.0, transition_progress)
		current_scroll_speed = lerpf(prev_scroll_speed, target_scroll_speed, blend)
		current_tint = previous_tint.lerp(target_tint, blend)
		current_star_alpha_multiplier = lerpf(prev_star_alpha_multiplier, target_star_alpha_multiplier, blend)

		if enable_warp_surge:
			warp_factor = 1.0 + warp_surge_intensity * sin(transition_progress * PI)

		if transition_progress >= 1.0:
			previous_texture = null

	var effective_speed: float = current_scroll_speed * warp_factor * speed_scale

	# 2. Update seamless background horizontal scroll offset
	if enable_background_texture and current_texture:
		var tex_size: Vector2 = current_texture.get_size()
		var scale_y: float = vp.y / maxf(tex_size.y, 1.0)
		var display_w: float = tex_size.x * scale_y

		if display_w > 1.0:
			bg_scroll_offset_x -= effective_speed * delta
			# Seamless horizontal wraparound when passing leftmost edge
			if bg_scroll_offset_x <= -display_w:
				bg_scroll_offset_x = fmod(bg_scroll_offset_x, display_w)

	# Update previous texture offset if actively cross-dissolving
	if enable_background_texture and previous_texture and transition_progress < 1.0:
		var prev_tex_size: Vector2 = previous_texture.get_size()
		var prev_scale_y: float = vp.y / maxf(prev_tex_size.y, 1.0)
		var prev_display_w: float = prev_tex_size.x * prev_scale_y

		if prev_display_w > 1.0:
			prev_scroll_offset_x -= effective_speed * delta
			if prev_scroll_offset_x <= -prev_display_w:
				prev_scroll_offset_x = fmod(prev_scroll_offset_x, prev_display_w)

	# 3. Move passing white stars from right to left
	for s: Star in stars:
		s.x -= s.speed * speed_scale * delta
		if warp_factor > 1.0:
			s.x -= s.speed * speed_scale * delta * (warp_factor - 1.0)
		s.twinkle_phase += s.twinkle_speed * delta

		var tw: float = 0.5 + 0.5 * sin(s.twinkle_phase)
		s.current_alpha = clampf(s.base_alpha * (0.7 + 0.3 * tw), 0.15, 1.0)

		# Wrap around when passing beyond left edge
		if s.x < -30.0:
			s.x = vp.x + randf_range(5.0, 45.0)
			s.y = randf_range(0.0, vp.y)

	# 4. Update shooting stars
	if enable_shooting_stars and sector_enable_shooting_stars:
		shooting_star_timer += delta
		if shooting_star_timer >= next_shooting_star_interval:
			shooting_star_timer = 0.0
			next_shooting_star_interval = randf_range(4.5, 9.0)
			_spawn_shooting_star(vp)

		var i: int = shooting_stars.size() - 1
		while i >= 0:
			var ss: ShootingStar = shooting_stars[i]
			ss.pos += ss.vel * delta
			ss.life -= delta
			if ss.life <= 0.0 or ss.pos.x < -100.0 or ss.pos.y > vp.y + 100.0:
				shooting_stars.remove_at(i)
			i -= 1

	queue_redraw()


func _spawn_shooting_star(vp: Vector2) -> void:
	var ss: ShootingStar = ShootingStar.new()
	var start_y: float = randf_range(30.0, vp.y * 0.7)
	ss.pos = Vector2(vp.x + 40.0, start_y)

	var angle: float = deg_to_rad(randf_range(185.0, 205.0)) # Heading left and slightly down
	var speed: float = randf_range(1300.0, 1850.0)
	ss.vel = Vector2.from_angle(angle) * speed
	ss.length = randf_range(90.0, 150.0)
	ss.max_life = randf_range(0.9, 1.4)
	ss.life = ss.max_life
	ss.width = randf_range(2.0, 3.2)
	shooting_stars.append(ss)


## Helper rendering multiple horizontal tiles seamlessly across viewport width
func _draw_repeating_texture(tex: Texture2D, offset_x: float, tint_color: Color, vp: Vector2) -> void:
	if not tex:
		return
	var tex_size: Vector2 = tex.get_size()
	var scale_y: float = vp.y / maxf(tex_size.y, 1.0)
	var display_w: float = tex_size.x * scale_y

	if display_w <= 1.0:
		return

	var start_x: float = fmod(offset_x, display_w)
	if start_x > 0.0:
		start_x -= display_w

	var cur_x: float = start_x
	while cur_x < vp.x:
		var tile_rect: Rect2 = Rect2(cur_x, 0.0, ceilf(display_w) + 1.0, vp.y)
		draw_texture_rect(tex, tile_rect, false, tint_color)
		cur_x += display_w


func _draw() -> void:
	var vp: Vector2 = _get_screen_size()
	var screen_rect: Rect2 = Rect2(Vector2.ZERO, vp)

	# 1. Base dark cosmic void
	draw_rect(screen_rect, Color(0.02, 0.025, 0.06, 1.0), true)

	# 2. Seamless repeating background PNG layer (with smooth crossfade support)
	if enable_background_texture:
		if previous_texture and transition_progress < 1.0:
			# Draw outgoing previous sector texture at full opacity underneath
			_draw_repeating_texture(previous_texture, prev_scroll_offset_x, previous_tint, vp)

			# Draw incoming new sector texture on top with smooth dissolve alpha
			var dissolve_alpha: float = smoothstep(0.0, 1.0, transition_progress)
			var incoming_tint: Color = Color(
				current_tint.r,
				current_tint.g,
				current_tint.b,
				current_tint.a * dissolve_alpha
			)
			_draw_repeating_texture(current_texture, bg_scroll_offset_x, incoming_tint, vp)
		elif current_texture:
			var tex_size: Vector2 = current_texture.get_size()
			var scale_y: float = vp.y / maxf(tex_size.y, 1.0)
			var display_w: float = tex_size.x * scale_y

			if display_w > 1.0:
				var start_x: float = fmod(bg_scroll_offset_x, display_w)
				if start_x > 0.0:
					start_x -= display_w

				var cur_x: float = start_x
				while cur_x < vp.x:
					var tile_rect: Rect2 = Rect2(cur_x, 0.0, ceilf(display_w) + 1.0, vp.y)
					draw_texture_rect(current_texture, tile_rect, false, current_tint)
					cur_x += display_w

	# 3. Passing white stars
	if enable_stars and sector_enable_stars:
		for s: Star in stars:
			var alpha: float = s.current_alpha * current_star_alpha_multiplier
			match s.layer:
				0:
					# Distant tiny star
					draw_circle(Vector2(s.x, s.y), s.size, Color(0.85, 0.90, 1.0, alpha))
				1:
					# Mid-distance star with subtle motion trail and faint halo
					var col: Color = Color(1.0, 1.0, 1.0, alpha)
					var halo: Color = Color(0.8, 0.9, 1.0, alpha * 0.25)
					draw_circle(Vector2(s.x, s.y), s.size * 1.6, halo)
					if s.streak_len > 1.0:
						draw_line(Vector2(s.x, s.y), Vector2(s.x + s.streak_len, s.y), col, s.size * 0.8)
					draw_circle(Vector2(s.x, s.y), s.size, col)

	# 4. Shooting stars (meteors)
	if enable_shooting_stars and sector_enable_shooting_stars:
		for ss: ShootingStar in shooting_stars:
			var progress: float = ss.life / ss.max_life
			var streak_dir: Vector2 = ss.vel.normalized()
			var tail_pos: Vector2 = ss.pos - streak_dir * ss.length
			var head_col: Color = Color(1.0, 1.0, 1.0, progress * 0.95 * current_star_alpha_multiplier)

			# Draw streak line
			draw_line(ss.pos, tail_pos, head_col, ss.width)
			# Glowing head
			draw_circle(ss.pos, ss.width * 1.5, Color(1.0, 1.0, 1.0, progress * current_star_alpha_multiplier))
