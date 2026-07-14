extends Control

signal exit_requested
signal puzzle_completed

const BG_COLOR := Color(0.08, 0.08, 0.1)
const WELD_DEVIATION_SCALE := 30.0
const DEAD_ZONE := 0.01
const CENTER_ANGLE := PI / 2.0

const PAUSE_TITLE := "Выйти из миниигры? Несохранённый прогресс будет потерян."
const PAUSE_EXIT := "Выйти"
const PAUSE_CONTINUE := "Продолжить"
const START_HINT := "Удерживайте маячок по центру дуги стрелками «← →»"
const LEVEL_SELECT_TITLE := "Выберите ранг сложности"

@export var config_path: String = "res://charts/corridor_game_config.json"

@onready var background: ColorRect = $Background
@onready var game_area: Control = $GameArea
@onready var welding_draw: Control = $GameArea/WeldingDraw
@onready var turn_warning_left: Label = $GameArea/TurnWarningLeft
@onready var turn_warning_right: Label = $GameArea/TurnWarningRight
@onready var hint_label: Label = $UI/HintLabel
@onready var time_label: Label = $UI/TopBar/TimeLabel
@onready var title_label: Label = $UI/TopBar/TitleLabel
@onready var feedback_label: Label = $UI/FeedbackLabel
@onready var level_select_overlay: Control = $LevelSelectOverlay
@onready var level_vbox: VBoxContainer = $LevelSelectOverlay/Panel/Margin/VBox
@onready var level_title_label: Label = $LevelSelectOverlay/Panel/Margin/VBox/TitleLabel
@onready var result_overlay: Control = $ResultOverlay
@onready var result_label: Label = $ResultOverlay/Panel/Margin/VBox/ResultLabel
@onready var retry_button: Button = $ResultOverlay/Panel/Margin/VBox/RetryButton
@onready var menu_button: Button = $ResultOverlay/Panel/Margin/VBox/MenuButton
@onready var finish_button: Button = $ResultOverlay/Panel/Margin/VBox/FinishButton
@onready var modal_blur: ColorRect = $ModalBlur
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_label: Label = $PauseOverlay/Panel/Margin/VBox/PauseLabel
@onready var pause_exit_button: Button = $PauseOverlay/Panel/Margin/VBox/PauseExitButton
@onready var pause_continue_button: Button = $PauseOverlay/Panel/Margin/VBox/PauseContinueButton

var _levels: Array[Dictionary] = []
var _current_level: Dictionary = {}
var _corridor_duration := 30.0
var _warning_duration := 2.0
var _turn_duration := 1.5

var _playing := false
var _is_finished := false
var _can_finish := false
var _result_shown := false
var _game_time := 0.0

var _beacon_x := 0.5
var _beacon_drift := 0.0
var _drift_timer := 0.0
var _drift_direction := 1.0

var _holding_left := false
var _holding_right := false

var _turns: Array[Dictionary] = []
var _next_turn_index := 0
var _turn_warning_active := false
var _turn_active := false
var _turn_timer := 0.0
var _turn_direction := 0

var _arc_center := Vector2.ZERO
var _arc_radius := 0.0


