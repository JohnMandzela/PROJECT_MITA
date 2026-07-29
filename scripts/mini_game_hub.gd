extends Control

signal exit_requested
signal puzzle_completed

const MINIGAME_SCENES := [
	preload("res://scenes/rhythm_game.tscn"),
	preload("res://scenes/bar_game.tscn"),
	preload("res://scenes/qt_event_game.tscn"),
	preload("res://scenes/corridor_game.tscn"),
]

const GAME_NAMES := [
	"\u0420\u0438\u0442\u043c-\u0438\u0433\u0440\u0430",
	"\u0428\u043a\u0430\u043b\u0430",
	"QT \u0421\u043e\u0431\u044b\u0442\u0438\u044f",
	"\u041a\u043e\u0440\u0438\u0434\u043e\u0440",
]

const BG_COLOR := Color(0.05, 0.05, 0.07)
const DOT_COLOR := Color(0.3, 0.3, 0.35)
const DOT_ACTIVE := Color(0.4, 0.8, 1.0)
const DOT_DONE := Color(0.2, 0.9, 0.3)
const TEXT_COLOR := Color(0.85, 0.85, 0.85)

var _current_index: int = -1
var _active_game: Node = null
var _is_transitioning: bool = false

@onready var background: ColorRect = $Background
@onready var progress_container: Control = $ProgressBar
@onready var game_name_label: Label = $GameNameLabel
@onready var dot_container: HBoxContainer = $ProgressBar/DotContainer
@onready var game_container: Control = $GameContainer
@onready var transition_overlay: ColorRect = $TransitionOverlay

var _dots: Array[ColorRect] = []


func _ready() -> void:
	background.color = BG_COLOR
	transition_overlay.color = Color(0, 0, 0, 1)
	transition_overlay.visible = false
	_create_dots()
	_start_sequence()


func _create_dots() -> void:
	for i in range(MINIGAME_SCENES.size()):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.size = Vector2(16, 16)
		dot.color = DOT_COLOR
		dot_container.add_child(dot)
		_dots.append(dot)


func _start_sequence() -> void:
	_is_transitioning = true
	transition_overlay.visible = true
	transition_overlay.color = Color(0, 0, 0, 1)
	transition_overlay.modulate = Color(1, 1, 1, 1)

	var tween := create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	transition_overlay.visible = false
	_is_transitioning = false
	_load_game(0)


func _load_game(index: int) -> void:
	if index < 0 or index >= MINIGAME_SCENES.size():
		_on_all_complete()
		return

	_current_index = index
	_clear_game()

	var scene: PackedScene = MINIGAME_SCENES[index]
	_active_game = scene.instantiate()
	_active_game.connect("puzzle_completed", Callable(self, "_on_game_completed"))
	_active_game.connect("exit_requested", Callable(self, "_on_game_exit"))
	game_container.add_child(_active_game)
	_active_game.visible = true

	GameManager.minigame_pause_target = _active_game

	_update_progress()


func _clear_game() -> void:
	if _active_game != null:
		if is_instance_valid(_active_game) and _active_game.get_parent() == game_container:
			game_container.remove_child(_active_game)
			_active_game.queue_free()
		_active_game = null


func _update_progress() -> void:
	for i in range(_dots.size()):
		if i < _current_index:
			_dots[i].color = DOT_DONE
		elif i == _current_index:
			_dots[i].color = DOT_ACTIVE
		else:
			_dots[i].color = DOT_COLOR

	if is_instance_valid(game_name_label):
		game_name_label.text = "%d/%d — %s" % [_current_index + 1, MINIGAME_SCENES.size(), GAME_NAMES[_current_index]]
		game_name_label.add_theme_font_override("font", preload("res://fonts/Impact.otf"))
		game_name_label.add_theme_font_size_override("font_size", 22)
		game_name_label.add_theme_color_override("font_color", TEXT_COLOR)
		game_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _on_game_completed() -> void:
	GameManager.minigame_pause_target = null
	_dots[_current_index].color = DOT_DONE
	_advance_to_next()


func _on_game_exit() -> void:
	GameManager.minigame_pause_target = null
	_clear_game()
	emit_signal("exit_requested")


func _advance_to_next() -> void:
	var next_index: int = _current_index + 1
	if next_index >= MINIGAME_SCENES.size():
		_on_all_complete()
		return
	_is_transitioning = true
	transition_overlay.visible = true
	transition_overlay.modulate = Color(1, 1, 1, 0)

	var tween := create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(1, 1, 1, 1), 0.3)
	await tween.finished
	_clear_game()
	_load_game(next_index)
	tween = create_tween()
	tween.tween_property(transition_overlay, "modulate", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	transition_overlay.visible = false
	_is_transitioning = false


func _on_all_complete() -> void:
	_clear_game()
	emit_signal("puzzle_completed")


func toggle_pause_overlay_from_pause_menu() -> void:
	if _active_game != null and is_instance_valid(_active_game):
		if _active_game.has_method("toggle_pause_overlay_from_pause_menu"):
			_active_game.call("toggle_pause_overlay_from_pause_menu")
