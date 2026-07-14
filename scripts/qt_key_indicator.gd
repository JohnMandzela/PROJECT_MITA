extends Control

signal note_hit(indicator: Control, key_name: String)
signal note_missed(indicator: Control, key_name: String)
signal hold_finished(indicator: Control, key_name: String, was_held: bool)

const IMPACT_FONT := preload("res://fonts/Impact.otf")
const TARGET_RADIUS := 30.0
const SPAWN_RADIUS := 180.0
const RING_WIDTH := 3.0
const BG_COLOR := Color(0.15, 0.15, 0.15, 0.85)
const RING_ACTIVE_COLOR := Color(0.85, 0.85, 0.85, 0.9)
const RING_HELD_COLOR := Color(0.4, 0.8, 1.0, 0.9)
const HIT_COLOR := Color(0.2, 0.9, 0.3, 1.0)
const MISS_COLOR := Color(0.9, 0.2, 0.2, 1.0)
const SIMULTANEOUS_RING_COLOR := Color(1.0, 0.85, 0.2, 0.9)

var key_name: String = ""
var is_hold: bool = false
var hold_beats: int = 0
var is_simultaneous: bool = false
var simultaneous_group: int = 0
var approach_duration: float = 1.0
var hit_window: float = 0.1

var _elapsed: float = 0.0
var _active: bool = false
var _state: int = 0
var _key_pressed: bool = false
var _key_just_pressed: bool = false
var _ring_radius: float = SPAWN_RADIUS
var _flash_timer: float = 0.0
var _hold_completed: bool = false

var _key_label: Label
var _ring_color: Color = RING_ACTIVE_COLOR


func _ready() -> void:
	_ensure_label()
	size = Vector2(SPAWN_RADIUS * 2.0 + 40.0, SPAWN_RADIUS * 2.0 + 40.0)
	_update_label_text()


func _ensure_label() -> void:
	if _key_label != null and is_instance_valid(_key_label):
		return
	_key_label = Label.new()
	_key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_key_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_key_label.add_theme_font_override("font", IMPACT_FONT)
	_key_label.add_theme_font_size_override("font_size", 24)
	_key_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_key_label)


func setup(key: String, hold: bool, hold_b: int, simultaneous: bool, group: int, approach: float, window: float) -> void:
	key_name = key
	is_hold = hold
	hold_beats = hold_b
	is_simultaneous = simultaneous
	simultaneous_group = group
	approach_duration = approach
	hit_window = window
	_elapsed = 0.0
	_active = true
	_state = 0
	_key_pressed = false
	_key_just_pressed = false
	_hold_completed = false
	_flash_timer = 0.0
	_ring_radius = SPAWN_RADIUS
	_ring_color = RING_ACTIVE_COLOR
	_update_label_text()
	visible = true
	queue_redraw()


func _update_label_text() -> void:
	if _key_label == null:
		return
	_key_label.text = key_name


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	if _state == 0:
		var progress: float = clampf(_elapsed / approach_duration, 0.0, 1.0)
		_ring_radius = lerpf(SPAWN_RADIUS, TARGET_RADIUS, progress)

		if is_simultaneous:
			_ring_color = SIMULTANEOUS_RING_COLOR
		elif _key_pressed:
			_ring_color = RING_HELD_COLOR
		else:
			_ring_color = RING_ACTIVE_COLOR

		if _elapsed >= approach_duration and _state == 0:
			_state = 1
			_ring_radius = TARGET_RADIUS

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			queue_redraw()

	queue_redraw()


func setup_hold_visual() -> void:
	_ring_color = RING_HELD_COLOR
	if _key_label != null:
		_key_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	queue_redraw()


func set_key_pressed(pressed: bool) -> void:
	_key_pressed = pressed
	if pressed:
		_key_just_pressed = true
		if _state == 1 and is_hold:
			_state = 2
			setup_hold_visual()
	queue_redraw()


func is_key_pressed() -> bool:
	return _key_pressed


func was_just_pressed() -> bool:
	var result: bool = _key_just_pressed
	_key_just_pressed = false
	return result


func is_in_hit_window() -> bool:
	return _state == 1


func is_active() -> bool:
	return _active and _state <= 1


func get_note_type() -> int:
	if is_hold:
		return 1
	if is_simultaneous:
		return 2
	return 0


func get_key_name() -> String:
	return key_name


func get_group() -> int:
	return simultaneous_group


func mark_hit() -> void:
	_state = 3
	_ring_color = HIT_COLOR
	_flash_timer = 0.2
	if _key_label != null:
		_key_label.add_theme_color_override("font_color", HIT_COLOR)
	emit_signal("note_hit", self, key_name)
	if is_hold:
		emit_signal("hold_finished", self, key_name, true)


func mark_miss() -> void:
	_state = 4
	_ring_color = MISS_COLOR
	_flash_timer = 0.2
	if _key_label != null:
		_key_label.add_theme_color_override("font_color", MISS_COLOR)
	emit_signal("note_missed", self, key_name)


func mark_hold_release() -> void:
	if is_hold and _state == 2:
		_state = 3
		_ring_color = HIT_COLOR
		if _key_label != null:
			_key_label.add_theme_color_override("font_color", HIT_COLOR)
		emit_signal("hold_finished", self, key_name, true)
		emit_signal("note_hit", self, key_name)


func mark_hold_released_early() -> void:
	if is_hold and _state == 2:
		_state = 4
		_ring_color = MISS_COLOR
		if _key_label != null:
			_key_label.add_theme_color_override("font_color", MISS_COLOR)
		emit_signal("hold_finished", self, key_name, false)
		emit_signal("note_missed", self, key_name)


func force_miss() -> void:
	if _state >= 3:
		return
	_state = 4
	_ring_color = MISS_COLOR
	if _key_label != null:
		_key_label.add_theme_color_override("font_color", MISS_COLOR)
	emit_signal("note_missed", self, key_name)


func get_time_overdue() -> float:
	if _elapsed > approach_duration:
		return _elapsed - approach_duration
	return 0.0


func is_resolved() -> bool:
	return _state >= 3


func is_held() -> bool:
	return _state == 2 and _key_pressed


func _draw() -> void:
	var center: Vector2 = size * 0.5

	draw_circle(center, TARGET_RADIUS + 2.0, BG_COLOR)

	if _state == 0 or _state == 1 or _state == 2:
		if _ring_radius > TARGET_RADIUS + 0.5:
			draw_arc(center, _ring_radius, 0.0, TAU, 64, _ring_color, RING_WIDTH)

	if _state == 3:
		draw_circle(center, TARGET_RADIUS, Color(0.2, 0.9, 0.3, 0.4))
	elif _state == 4:
		draw_circle(center, TARGET_RADIUS, Color(0.9, 0.2, 0.2, 0.4))
	elif _state == 2:
		draw_circle(center, TARGET_RADIUS, Color(0.4, 0.8, 1.0, 0.3))
	else:
		draw_circle(center, TARGET_RADIUS, Color(0.5, 0.5, 0.5, 0.5))
