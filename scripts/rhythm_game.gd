extends Control

signal exit_requested
signal puzzle_completed

const LANE_COUNT := 3
const LANE_KEYS: Array[int] = [KEY_Z, KEY_X, KEY_C]
const LANE_LABELS: Array[String] = ["Z", "X", "C"]
const LANE_COLORS: Array[Color] = [
	Color(0.95, 0.35, 0.35),
	Color(0.35, 0.75, 0.95),
	Color(0.45, 0.9, 0.45),
	Color(0.95, 0.75, 0.25),
]

const SCROLL_SPEED := 420.0
const LOOK_AHEAD_SEC := 3.0
const PERFECT_WINDOW_MS := 45.0
const GOOD_WINDOW_MS := 110.0
const NOTE_SIZE := Vector2(56, 56)
const LANE_HEIGHT := 72.0
const JUDGEMENT_X := 140.0
const SPAWN_MARGIN := 80.0

const BG_COLOR := Color(0.08, 0.08, 0.1)
const LANE_BG := Color(0.14, 0.14, 0.18)
const LANE_BORDER := Color(0.28, 0.28, 0.34)
const JUDGEMENT_COLOR := Color(0.95, 0.95, 0.95, 0.85)
const TEXT_LIGHT := Color(0.96, 0.96, 0.96)

const PAUSE_TITLE := "Выйти из ритм-игры? Несохранённый прогресс будет потерян."
const PAUSE_EXIT := "Выйти"
const PAUSE_CONTINUE := "Продолжить"
const SUCCESS_TEXT := "Отлично! Трек пройден."
const RESTART_TEXT := "Начать заново"
const FINISH_TEXT := "Завершить"
const START_HINT := "Нажмите Пробел, чтобы начать"

@export var chart_path: String = "res://charts/demo_chart.json"
@export var auto_start: bool = false
@export var completion_score_threshold: int = 0

@onready var background: ColorRect = $Background
@onready var playfield: Control = $Playfield
@onready var lanes_root: Control = $Playfield/Lanes
@onready var notes_root: Control = $Playfield/Notes
@onready var judgement_line: ColorRect = $Playfield/JudgementLine
@onready var lane_hints_root: Control = $Playfield/LaneHints
@onready var score_label: Label = $UI/TopBar/ScoreLabel
@onready var combo_label: Label = $UI/TopBar/ComboLabel
@onready var title_label: Label = $UI/TopBar/TitleLabel
@onready var feedback_label: Label = $UI/FeedbackLabel
@onready var start_hint_label: Label = $UI/StartHintLabel
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var modal_blur: ColorRect = $ModalBlur
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_label: Label = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseLabel
@onready var pause_exit_button: Button = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseExitButton
@onready var pause_continue_button: Button = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseContinueButton
@onready var success_overlay: Control = $SuccessOverlay
@onready var success_label: Label = $SuccessOverlay/SuccessPanel/SuccessMargin/SuccessVBox/SuccessLabel
@onready var restart_button: Button = $SuccessOverlay/SuccessPanel/SuccessMargin/SuccessVBox/RestartButton
@onready var finish_button: Button = $SuccessOverlay/SuccessPanel/SuccessMargin/SuccessVBox/FinishButton

var _chart: Dictionary = {}
var _note_defs: Array[Dictionary] = []
var _next_spawn_index := 0
var _active_notes: Array[Dictionary] = []
var _lane_y: Array[float] = []

var _playing := false
var _paused_time := 0.0
var _started_at_usec := 0
var _audio_offset := 0.0

var _score := 0
var _combo := 0
var _max_combo := 0
var _perfect_count := 0
var _good_count := 0
var _miss_count := 0
var _is_finished := false
var _can_finish := false
var _feedback_timer := 0.0

var _note_pool: Array[Control] = []


