extends Area2D

signal destroyed
signal escaped

@export var max_health: int = 20
@export var speed: float = 85.0
@export var contact_damage: int = 35

var current_health: int = 20
var elapsed_time: float = 0.0
var breed_timer: float = 5.0

@export var void_bile_scene: PackedScene = preload("res://scenes/enemies/void_bile.tscn")
@export var custom_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func set_enemy_texture(tex: Texture2D) -> void:
	custom_texture = tex
	if sprite:
		sprite.texture = tex


func _ready() -> void:
	add_to_group("bile_breeders")
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

	# Slow steady movement across screen with pulsing undulation
	position.x -= speed * delta
	position.y += sin(elapsed_time * 1.6) * 35.0 * delta
	var vp_h: float = get_viewport_rect().size.y
	if vp_h > 0.0:
		position.y = clampf(position.y, 90.0, vp_h - 90.0)

	if position.x < -100.0:
		escaped.emit()
		queue_free()
		return

	# Breed 3 Void Biles every 5.0 seconds (shoots no projectiles itself)
	breed_timer -= delta
	if breed_timer <= 0.0:
		breed_timer = 5.0
		_breed_void_biles()


func _breed_void_biles() -> void:
	var main_node: Node = get_parent()
	if not main_node:
		return

	# Visual pulsating birth flash
	if sprite:
		var base_scale: Vector2 = sprite.scale
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "scale", base_scale * 1.15, 0.15)
		tween.tween_property(sprite, "modulate", Color(1.8, 2.5, 0.9), 0.12)
		tween.tween_property(sprite, "scale", base_scale, 0.15)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.15)

	var offsets: Array[Vector2] = [
		Vector2(-35.0, -50.0),
		Vector2(-55.0, 0.0),
		Vector2(-35.0, 50.0)
	]

	for offset: Vector2 in offsets:
		var spawn_pos: Vector2 = position + offset
		if main_node.has_method("spawn_bred_void_bile"):
			main_node.spawn_bred_void_bile(spawn_pos)
		elif void_bile_scene:
			var baby: Area2D = void_bile_scene.instantiate() as Area2D
			if baby:
				baby.position = spawn_pos
				main_node.add_child(baby)


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
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.14)
		tween.parallel().tween_property(sprite, "modulate", Color(2.8, 0.5, 3.0, 0.0), 0.14)
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
