extends Control

signal joystick_vector_changed(vector: Vector2)
signal joystick_released

@export var base_radius: float = 75.0
@export var knob_radius: float = 30.0
@export var max_distance: float = 65.0
@export var deadzone: float = 8.0

var center_pos: Vector2 = Vector2.ZERO
var knob_pos: Vector2 = Vector2.ZERO
var output_vector: Vector2 = Vector2.ZERO

var is_active: bool = false
var touch_id: int = -1


func _ready() -> void:
	custom_minimum_size = Vector2(base_radius * 2.0 + 30.0, base_radius * 2.0 + 30.0)
	center_pos = size * 0.5
	knob_pos = center_pos
	mouse_filter = MOUSE_FILTER_PASS


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		center_pos = size * 0.5
		if not is_active:
			knob_pos = center_pos
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed() and not is_active:
			touch_id = event.index
			is_active = true
			_update_from_position(event.position)
			accept_event()
		elif not event.is_pressed() and event.index == touch_id:
			_release()
			accept_event()

	elif event is InputEventScreenDrag:
		if is_active and event.index == touch_id:
			_update_from_position(event.position)
			accept_event()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and not is_active:
				touch_id = -1
				is_active = true
				_update_from_position(event.position)
				accept_event()
			elif not event.is_pressed() and is_active and touch_id == -1:
				_release()
				accept_event()

	elif event is InputEventMouseMotion:
		if is_active and touch_id == -1:
			_update_from_position(event.position)
			accept_event()


## Global input listener to ensure drag tracking & release are NEVER lost when finger leaves control bounds
func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventScreenTouch:
		if not event.is_pressed() and event.index == touch_id:
			_release()
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			var drag_pos: Vector2 = get_global_transform().affine_inverse() * event.position
			_update_from_position(drag_pos)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed() and touch_id == -1:
			_release()
	elif event is InputEventMouseMotion:
		if touch_id == -1:
			var motion_pos: Vector2 = get_global_transform().affine_inverse() * event.position
			_update_from_position(motion_pos)


func _update_from_position(pos: Vector2) -> void:
	var diff: Vector2 = pos - center_pos
	var dist: float = diff.length()

	if dist < deadzone:
		output_vector = Vector2.ZERO
		knob_pos = center_pos
	else:
		var dir: Vector2 = diff.normalized()
		var clamped_dist: float = minf(dist, max_distance)
		knob_pos = center_pos + dir * clamped_dist

		var strength: float = (clamped_dist - deadzone) / (max_distance - deadzone)
		output_vector = dir * clampf(strength, 0.0, 1.0)

	_inject_input_strengths()
	joystick_vector_changed.emit(output_vector)
	queue_redraw()


func _release() -> void:
	is_active = false
	touch_id = -1
	output_vector = Vector2.ZERO
	knob_pos = center_pos
	_inject_input_strengths()
	joystick_released.emit()
	queue_redraw()


func _inject_input_strengths() -> void:
	var left: float = maxf(0.0, -output_vector.x)
	var right: float = maxf(0.0, output_vector.x)
	var up: float = maxf(0.0, -output_vector.y)
	var down: float = maxf(0.0, output_vector.y)

	_apply_action_strength("move_left", left)
	_apply_action_strength("move_right", right)
	_apply_action_strength("move_up", up)
	_apply_action_strength("move_down", down)


func _apply_action_strength(action: StringName, strength: float) -> void:
	if strength > 0.001:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _draw() -> void:
	# Outer subtle glow / base disc
	draw_circle(center_pos, base_radius, Color(0.04, 0.12, 0.22, 0.5))

	# Outer sci-fi ring outline
	var ring_col: Color = Color(0.25, 0.85, 1.0, 0.75) if is_active else Color(0.2, 0.65, 0.9, 0.45)
	draw_arc(center_pos, base_radius, 0.0, TAU, 48, ring_col, 2.5, true)

	# 4 Cardinal direction tick marks
	var tick_len: float = 10.0
	var tick_col: Color = Color(0.4, 0.9, 1.0, 0.6)
	# UP
	draw_line(center_pos + Vector2(0, -base_radius + 4), center_pos + Vector2(0, -base_radius + 4 + tick_len), tick_col, 2.0)
	# DOWN
	draw_line(center_pos + Vector2(0, base_radius - 4), center_pos + Vector2(0, base_radius - 4 - tick_len), tick_col, 2.0)
	# LEFT
	draw_line(center_pos + Vector2(-base_radius + 4, 0), center_pos + Vector2(-base_radius + 4 + tick_len, 0), tick_col, 2.0)
	# RIGHT
	draw_line(center_pos + Vector2(base_radius - 4, 0), center_pos + Vector2(base_radius - 4 - tick_len, 0), tick_col, 2.0)

	# Inner connecting ray when active
	if is_active and (knob_pos - center_pos).length_squared() > 10.0:
		draw_line(center_pos, knob_pos, Color(0.3, 0.95, 1.0, 0.5), 3.0)

	# Stick Knob
	var knob_body_col: Color = Color(0.12, 0.45, 0.75, 0.85) if is_active else Color(0.08, 0.30, 0.52, 0.65)
	var knob_rim_col: Color = Color(0.55, 0.95, 1.0, 0.95) if is_active else Color(0.35, 0.75, 0.95, 0.65)
	draw_circle(knob_pos, knob_radius, knob_body_col)
	draw_arc(knob_pos, knob_radius, 0.0, TAU, 32, knob_rim_col, 2.5, true)

	# Center bright pip
	var pip_col: Color = Color(1.0, 1.0, 1.0, 0.9) if is_active else Color(0.4, 0.8, 1.0, 0.6)
	draw_circle(knob_pos, 6.0, pip_col)
