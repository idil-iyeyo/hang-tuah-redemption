extends Area2D

signal destroyed
signal escaped

@export var max_health: int = 8
@export var speed: float = 210.0
@export var contact_damage: int = 25

var current_health: int = 8
var elapsed_time: float = 0.0
var shoot_timer: float = 2.5
var teleport_timer: float = 3.0
var is_teleporting: bool = false

@export var projectile_scene: PackedScene = preload("res://scenes/enemies/projectile.tscn")
@export var custom_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var base_sprite_scale: Vector2 = Vector2.ZERO


func _get_base_scale() -> Vector2:
	if base_sprite_scale != Vector2.ZERO:
		return base_sprite_scale
	if sprite:
		base_sprite_scale = sprite.scale
		return base_sprite_scale
	return Vector2(0.125, 0.125)


func set_enemy_texture(tex: Texture2D) -> void:
	custom_texture = tex
	if sprite:
		sprite.texture = tex


func _ready() -> void:
	add_to_group("void_bile")
	add_to_group("enemy_units")
	body_entered.connect(_on_body_entered)
	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)

	if custom_texture and sprite:
		sprite.texture = custom_texture

	if sprite:
		base_sprite_scale = sprite.scale
		sprite.modulate = Color(1.0, 1.0, 1.0)

	current_health = max_health
	if hp_bar:
		hp_bar.max_value = float(max_health)
		hp_bar.value = float(current_health)


func _physics_process(delta: float) -> void:
	elapsed_time += delta

	# Fast forward advance
	position.x -= speed * delta

	if position.x < -80.0:
		escaped.emit()
		queue_free()
		return

	# Teleportation cycle every 3.0 seconds
	teleport_timer -= delta
	if teleport_timer <= 0.0 and not is_teleporting:
		teleport_timer = 3.0
		_execute_teleport()

	# Single projectile shooting cycle
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(2.8, 3.4)
		_shoot_single_projectile()


func _execute_teleport() -> void:
	is_teleporting = true
	var screen_height: float = get_viewport_rect().size.y
	if screen_height <= 0.0:
		screen_height = 1080.0

	# Calculate unpredictable new Y position with sufficient separation
	var current_y: float = position.y
	var candidate_y: float = randf_range(120.0, screen_height - 120.0)
	while absf(candidate_y - current_y) < 160.0:
		candidate_y = randf_range(120.0, screen_height - 120.0)

	if sprite:
		var base_scale: Vector2 = _get_base_scale()
		var tween: Tween = create_tween()
		# Collapse into void rift (preserve relative proportion to base_scale)
		tween.tween_property(sprite, "scale", Vector2(base_scale.x * 0.05, base_scale.y * 1.25), 0.12)
		tween.parallel().tween_property(sprite, "modulate", Color(2.5, 0.8, 3.0, 0.2), 0.12)
		tween.tween_callback(func():
			position.y = candidate_y
		)
		# Emerge from void rift smoothly returning to base_scale
		tween.tween_property(sprite, "scale", base_scale * 1.15, 0.10)
		tween.parallel().tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.10)
		tween.tween_property(sprite, "scale", base_scale, 0.08)
		tween.tween_callback(func():
			is_teleporting = false
		)
	else:
		position.y = candidate_y
		is_teleporting = false


func _shoot_single_projectile() -> void:
	if not projectile_scene or is_teleporting:
		return

	var main_scene: Node = get_parent()
	if not main_scene:
		return

	var player_node: Node2D = main_scene.get_node_or_null("Player") as Node2D
	if not player_node:
		return

	# Only stop shooting if passed behind the player
	if position.x < player_node.global_position.x - 20.0:
		return

	var bullet: Area2D = projectile_scene.instantiate() as Area2D
	if not bullet:
		return

	var spawn_pos: Vector2 = position + Vector2(-35.0, 0.0)
	bullet.position = spawn_pos
	var aim_dir: Vector2 = (player_node.global_position - spawn_pos).normalized()

	var proj_cfg: Dictionary = EnemyProjectileDatabase.get_projectile_config("void")
	if bullet.has_method("apply_config"):
		bullet.apply_config(proj_cfg, aim_dir)
	elif bullet.has_method("setup"):
		# High-speed void projectile
		bullet.setup(3, 490.0, aim_dir, 20, 4.5, 45.0, true, false)
	else:
		bullet.set("direction", aim_dir)
		bullet.set("speed", proj_cfg.get("speed", 490.0))

	main_scene.add_child(bullet)


func take_damage(amount: int = 1) -> void:
	if current_health <= 0:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	if hp_bar:
		hp_bar.value = float(current_health)

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(2.5, 2.0, 3.0), 0.07)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.12)

	if current_health <= 0:
		die()


func die() -> void:
	set_physics_process(false)
	destroyed.emit()

	if sprite:
		var base_scale: Vector2 = _get_base_scale()
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "scale", base_scale * 1.5, 0.1)
		tween.parallel().tween_property(sprite, "modulate", Color(3.0, 1.0, 3.0, 0.0), 0.12)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
		die()


func _on_screen_exited() -> void:
	if position.x < 100.0:
		escaped.emit()
		queue_free()