func _ready() -> void:
	background.color = BG_COLOR
	pause_label.text = PAUSE_TITLE
	pause_exit_button.text = PAUSE_EXIT
	pause_continue_button.text = PAUSE_CONTINUE
	level_title_label.text = LEVEL_SELECT_TITLE
	title_label.text = "Фаза коридоров"
	finish_button.visible = false
	turn_warning_left.text = "← Поворот!"
	turn_warning_right.text = "Поворот! →"

	pause_exit_button.pressed.connect(_on_pause_exit_pressed)
	pause_continue_button.pressed.connect(_on_pause_continue_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	game_area.resized.connect(_on_game_area_resized)

	_load_config()
	_build_level_buttons()
	_show_level_select()


func _load_config() -> void:
	if not FileAccess.file_exists(config_path):
		push_error("Corridor game config not found: %s" % config_path)
		return

	var file := FileAccess.open(config_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid corridor game config JSON: %s" % config_path)
		return

	_corridor_duration = float(parsed.get("corridor_duration", 30.0))
	_warning_duration = float(parsed.get("warning_duration", 2.0))
	_turn_duration = float(parsed.get("turn_duration", 1.5))

	var raw_levels: Variant = parsed.get("levels", [])
	_levels.clear()
	if raw_levels is Array:
		for entry in raw_levels:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			_levels.append(entry)


func _build_level_buttons() -> void:
	for child in level_vbox.get_children():
		if child is Button:
			child.queue_free()

	for i in range(_levels.size()):
		var level: Dictionary = _levels[i]
		var btn := Button.new()
		btn.text = str(level.get("name", "Ранг %d" % (i + 1)))
		btn.custom_minimum_size = Vector2(260, 44)
		btn.pressed.connect(_on_level_selected.bind(i))
		level_vbox.add_child(btn)


func _show_level_select() -> void:
	_playing = false
	_is_finished = false
	_holding_left = false
	_holding_right = false
	pause_overlay.visible = false
	result_overlay.visible = false
	level_select_overlay.visible = true
	modal_blur.visible = true
	hint_label.text = ""
	feedback_label.text = ""
	turn_warning_left.visible = false
	turn_warning_right.visible = false
	time_label.text = ""
	welding_draw.set_marker(0.0, false)


func _on_level_selected(index: int) -> void:
	if index < 0 or index >= _levels.size():
		return
	_current_level = _levels[index]
	level_select_overlay.visible = false
	modal_blur.visible = false
	_start_game()


func _start_game() -> void:
	_is_finished = false
	_can_finish = false
	_result_shown = false
	_game_time = 0.0
	_beacon_x = 0.5
	_beacon_drift = 0.0
	_drift_direction = 1.0
	_holding_left = false
	_holding_right = false
	_turn_warning_active = false
	_turn_active = false
	_turn_timer = 0.0
	_turn_direction = 0
	_next_turn_index = 0

	welding_draw.clear_weld()
	_generate_turns()
	_setup_arc()
	_schedule_next_drift()

	turn_warning_left.visible = false
	turn_warning_right.visible = false
	hint_label.text = START_HINT
	feedback_label.text = ""
	result_overlay.visible = false
	modal_blur.visible = false
	_playing = true
	_update_marker_visual()


func _generate_turns() -> void:
	_turns.clear()
	var turn_count: int = _current_level.get("turn_count", 4)
	var min_spacing := _corridor_duration / float(turn_count + 1) * 0.6
	var positions: Array[float] = []

	for i in range(turn_count):
		var pos := randf_range(min_spacing, _corridor_duration - min_spacing)
		var attempts := 0
		var valid := false
		while not valid and attempts < 50:
			valid = true
			for existing in positions:
				if absf(pos - existing) < min_spacing:
					pos = randf_range(min_spacing, _corridor_duration - min_spacing)
					valid = false
					break
			attempts += 1
		positions.append(pos)

	positions.sort()

	for i in range(positions.size()):
		_turns.append({
			"position": positions[i],
			"direction": [-1, 1][randi() % 2]
		})


func _setup_arc() -> void:
	var w := game_area.size.x
	var h := game_area.size.y
	_arc_center = Vector2(w * 0.5, h * 0.82)
	_arc_radius = minf(w * 0.38, h * 0.55)
	welding_draw.set_arc_params(_arc_center, _arc_radius)


func _beacon_x_to_angle() -> float:
	return PI * (1.0 - _beacon_x)


func _schedule_next_drift() -> void:
	var interval_range: Array = _current_level.get("interval_range", [4.0, 8.0])
	_drift_timer = randf_range(interval_range[0], interval_range[1])

	var force_range: Array = _current_level.get("fall_force_range", [0.10, 0.25])
	var force := randf_range(force_range[0], force_range[1])
	_drift_direction *= -1.0
	_beacon_drift = force * _drift_direction


func _process(delta: float) -> void:
	if not _playing or _is_finished:
		return

	_game_time += delta

	if _game_time >= _corridor_duration:
		_finish_game(true)
		return

	_update_turns(delta)

	var drift := _beacon_drift
	if _turn_active:
		var turn_force_range: Array = _current_level.get("fall_force_range", [0.10, 0.25])
		var turn_force: float = (float(turn_force_range[0]) + float(turn_force_range[1])) * 0.5
		drift = turn_force * float(_turn_direction)

	var player_force: float = _current_level.get("player_force", 0.35)
	var player_input := 0.0
	if _holding_right:
		player_input = player_force
	elif _holding_left:
		player_input = -player_force

	_beacon_x += (drift + player_input) * delta
	_beacon_x = clampf(_beacon_x, 0.0, 1.0)

	if _beacon_x <= DEAD_ZONE or _beacon_x >= 1.0 - DEAD_ZONE:
		_finish_game(false)
		return

	if not _turn_active and not _turn_warning_active:
		_drift_timer -= delta
		if _drift_timer <= 0.0:
			_schedule_next_drift()

	_update_welding_line()
	_update_marker_visual()
	_update_turn_warnings()
	_update_time_label()


func _update_turns(delta: float) -> void:
	if _turn_warning_active:
		_turn_timer -= delta
		if _turn_timer <= 0.0:
			_turn_warning_active = false
			_turn_active = true
			if _next_turn_index < _turns.size():
				_turn_direction = int(_turns[_next_turn_index]["direction"])
			_turn_timer = _turn_duration

	elif _turn_active:
		_turn_timer -= delta
		if _turn_timer <= 0.0:
			_turn_active = false
			_turn_direction = 0
			_next_turn_index += 1
			_schedule_next_drift()

	else:
		if _next_turn_index < _turns.size():
			var turn: Dictionary = _turns[_next_turn_index]
			var turn_pos: float = turn["position"]
			if _game_time >= turn_pos - _warning_duration:
				_turn_warning_active = true
				_turn_timer = _warning_duration


func _update_welding_line() -> void:
	var angle := _beacon_x_to_angle()
	var deviation := (_beacon_x - 0.5) * 2.0 * WELD_DEVIATION_SCALE
	welding_draw.add_weld_point(angle, deviation)


func _update_marker_visual() -> void:
	var angle := _beacon_x_to_angle()
	welding_draw.set_marker(angle, true)


func _update_turn_warnings() -> void:
	var show_left := false
	var show_right := false

	if _turn_warning_active and _next_turn_index < _turns.size():
		var turn: Dictionary = _turns[_next_turn_index]
		if int(turn["direction"]) == -1:
			show_left = true
		else:
			show_right = true

	turn_warning_left.visible = show_left
	turn_warning_right.visible = show_right


func _update_time_label() -> void:
	var remaining := maxi(0, int(ceilf(_corridor_duration - _game_time)))
	time_label.text = "Осталось: %dс" % remaining


func _finish_game(success: bool) -> void:
	_playing = false
	_is_finished = true
	_can_finish = success
	_result_shown = true
	hint_label.text = ""
	turn_warning_left.visible = false
	turn_warning_right.visible = false
	welding_draw.set_marker(0.0, false)

	if success:
		result_label.text = "Коридор проварен!"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	else:
		result_label.text = "Маячок упал!"
		result_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))

	finish_button.visible = _can_finish
	result_overlay.visible = true
	modal_blur.visible = true
	if _can_finish:
		emit_signal("puzzle_completed")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if result_overlay.visible:
		return

	if event.is_action_pressed("ui_cancel"):
		if _playing:
			if pause_overlay.visible:
				_close_pause_overlay()
			else:
				_open_pause_overlay()
			get_viewport().set_input_as_handled()
			return

	if _is_finished or pause_overlay.visible or level_select_overlay.visible:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_LEFT:
			_holding_left = key_event.pressed
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_RIGHT:
			_holding_right = key_event.pressed
			get_viewport().set_input_as_handled()


func _on_game_area_resized() -> void:
	if _playing:
		_setup_arc()
		welding_draw.clear_weld()


func _open_pause_overlay() -> void:
	_playing = false
	pause_overlay.visible = true
	modal_blur.visible = true


func _close_pause_overlay() -> void:
	pause_overlay.visible = false
	modal_blur.visible = _result_shown
	_playing = true


func toggle_pause_overlay_from_pause_menu() -> void:
	if not visible:
		return
	if result_overlay.visible:
		return
	if pause_overlay.visible:
		_close_pause_overlay()
	else:
		_open_pause_overlay()


func _on_pause_continue_pressed() -> void:
	_close_pause_overlay()


func _on_pause_exit_pressed() -> void:
	_close_pause_overlay()
	_show_level_select()
	emit_signal("exit_requested")


func _on_retry_pressed() -> void:
	result_overlay.visible = false
	modal_blur.visible = false
	_start_game()


func _on_menu_pressed() -> void:
	_show_level_select()


func _on_finish_pressed() -> void:
	if not _can_finish:
		return
	_show_level_select()
	emit_signal("exit_requested")
