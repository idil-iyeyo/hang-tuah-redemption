extends Area2D

signal destroyed
signal escaped

@export var max_health: int = 30
@export var speed: float = 620.0
@export var contact_damage: int = 35

var current_health: int = 30
var elapsed_time: float = 0.0
var charge_direction: Vector2 = Vector2.LEFT
var has_locked_direction: bool = false
var lock_timer: float = 0.35
@export var custom_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func set_enemy_texture(tex: Texture2D) -> void:
	custom_texture = tex
	if sprite:
		sprite.texture = tex


func _ready() -> void:
	add_to_group("charger_roach")
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

	# Initial brief targeting lock before relentless high-speed charge
	if not has_locked_direction:
		lock_timer -= delta
		var main_node: Node = get_parent()
		if main_node:
			var player_node: Node2D = main_node.get_node_or_null("Player") as Node2D
			if player_node:
				charge_direction = (player_node.global_position - position).normalized()
				# Enforce moving leftwards towards player base
				if charge_direction.x > -0.3:
					charge_direction.x = -0.8
					charge_direction = charge_direction.normalized()

		if lock_timer <= 0.0:
			has_locked_direction = true
			rotation = charge_direction.angle() + PI # Point forward

	# High speed charge forward
	position += charge_direction * speed * delta

	if position.x < -100.0:
		escaped.emit()
		queue_free()
		return


func take_damage(amount: int = 1) -> void:
	if current_health <= 0:
		return

	current_health = clampi(current_health - amount, 0, max_health)
	if hp_bar:
		hp_bar.value = float(current_health)

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(2.5, 2.0, 1.2), 0.06)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.10)

	if current_health <= 0:
		die()


func die() -> void:
	set_physics_process(false)
	destroyed.emit()

	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "scale", sprite.scale * 1.4, 0.12)
		tween.parallel().tween_property(sprite, "modulate", Color(3.0, 1.5, 0.5, 0.0), 0.12)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if body.has_method("take_damage"):
			var shields: int = int(body.get("current_shields"))
			if shields <= 0:
				# Instant kill if unshielded
				body.take_damage(100)
			else:
				body.take_damage(contact_damage)
		die()


func _on_screen_exited() -> void:
	if position.x < 100.0:
		escaped.emit()
		queue_free()