func _ready() -> void:
	background.color = BG_COLOR
	judgement_line.color = JUDGEMENT_COLOR
	pause_label.text = PAUSE_TITLE
	pause_exit_button.text = PAUSE_EXIT
	pause_continue_button.text = PAUSE_CONTINUE
	success_label.text = SUCCESS_TEXT
	restart_button.text = RESTART_TEXT
	finish_button.text = FINISH_TEXT
	start_hint_label.text = START_HINT

	pause_exit_button.pressed.connect(_on_pause_exit_pressed)
	pause_continue_button.pressed.connect(_on_pause_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	playfield.resized.connect(_rebuild_lanes)

	_load_chart()
	call_deferred("_rebuild_lanes")
	_reset_run()


func _load_chart() -> void:
	if not FileAccess.file_exists(chart_path):
		push_error("Rhythm chart not found: %s" % chart_path)
		return

	var file := FileAccess.open(chart_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid rhythm chart JSON: %s" % chart_path)
		return

	_chart = parsed
	title_label.text = str(_chart.get("title", "Rhythm Game"))
	_audio_offset = float(_chart.get("offset", 0.0))

	var raw_notes: Variant = _chart.get("notes", [])
	_note_defs.clear()
	if raw_notes is Array:
		for entry in raw_notes:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var lane := int(entry.get("lane", -1))
			var time_sec := float(entry.get("time", -1.0))
			if lane < 0 or lane >= LANE_COUNT or time_sec < 0.0:
				continue
			_note_defs.append({"lane": lane, "time": time_sec})

	_note_defs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["time"]) < float(b["time"])
	)

	var audio_path := str(_chart.get("audio", ""))
	if not audio_path.is_empty() and ResourceLoader.exists(audio_path):
		audio_player.stream = load(audio_path)


func _reset_run() -> void:
	_playing = false
	_paused_time = 0.0
	_started_at_usec = 0
	_next_spawn_index = 0
	_is_finished = false
	_can_finish = false
	_score = 0
	_combo = 0
	_max_combo = 0
	_perfect_count = 0
	_good_count = 0
	_miss_count = 0
	_feedback_timer = 0.0

	audio_player.stop()
	_clear_active_notes()
	_despawn_all_pooled_notes()

	pause_overlay.visible = false
	success_overlay.visible = false
	finish_button.visible = false
	modal_blur.visible = false
	feedback_label.text = ""
	start_hint_label.visible = not auto_start
	_update_hud()

	if auto_start:
		call_deferred("_start_song")


func _start_song() -> void:
	if _is_finished:
		return
	start_hint_label.visible = false
	_next_spawn_index = 0
	_clear_active_notes()
	_despawn_all_pooled_notes()
	_paused_time = 0.0
	_started_at_usec = Time.get_ticks_usec()
	_playing = true
	if audio_player.stream != null:
		audio_player.play()


func _get_song_time() -> float:
	if not _playing:
		return _paused_time
	if audio_player.stream != null and audio_player.playing:
		return (
			audio_player.get_playback_position()
			+ AudioServer.get_time_since_last_mix()
			- _audio_offset
		)
	return float(Time.get_ticks_usec() - _started_at_usec) / 1_000_000.0 - _audio_offset


func _process(delta: float) -> void:
	if not _playing or _is_finished:
		return

	var song_time := _get_song_time()
	_spawn_due_notes(song_time)
	_update_note_positions(song_time)
	_check_missed_notes(song_time)
	_update_hud()

	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0:
			feedback_label.text = ""

	if _all_notes_resolved() and _is_song_over(song_time):
		_finish_success()


func _spawn_due_notes(song_time: float) -> void:
	while _next_spawn_index < _note_defs.size():
		var note_def: Dictionary = _note_defs[_next_spawn_index]
		var note_time := float(note_def["time"])
		if note_time > song_time + LOOK_AHEAD_SEC:
			break
		_spawn_note(int(note_def["lane"]), note_time)
		_next_spawn_index += 1


func _spawn_note(lane: int, note_time: float) -> void:
	var note_node := _acquire_note_node(lane)
	notes_root.add_child(note_node)
	note_node.visible = true
	_active_notes.append({
		"lane": lane,
		"time": note_time,
		"node": note_node,
		"resolved": false,
	})


