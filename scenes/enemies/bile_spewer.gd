extends Area2D

signal destroyed
signal escaped

@export var max_health: int = 8
@export var speed: float = 145.0
@export var contact_damage: int = 20

var current_health: int = 8
var elapsed_time: float = 0.0
var spew_cooldown: float = 5.0

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
	add_to_group("bile_spewers")
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

	# Smooth undulating forward drift
	position.x -= speed * delta
	position.y += cos(elapsed_time * 2.0) * 60.0 * delta
	var vp_h: float = get_viewport_rect().size.y
	if vp_h > 0.0:
		position.y = clampf(position.y, 80.0, vp_h - 80.0)

	if position.x < -80.0:
		escaped.emit()
		queue_free()
		return

	# Multiple projectile barrage every 5.0 seconds
	spew_cooldown -= delta
	if spew_cooldown <= 0.0:
		spew_cooldown = 5.0
		_spew_multiple_projectiles()


func _spew_multiple_projectiles() -> void:
	if not projectile_scene:
		return

	var main_scene: Node = get_parent()
	if not main_scene:
		return

	var player_node: Node2D = main_scene.get_node_or_null("Player") as Node2D
	if not player_node:
		return

	# Only stop spewing if passed behind the player
	if position.x < player_node.global_position.x - 20.0:
		return

	var spawn_pos: Vector2 = position + Vector2(-40.0, 0.0)
	var dir_to_player: Vector2 = (player_node.global_position - spawn_pos).normalized()
	var base_angle: float = dir_to_player.angle()

	# Spew 5 toxic projectiles in a wide arc using EnemyProjectileDatabase
	var proj_cfg: Dictionary = EnemyProjectileDatabase.get_projectile_config("spewer")
	var angles: Array[float] = [-24.0, -12.0, 0.0, 12.0, 24.0]
	for offset_deg: float in angles:
		var bullet: Area2D = projectile_scene.instantiate() as Area2D
		if not bullet:
			continue

		bullet.position = spawn_pos
		var bullet_dir: Vector2 = Vector2.from_angle(base_angle + deg_to_rad(offset_deg))

		if bullet.has_method("apply_config"):
			bullet.apply_config(proj_cfg, bullet_dir)
		elif bullet.has_method("setup"):
			# setup(MovementType.DIRECT, 430.0 speed, bullet_dir, 20 dmg, 4.5 freq, 45.0 amp, zoning=false, bile=true)
			bullet.setup(0, 430.0, bullet_dir, 20, 4.5, 45.0, false, true)
		else:
			bullet.set("direction", bullet_dir)
			bullet.set("speed", proj_cfg.get("speed", 430.0))

		main_scene.add_child(bullet)


func take_damage(amount: int = 1) -> void:
	if current_health <= 0:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	if hp_bar:
		hp_bar.value = float(current_health)

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.8, 2.5, 1.5), 0.07)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.12)

	if current_health <= 0:
		die()


func die() -> void:
	set_physics_process(false)
	destroyed.emit()

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "scale", sprite.scale * 1.35, 0.1)
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
