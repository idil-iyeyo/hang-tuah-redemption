extends Area2D

signal evaded
signal destroyed
signal intercepted_by_player

enum MovementType {
	DIRECT,        # Straight line with angular deviation
	WAVY,          # Transverse sinusoidal wave oscillation
	ACCELERATING,  # Starts slower, ramps up speed dynamically
	FAST_DART      # High speed straight dart
}

@export var speed: float = 450.0
@export var damage: int = 20
@export var movement_type: MovementType = MovementType.DIRECT
@export var custom_texture: Texture2D

var direction: Vector2 = Vector2.LEFT
var has_hit_target: bool = false
var is_zoning_shot: bool = false
var is_bile_shot: bool = false
var elapsed_time: float = 0.0

var custom_scale: Vector2 = Vector2.ZERO
var custom_modulate: Color = Color.WHITE
var has_custom_modulate: bool = false

# Wavy motion parameters
var base_position: Vector2 = Vector2.ZERO
var wave_frequency: float = 4.5
var wave_amplitude: float = 45.0

# Acceleration parameters
var current_speed: float = 450.0
var initial_speed: float = 300.0
var target_speed: float = 650.0
var acceleration_rate: float = 380.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func set_projectile_texture(tex: Texture2D) -> void:
	custom_texture = tex
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr and tex:
		spr.texture = tex


func set_projectile_texture_by_path(path: String) -> void:
	if path.is_empty():
		return
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			set_projectile_texture(tex)


func apply_config(config: Dictionary, fire_dir: Vector2 = Vector2.ZERO) -> void:
	if config.is_empty():
		return

	if fire_dir != Vector2.ZERO:
		direction = fire_dir.normalized()
		rotation = direction.angle()

	movement_type = config.get("movement_type", MovementType.DIRECT) as MovementType
	speed = float(config.get("speed", 450.0))
	damage = int(config.get("damage", 20))
	wave_frequency = float(config.get("wave_frequency", 4.5))
	wave_amplitude = float(config.get("wave_amplitude", 45.0))
	acceleration_rate = float(config.get("acceleration_rate", 380.0))
	is_zoning_shot = bool(config.get("is_zoning_shot", false))
	is_bile_shot = bool(config.get("is_bile_shot", false))

	if movement_type == MovementType.ACCELERATING:
		initial_speed = speed * 0.55
		current_speed = initial_speed
		target_speed = speed * 1.35
		acceleration_rate = (target_speed - initial_speed) / 1.6
	else:
		current_speed = speed

	if config.has("scale") and config["scale"] is Vector2:
		custom_scale = config["scale"]

	if config.has("modulate") and config["modulate"] is Color:
		custom_modulate = config["modulate"]
		has_custom_modulate = true

	# Texture assignment
	var tex_val = config.get("texture", null)
	if tex_val is Texture2D:
		set_projectile_texture(tex_val)
	elif tex_val is String and not (tex_val as String).is_empty():
		set_projectile_texture_by_path(tex_val)

	base_position = position
	_apply_visuals()


