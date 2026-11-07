extends Control

signal fire_state_changed(is_firing: bool)

@export var button_radius: float = 65.0

var center_pos: Vector2 = Vector2.ZERO
var is_down: bool = false
var touch_id: int = -1
var anim_pulse: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(button_radius * 2.0 + 20.0, button_radius * 2.0 + 20.0)
	center_pos = size * 0.5
	mouse_filter = MOUSE_FILTER_PASS


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		center_pos = size * 0.5
		queue_redraw()


func _process(delta: float) -> void:
	if is_down:
		anim_pulse += delta * 6.0
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed() and not is_down:
			touch_id = event.index
			_set_pressed(true)
			accept_event()
		elif not event.is_pressed() and event.index == touch_id:
			_set_pressed(false)
			accept_event()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and not is_down:
				touch_id = -1
				_set_pressed(true)
				accept_event()
			elif not event.is_pressed() and is_down and touch_id == -1:
				_set_pressed(false)
				accept_event()


## Global input listener to guarantee button release is NEVER lost even if touch slides off
func _input(event: InputEvent) -> void:
	if not is_down:
		return

	if event is InputEventScreenTouch:
		if not event.is_pressed() and event.index == touch_id:
			_set_pressed(false)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed() and touch_id == -1:
			_set_pressed(false)


func _set_pressed(pressed: bool) -> void:
	is_down = pressed
	if not pressed:
		touch_id = -1

	_update_shoot_action()
	fire_state_changed.emit(is_firing())
	queue_redraw()


func is_firing() -> bool:
	return is_down


func _update_shoot_action() -> void:
	if is_firing():
		Input.action_press("shoot")
	else:
		Input.action_release("shoot")


func reset_state() -> void:
	is_down = false
	touch_id = -1
	_update_shoot_action()
	queue_redraw()


func _draw() -> void:
	var firing: bool = is_firing()

	# Dynamic pulse scale
	var pulse: float = sin(anim_pulse) * 4.0 if firing else 0.0
	var cur_radius: float = button_radius + pulse

	# Outer subtle glow disc
	var bg_col: Color = Color(0.4, 0.08, 0.05, 0.55) if firing else Color(0.18, 0.05, 0.05, 0.45)
	draw_circle(center_pos, cur_radius, bg_col)

	# Outer targeting ring
	var ring_col: Color = Color(1.0, 0.4, 0.2, 0.95) if firing else Color(0.9, 0.3, 0.2, 0.6)
	draw_arc(center_pos, cur_radius, 0.0, TAU, 48, ring_col, 3.0, true)

	# Crosshair ticks on perimeter
	var tick_size: float = 12.0
	# Top, Bottom, Left, Right
	draw_line(center_pos + Vector2(0, -cur_radius - 2), center_pos + Vector2(0, -cur_radius + tick_size), ring_col, 2.5)
	draw_line(center_pos + Vector2(0, cur_radius + 2), center_pos + Vector2(0, cur_radius - tick_size), ring_col, 2.5)
	draw_line(center_pos + Vector2(-cur_radius - 2, 0), center_pos + Vector2(-cur_radius + tick_size, 0), ring_col, 2.5)
	draw_line(center_pos + Vector2(cur_radius + 2, 0), center_pos + Vector2(cur_radius - tick_size, 0), ring_col, 2.5)

	# Inner core circle
	var inner_col: Color = Color(1.0, 0.25, 0.15, 0.85) if is_down else Color(0.45, 0.12, 0.1, 0.6)
	draw_circle(center_pos, cur_radius * 0.55, inner_col)

	# Inner reticle circle
	draw_arc(center_pos, cur_radius * 0.30, 0.0, TAU, 24, Color(1.0, 0.9, 0.8, 0.8), 2.0, true)

	# Central targeting pip
	draw_circle(center_pos, 5.0, Color(1.0, 1.0, 1.0, 0.95))
