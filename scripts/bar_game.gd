extends Control

signal exit_requested
signal puzzle_completed

const BAR_HEIGHT := 48.0
const BAR_MARGIN := 60.0
const DOT_SIZE := Vector2(28, 28)
const BAR_BG_COLOR := Color(0.14, 0.14, 0.18)
const BAR_BORDER_COLOR := Color(0.28, 0.28, 0.34)
const BG_COLOR := Color(0.08, 0.08, 0.1)
const TEXT_LIGHT := Color(0.96, 0.96, 0.96)

const PAUSE_TITLE := "Выйти из миниигры? Несохранённый прогресс будет потерян."
const PAUSE_EXIT := "Выйти"
const PAUSE_CONTINUE := "Продолжить"
const START_HINT := "Нажмите Пробел, чтобы остановить"
const LEVEL_SELECT_TITLE := "Выберите сложность"

@export var config_path: String = "res://charts/bar_game_config.json"

@onready var background: ColorRect = $Background
@onready var bar_area: Control = $BarArea
@onready var bar_bg: ColorRect = $BarArea/BarBg
@onready var target_zone: ColorRect = $BarArea/TargetZone
@onready var dot: ColorRect = $BarArea/Dot
@onready var hint_label: Label = $UI/HintLabel
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
var _dot_direction := 1.0
var _dot_x := 0.0
var _bar_left := 0.0
var _bar_right := 0.0
var _target_left := 0.0
var _target_right := 0.0
var _playing := false
var _is_finished := false
var _can_finish := false
var _result_shown := false


func _ready() -> void:
	background.color = BG_COLOR
	pause_label.text = PAUSE_TITLE
	pause_exit_button.text = PAUSE_EXIT
	pause_continue_button.text = PAUSE_CONTINUE
	level_title_label.text = LEVEL_SELECT_TITLE
	finish_button.visible = false

	pause_exit_button.pressed.connect(_on_pause_exit_pressed)
	pause_continue_button.pressed.connect(_on_pause_continue_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	bar_area.resized.connect(_on_bar_area_resized)

	_load_config()
	_build_level_buttons()
	_show_level_select()


func _load_config() -> void:
	if not FileAccess.file_exists(config_path):
		push_error("Bar game config not found: %s" % config_path)
		return

	var file := FileAccess.open(config_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid bar game config JSON: %s" % config_path)
		return

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
		btn.text = str(level.get("name", "Уровень %d" % (i + 1)))
		btn.custom_minimum_size = Vector2(260, 44)
		btn.pressed.connect(_on_level_selected.bind(i))
		level_vbox.add_child(btn)


func _show_level_select() -> void:
	_playing = false
	_is_finished = false
	_result_shown = false
	pause_overlay.visible = false
	result_overlay.visible = false
	level_select_overlay.visible = true
	modal_blur.visible = true
	hint_label.text = ""
	feedback_label.text = ""
	dot.visible = false
	target_zone.visible = false


func _on_level_selected(index: int) -> void:
	if index < 0 or index >= _levels.size():
		return
	_current_level = _levels[index]
	level_select_overlay.visible = false
	modal_blur.visible = false
	_start_game()


func _start_game() -> void:
	_is_finished = false
	_result_shown = false
	result_overlay.visible = false
	modal_blur.visible = false
	feedback_label.text = ""

	_dot_direction = 1.0
	_setup_bar()
	dot.visible = true
	target_zone.visible = true
	hint_label.text = START_HINT
	_playing = true


func _setup_bar() -> void:
	var bar_width := bar_area.size.x - BAR_MARGIN * 2.0
	_bar_left = BAR_MARGIN
	_bar_right = BAR_MARGIN + bar_width

	bar_bg.position = Vector2(BAR_MARGIN, (bar_area.size.y - BAR_HEIGHT) * 0.5)
	bar_bg.size = Vector2(bar_width, BAR_HEIGHT)

	var target_width: float = _current_level.get("target_zone_width", 80.0)
	var target_color_arr: Array = _current_level.get("target_zone_color", [0.3, 0.85, 0.3])
	var target_color := Color(target_color_arr[0], target_color_arr[1], target_color_arr[2])

	var max_target_x := _bar_right - target_width
	var min_target_x := _bar_left
	var target_x := randf_range(min_target_x, max_target_x)

	_target_left = target_x
	_target_right = target_x + target_width

	target_zone.position = Vector2(target_x, bar_bg.position.y)
	target_zone.size = Vector2(target_width, BAR_HEIGHT)
	target_zone.color = target_color

	_dot_x = _bar_left + (bar_width * 0.5)
	_update_dot_position()


func _update_dot_position() -> void:
	dot.position = Vector2(_dot_x - DOT_SIZE.x * 0.5, bar_bg.position.y + (BAR_HEIGHT - DOT_SIZE.y) * 0.5)
	dot.size = DOT_SIZE


func _process(delta: float) -> void:
	if not _playing or _is_finished:
		return

	var speed: float = _current_level.get("dot_speed", 200.0)
	_dot_x += speed * _dot_direction * delta

	if _dot_x >= _bar_right:
		_dot_x = _bar_right
		_dot_direction = -1.0
	elif _dot_x <= _bar_left:
		_dot_x = _bar_left
		_dot_direction = 1.0

	_update_dot_position()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if result_overlay.visible:
		return

	if event.is_action_pressed("ui_cancel"):
		if _playing and not _is_finished:
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
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_SPACE and _playing:
			_stop_dot()
			get_viewport().set_input_as_handled()
			return


func _stop_dot() -> void:
	_playing = false
	hint_label.text = ""

	var in_zone := _dot_x >= _target_left and _dot_x <= _target_right
	_can_finish = in_zone

	if in_zone:
		var zone_center := (_target_left + _target_right) * 0.5
		var accuracy := 1.0 - absf(_dot_x - zone_center) / ((_target_right - _target_left) * 0.5)
		var grade := ""
		var color := Color.WHITE
		if accuracy > 0.85:
			grade = "Отлично!"
			color = Color(1.0, 0.92, 0.35)
		elif accuracy > 0.5:
			grade = "Хорошо!"
			color = Color(0.55, 0.9, 0.55)
		else:
			grade = "Попал!"
			color = Color(0.3, 0.75, 0.95)
		_show_result(grade, color)
	else:
		_show_result("Мимо!", Color(0.95, 0.35, 0.35))


func _show_result(text: String, color: Color) -> void:
	_result_shown = true
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)
	finish_button.visible = _can_finish
	result_overlay.visible = true
	modal_blur.visible = true
	feedback_label.text = ""
	if _can_finish:
		emit_signal("puzzle_completed")


func _on_bar_area_resized() -> void:
	if _playing:
		_setup_bar()


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