func _update_note_positions(song_time: float) -> void:
	var spawn_x := playfield.size.x + SPAWN_MARGIN
	for entry in _active_notes:
		if bool(entry.get("resolved", false)):
			continue
		var note_time := float(entry["time"])
		var delta_time := note_time - song_time
		var x_pos := JUDGEMENT_X + delta_time * SCROLL_SPEED
		var node: Control = entry["node"]
		node.position = Vector2(x_pos - NOTE_SIZE.x * 0.5, _lane_y[int(entry["lane"])] - NOTE_SIZE.y * 0.5)
		node.modulate = Color.WHITE if x_pos <= spawn_x else Color(1, 1, 1, 0)


func _check_missed_notes(song_time: float) -> void:
	var miss_window_sec := GOOD_WINDOW_MS / 1000.0
	for entry in _active_notes:
		if bool(entry.get("resolved", false)):
			continue
		var note_time := float(entry["time"])
		if song_time - note_time > miss_window_sec:
			_register_miss(entry)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if success_overlay.visible:
		return

	if event.is_action_pressed("ui_cancel"):
		if pause_overlay.visible:
			_close_pause_overlay()
		else:
			_open_pause_overlay()
		get_viewport().set_input_as_handled()
		return

	if _is_finished or pause_overlay.visible:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_SPACE and not _playing:
			_start_song()
			get_viewport().set_input_as_handled()
			return

		if not _playing:
			return

		for lane in range(LANE_COUNT):
			if key_event.keycode == LANE_KEYS[lane]:
				_try_hit_lane(lane)
				get_viewport().set_input_as_handled()
				return


func _try_hit_lane(lane: int) -> void:
	var song_time := _get_song_time()
	var best_entry: Dictionary = {}
	var best_abs_error := INF

	for entry in _active_notes:
		if bool(entry.get("resolved", false)):
			continue
		if int(entry["lane"]) != lane:
			continue
		var error_ms := (float(entry["time"]) - song_time) * 1000.0
		var abs_error := absf(error_ms)
		if abs_error <= GOOD_WINDOW_MS and abs_error < best_abs_error:
			best_abs_error = abs_error
			best_entry = entry

	if best_entry.is_empty():
		_break_combo()
		_show_feedback("—", Color(0.7, 0.7, 0.7))
		return

	if best_abs_error <= PERFECT_WINDOW_MS:
		_register_hit(best_entry, 300, "Perfect!", Color(1.0, 0.92, 0.35))
		_perfect_count += 1
	elif best_abs_error <= GOOD_WINDOW_MS:
		_register_hit(best_entry, 100, "Good", Color(0.55, 0.9, 0.55))
		_good_count += 1


func _register_hit(entry: Dictionary, points: int, text: String, color: Color) -> void:
	entry["resolved"] = true
	_score += points
	_combo += 1
	_max_combo = maxi(_max_combo, _combo)
	_show_feedback(text, color)
	_release_note_node(entry["node"])


func _register_miss(entry: Dictionary) -> void:
	entry["resolved"] = true
	_miss_count += 1
	_break_combo()
	_show_feedback("Miss", Color(0.95, 0.35, 0.35))
	_release_note_node(entry["node"])


func _break_combo() -> void:
	_combo = 0


func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	_feedback_timer = 0.45


func _release_note_node(node: Control) -> void:
	node.visible = false
	node.get_parent().remove_child(node)
	_note_pool.append(node)


func _acquire_note_node(lane: int) -> Control:
	var note_node: Control
	if _note_pool.is_empty():
		note_node = _create_note_node(lane)
	else:
		note_node = _note_pool.pop_back()
		_style_note_node(note_node, lane)
	return note_node


func _create_note_node(lane: int) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = NOTE_SIZE
	panel.size = NOTE_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.name = "KeyLabel"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	_style_note_node(panel, lane)
	return panel


func _style_note_node(note_node: Control, lane: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = LANE_COLORS[lane]
	style.border_color = Color.WHITE
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	note_node.add_theme_stylebox_override("panel", style)

	var label: Label = note_node.get_node("KeyLabel")
	label.text = LANE_LABELS[lane]
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 24)


func _clear_active_notes() -> void:
	for entry in _active_notes:
		if entry.has("node") and is_instance_valid(entry["node"]):
			entry["node"].queue_free()
	_active_notes.clear()


func _despawn_all_pooled_notes() -> void:
	for node in _note_pool:
		if is_instance_valid(node):
			node.queue_free()
	_note_pool.clear()