func _ready() -> void:
	add_to_group("enemy_projectiles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if screen_notifier:
		screen_notifier.screen_exited.connect(_on_screen_exited)
	base_position = position
	if custom_texture and sprite:
		sprite.texture = custom_texture
	_apply_visuals()


func setup(
	type: MovementType,
	proj_speed: float,
	proj_dir: Vector2,
	proj_damage: int = 20,
	wave_freq: float = 4.5,
	wave_amp: float = 45.0,
	zoning: bool = false,
	bile: bool = false
) -> void:
	movement_type = type
	speed = proj_speed
	direction = proj_dir.normalized()
	damage = proj_damage
	wave_frequency = wave_freq
	wave_amplitude = wave_amp
	is_zoning_shot = zoning
	is_bile_shot = bile
	rotation = direction.angle()
	base_position = position

	if movement_type == MovementType.ACCELERATING:
		initial_speed = proj_speed * 0.55
		current_speed = initial_speed
		target_speed = proj_speed * 1.35
		acceleration_rate = (target_speed - initial_speed) / 1.6
	else:
		current_speed = proj_speed

	_apply_visuals()


func _apply_visuals() -> void:
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if not spr:
		return

	if custom_texture:
		spr.texture = custom_texture
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if has_custom_modulate:
			spr.modulate = custom_modulate
		else:
			spr.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif has_custom_modulate:
		spr.modulate = custom_modulate
	elif is_bile_shot:
		# Toxic acid lime green for Bile Spewer projectiles
		spr.modulate = Color(0.38, 1.0, 0.22)
	elif is_zoning_shot:
		# Distinct high-visibility electric violet for predictive cut-off / zoning shots
		spr.modulate = Color(0.95, 0.2, 0.75)
	else:
		match movement_type:
			MovementType.DIRECT:
				spr.modulate = Color(1.0, 0.38, 0.2)
			MovementType.WAVY:
				spr.modulate = Color(0.85, 0.3, 1.0)
			MovementType.ACCELERATING:
				spr.modulate = Color(1.0, 0.8, 0.15)
			MovementType.FAST_DART:
				spr.modulate = Color(1.0, 0.15, 0.35)

	# Smart scaling: If high-res custom texture is used (>64px), scale dynamically unless fine-tuned (<0.15)
	if custom_texture and (custom_texture.get_width() > 64 or custom_texture.get_height() > 64):
		var max_dim: float = maxf(float(custom_texture.get_width()), float(custom_texture.get_height()))
		var target_size: float = 38.0
		var auto_factor: float = clampf(target_size / max_dim, 0.01, 1.0)
		if custom_scale != Vector2.ZERO and custom_scale.x < 0.15 and custom_scale.y < 0.15:
			spr.scale = custom_scale
		else:
			spr.scale = Vector2(auto_factor, auto_factor)
	elif custom_scale != Vector2.ZERO:
		spr.scale = custom_scale
	elif is_bile_shot:
		spr.scale = Vector2(0.32, 0.32)
	elif is_zoning_shot:
		spr.scale = Vector2(0.33, 0.28)
	else:
		match movement_type:
			MovementType.DIRECT, MovementType.WAVY, MovementType.ACCELERATING:
				spr.scale = Vector2(0.3, 0.3)
			MovementType.FAST_DART:
				spr.scale = Vector2(0.35, 0.22)


func _physics_process(delta: float) -> void:
	elapsed_time += delta

	match movement_type:
		MovementType.DIRECT:
			position += direction * speed * delta
			rotation = direction.angle()

		MovementType.WAVY:
			base_position += direction * speed * delta
			var normal: Vector2 = Vector2(-direction.y, direction.x)
			var wave_offset: Vector2 = normal * sin(elapsed_time * wave_frequency) * wave_amplitude
			position = base_position + wave_offset
			var wave_slope: float = cos(elapsed_time * wave_frequency) * (wave_amplitude * wave_frequency / maxf(1.0, speed))
			rotation = direction.angle() + clampf(wave_slope * 0.35, -0.6, 0.6)

		MovementType.ACCELERATING:
			current_speed = move_toward(current_speed, target_speed, acceleration_rate * delta)
			position += direction * current_speed * delta
			rotation = direction.angle()

		MovementType.FAST_DART:
			position += direction * speed * delta
			rotation = direction.angle()

	# Deterministic boundary safety cleanup
	if position.x < -100.0 or position.x > 2400.0 or position.y < -150.0 or position.y > 1250.0:
		destroyed.emit()
		queue_free()
		return


func hit_by_player_projectile() -> void:
	if has_hit_target:
		return
	has_hit_target = true
	intercepted_by_player.emit()
	evaded.emit()
	destroyed.emit()

	# Impact destruction pop
	set_physics_process(false)
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr:
		var tween: Tween = create_tween()
		tween.tween_property(spr, "scale", spr.scale * 1.5, 0.08)
		tween.parallel().tween_property(spr, "modulate:a", 0.0, 0.08)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_projectiles"):
		hit_by_player_projectile()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		has_hit_target = true
		if body.has_method("take_damage"):
			body.take_damage(damage)
		destroyed.emit()
		queue_free()


func _on_screen_exited() -> void:
	if not has_hit_target:
		evaded.emit()
	destroyed.emit()
	queue_free()
