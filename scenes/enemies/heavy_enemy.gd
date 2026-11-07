extends Area2D

signal destroyed
signal escaped

@export var max_health: int = 50
@export var speed: float = 175.0
@export var contact_damage: int = 30

var current_health: int = 50
var elapsed_time: float = 0.0
var shoot_timer: float = 1.4

@export var projectile_scene: PackedScene = preload("res://scenes/enemies/projectile.tscn")
@export var custom_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func set_enemy_texture(tex: Texture2D) -> void:
	custom_texture = tex
	if sprite:
		sprite.texture = tex


func _ready() -> void:
	add_to_group("heavy_enemies")
	add_to_group("enemy_units")
	body_entered.connect(_on_body_entered)
	if notifier:
		notifier.screen_exited.connect(_on_screen_exited)

	if custom_texture and sprite:
		sprite.texture = custom_texture

	current_health = max_health
	if hp_bar:
		hp_bar.max_value = float(max_health)
		hp_bar.value = float(current_health)

	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0)


func _physics_process(delta: float) -> void:
	elapsed_time += delta

	# Advance steadily across screen with gentle vertical weaving
	position.x -= speed * delta
	position.y += sin(elapsed_time * 2.2) * 55.0 * delta
	var vp_h: float = get_viewport_rect().size.y
	if vp_h > 0.0:
		position.y = clampf(position.y, 80.0, vp_h - 80.0)

	if position.x < -80.0:
		escaped.emit()
		queue_free()
		return

	# Firing retaliatory projectiles towards player
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(1.5, 2.1)
		_shoot_at_player()


func _shoot_at_player() -> void:
	if not projectile_scene:
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

	var spawn_pos: Vector2 = position + Vector2(-45.0, 0.0)
	bullet.position = spawn_pos
	var aim_dir: Vector2 = (player_node.global_position - spawn_pos).normalized()

	var proj_cfg: Dictionary = EnemyProjectileDatabase.get_projectile_config("heavy")
	if bullet.has_method("apply_config"):
		bullet.apply_config(proj_cfg, aim_dir)
	elif bullet.has_method("setup"):
		# 0 = DIRECT archetype, 420 px/s speed
		bullet.setup(0, 420.0, aim_dir, 20)
	else:
		bullet.set("direction", aim_dir)
		bullet.set("speed", proj_cfg.get("speed", 420.0))

	main_scene.add_child(bullet)


func take_damage(amount: int = 1) -> void:
	if current_health <= 0:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	if hp_bar:
		hp_bar.value = float(current_health)

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(2.5, 2.0, 2.2), 0.07)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.12)

	if current_health <= 0:
		die()


func die() -> void:
	set_physics_process(false)
	destroyed.emit()

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "scale", sprite.scale * 1.4, 0.1)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.1)
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