func _all_notes_resolved() -> bool:
	return _next_spawn_index >= _note_defs.size() and _active_notes.all(
		func(entry: Dictionary) -> bool: return bool(entry.get("resolved", false))
	)


func _is_song_over(song_time: float) -> bool:
	if _note_defs.is_empty():
		return song_time >= 1.0
	var last_time := float(_note_defs[_note_defs.size() - 1]["time"])
	return song_time >= last_time + LOOK_AHEAD_SEC


func _finish_success() -> void:
	_is_finished = true
	_playing = false
	audio_player.stop()
	_can_finish = completion_score_threshold <= 0 or _score >= completion_score_threshold
	success_label.text = (
		"%s\nPerfect: %d  Good: %d  Miss: %d\nScore: %d  Max combo: %d"
		% [SUCCESS_TEXT, _perfect_count, _good_count, _miss_count, _score, _max_combo]
	)
	finish_button.visible = _can_finish
	success_overlay.visible = true
	modal_blur.visible = true
	if _can_finish:
		emit_signal("puzzle_completed")


func _update_hud() -> void:
	score_label.text = "Score: %d" % _score
	combo_label.text = "Combo: %d" % _combo if _combo >= 2 else ""


func _rebuild_lanes() -> void:
	for child in lanes_root.get_children():
		child.queue_free()
	for child in lane_hints_root.get_children():
		child.queue_free()

	_lane_y.clear()
	var total_height := playfield.size.y
	var top := (total_height - LANE_COUNT * LANE_HEIGHT) * 0.5

	for lane in range(LANE_COUNT):
		var y_center := top + LANE_HEIGHT * (float(lane) + 0.5)
		_lane_y.append(y_center)

		var lane_bg := ColorRect.new()
		lane_bg.color = LANE_BG if lane % 2 == 0 else LANE_BG.lightened(0.04)
		lane_bg.position = Vector2(0, top + lane * LANE_HEIGHT)
		lane_bg.size = Vector2(playfield.size.x, LANE_HEIGHT)
		lanes_root.add_child(lane_bg)

		var divider := ColorRect.new()
		divider.color = LANE_BORDER
		divider.position = Vector2(0, top + (lane + 1) * LANE_HEIGHT - 1)
		divider.size = Vector2(playfield.size.x, 2)
		lanes_root.add_child(divider)

		var hint := Label.new()
		hint.text = LANE_LABELS[lane]
		hint.add_theme_color_override("font_color", LANE_COLORS[lane])
		hint.add_theme_font_size_override("font_size", 20)
		hint.position = Vector2(24, y_center - 14)
		lane_hints_root.add_child(hint)

	judgement_line.position = Vector2(JUDGEMENT_X - 2, top - 8)
	judgement_line.size = Vector2(4, LANE_COUNT * LANE_HEIGHT + 16)


func _open_pause_overlay() -> void:
	if _is_finished:
		return
	_paused_time = _get_song_time()
	_playing = false
	if audio_player.stream != null:
		audio_player.stream_paused = true
	pause_overlay.visible = true
	modal_blur.visible = true


func _close_pause_overlay() -> void:
	pause_overlay.visible = false
	modal_blur.visible = success_overlay.visible
	if _is_finished:
		return
	if audio_player.stream != null:
		audio_player.stream_paused = false
	else:
		_started_at_usec = Time.get_ticks_usec() - int(_paused_time * 1_000_000.0)
	_playing = true


func toggle_pause_overlay_from_pause_menu() -> void:
	if not visible:
		return
	if success_overlay.visible:
		return
	if pause_overlay.visible:
		_close_pause_overlay()
	else:
		_open_pause_overlay()


func _on_pause_continue_pressed() -> void:
	_close_pause_overlay()


func _on_pause_exit_pressed() -> void:
	_close_pause_overlay()
	_reset_run()
	emit_signal("exit_requested")


func _on_restart_pressed() -> void:
	success_overlay.visible = false
	modal_blur.visible = false
	_reset_run()


func _on_finish_pressed() -> void:
	if not _can_finish:
		return
	emit_signal("exit_requested")
