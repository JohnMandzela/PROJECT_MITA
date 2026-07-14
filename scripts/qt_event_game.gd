extends Control

signal exit_requested
signal puzzle_completed

const CHART_PATH := "res://charts/qt_event_config.json"
const KEY_INDICATOR_SCENE := preload("res://scenes/qt_key_indicator.tscn")
const PASS_THRESHOLD := 0.75
const MAX_FAILS := 3
const MODULES_PER_GAME := 5
const COUNTDOWN_DURATION := 2.0
const PHASE_PAUSE_DURATION := 2.0
const KEY_AREA_MARGIN := 120.0

const KEY_TO_SCANCODE := {
	"Q": 81,
	"E": 69,
	"F": 70,
	"Z": 90,
	"X": 88,
	"Space": 32,
	"I": 73,
	"M": 77,
}

const SIMULTANEOUS_KEYS := [
	["Q", "E"],
	["E", "F"],
	["Q", "F"],
	["E", "Z"],
	["F", "Z"],
]

var _config: Dictionary = {}
var _rank_config: Dictionary = {}
var _rank: int = 1
var _bpm: float = 120.0
var _keys: Array = []
var _hit_window: float = 0.1
var _approach_beats: int = 2
var _hold_enabled: bool = false
var _hold_range: Array = [2, 4]
var _simultaneous_enabled: bool = false
var _speed_multiplier: float = 0.0

var _modules: Array = []
var _current_module_index: int = 0
var _phase_hit_count: int = 0
var _phase_miss_count: int = 0
var _total_hit_count: int = 0
var _total_miss_count: int = 0
var _consecutive_fails: int = 0
var _phase_failed: bool = false
var _is_counting_down: bool = false
var _countdown_timer: float = 0.0
var _is_phase_active: bool = false
var _is_game_over: bool = false
var _beat_timer: float = 0.0
var _beat_interval: float = 0.5
var _current_beat: int = 0
var _notes_to_spawn: Array = []
var _next_note_index: int = 0
var _active_notes: Array = []
var _is_paused: bool = false
var _hold_beats_remaining: Dictionary = {}

@onready var background: ColorRect = $Background
@onready var center_pulse: ColorRect = $CenterPulse
@onready var phase_label: Label = $PhaseLabel
@onready var rank_label: Label = $RankLabel
@onready var pass_label: Label = $PassLabel
@onready var key_container: Control = $KeyContainer
@onready var modal_blur: ColorRect = $ModalBlur
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_exit_button: Button = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseExitButton
@onready var pause_continue_button: Button = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseContinueButton
@onready var pause_label: Label = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseLabel


func _ready() -> void:
	_load_config()
	_rank = 1
	_init_rank(_rank)
	_setup_nodes()
	_load_modules()
	_show_ui()
	if _modules.is_empty():
		emit_signal("exit_requested")
		return
	_start_countdown()


func _load_config() -> void:
	if not FileAccess.file_exists(CHART_PATH):
		push_error("QT Event config not found: %s" % CHART_PATH)
		return
	var file := FileAccess.open(CHART_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open QT Event config: %s" % CHART_PATH)
		return
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Failed to parse QT Event config JSON")
		return
	_config = json.data


func _init_rank(rank: int) -> void:
	var ranks: Dictionary = _config.get("ranks", {})
	var key := str(rank)
	if ranks.has(key):
		_rank_config = ranks[key]
	else:
		_rank_config = {
			"bpm": 120,
			"keys": ["Q", "E", "Space"],
			"hit_window_ms": 100,
			"approach_beats": 2,
			"hold_enabled": false,
			"simultaneous_enabled": false,
			"speed_multiplier": 0.0,
		}

	_bpm = _rank_config.get("bpm", 120)
	_keys = _rank_config.get("keys", ["Q", "E", "Space"])
	_hit_window = _rank_config.get("hit_window_ms", 100) / 1000.0
	_approach_beats = _rank_config.get("approach_beats", 2)
	_hold_enabled = _rank_config.get("hold_enabled", false)
	_hold_range = _rank_config.get("hold_range", [2, 4])
	_simultaneous_enabled = _rank_config.get("simultaneous_enabled", false)
	_speed_multiplier = _rank_config.get("speed_multiplier", 0.0)

	var effective_bpm: float = _bpm * (1.0 + _speed_multiplier)
	_beat_interval = 60.0 / effective_bpm


func _setup_nodes() -> void:
	_update_rank_label()
	_update_pass_label()
	_setup_pause_overlay()
	_setup_center_pulse()


func _setup_pause_overlay() -> void:
	if not is_instance_valid(pause_label):
		return
	pause_label.text = "\u0412\u044b\u0439\u0442\u0438 \u0438\u0437 \u043c\u0438\u043d\u0438-\u0438\u0433\u0440\u044b?"
	pause_label.add_theme_font_override("font", preload("res://fonts/Impact.otf"))
	pause_label.add_theme_font_size_override("font_size", 28)
	pause_label.add_theme_color_override("font_color", Color.WHITE)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if is_instance_valid(pause_exit_button):
		pause_exit_button.text = "\u0412\u044b\u0439\u0442\u0438"
		pause_exit_button.pressed.connect(_on_pause_exit_pressed)

	if is_instance_valid(pause_continue_button):
		pause_continue_button.text = "\u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c"
		pause_continue_button.pressed.connect(_on_pause_continue_pressed)


func _setup_center_pulse() -> void:
	if not is_instance_valid(center_pulse):
		return
	center_pulse.color = Color(1.0, 1.0, 1.0, 0.0)
	center_pulse.pivot_offset = center_pulse.size * 0.5


func _load_modules() -> void:
	_modules.clear()
	for i in range(MODULES_PER_GAME):
		_modules.append(_generate_module())
	_current_module_index = 0


func _generate_module() -> Dictionary:
	var key_count: int = _keys.size()
	var note_count: int = clampi(key_count * 3, 8, 20)
	var notes: Array = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(note_count):
		var note: Dictionary = {
			"key": _keys[rng.randi_range(0, key_count - 1)],
			"hold": false,
			"hold_beats": 0,
			"simultaneous": false,
			"simultaneous_key": "",
		}

		if _hold_enabled and rng.randf() < 0.3:
			note["hold"] = true
			note["hold_beats"] = rng.randi_range(_hold_range[0], _hold_range[1])

		if _simultaneous_enabled and rng.randf() < 0.2 and not note["hold"]:
			note["simultaneous"] = true
			var pair: Array = SIMULTANEOUS_KEYS[rng.randi_range(0, SIMULTANEOUS_KEYS.size() - 1)]
			note["key"] = pair[0]
			note["simultaneous_key"] = pair[1]

		notes.append(note)

	return {"notes": notes}


func _process(delta: float) -> void:
	if not visible:
		return

	if _is_counting_down:
		_process_countdown(delta)
		return

	if _is_phase_active and not _is_paused:
		_process_beats(delta)
		_check_missed_notes()
		_process_hold_releases()

	_update_center_pulse(delta)


func _process_countdown(delta: float) -> void:
	_countdown_timer -= delta
	if _countdown_timer <= 0.0:
		_is_counting_down = false
		_begin_phase()


func _process_beats(delta: float) -> void:
	_beat_timer += delta

	while _beat_timer >= _beat_interval:
		_beat_timer -= _beat_interval
		_current_beat += 1
		_on_beat()

	if _next_note_index >= _notes_to_spawn.size() and _active_notes.is_empty():
		_evaluate_phase()


func _on_beat() -> void:
	_pulse_center()

	var approach_time: float = _approach_beats * _beat_interval

	while _next_note_index < _notes_to_spawn.size():
		var note_data: Dictionary = _notes_to_spawn[_next_note_index]
		var note_beat: int = note_data.get("beat", 0)

		if _current_beat >= note_beat:
			_spawn_note(note_data)
			_next_note_index += 1
		else:
			break

	_check_hold_releases_on_beat()


func _spawn_note(note_data: Dictionary) -> void:
	var key_name: String = note_data.get("key", "Space")
	var is_hold: bool = note_data.get("hold", false)
	var hold_beats: int = note_data.get("hold_beats", 0)
	var is_simultaneous: bool = note_data.get("simultaneous", false)
	var simultaneous_key: String = note_data.get("simultaneous_key", "")
	var approach_time: float = _approach_beats * _beat_interval

	var indicator: Control = KEY_INDICATOR_SCENE.instantiate()

	var viewport_size: Vector2 = get_viewport_rect().size
	var margin: float = KEY_AREA_MARGIN
	var indicator_size: float = 400.0
	var x: float = randf_range(margin + indicator_size * 0.5, viewport_size.x - margin - indicator_size * 0.5)
	var y: float = randf_range(margin + indicator_size * 0.5, viewport_size.y - margin - indicator_size * 0.5)
	indicator.position = Vector2(x - indicator_size * 0.5, y - indicator_size * 0.5)

	var group_id: int = -1
	if is_simultaneous:
		group_id = _next_note_index

	indicator.setup(
		key_name, is_hold, hold_beats,
		is_simultaneous, group_id,
		approach_time, _hit_window
	)

	indicator.note_hit.connect(_on_note_hit)
	indicator.note_missed.connect(_on_note_missed)
	indicator.hold_finished.connect(_on_hold_finished)

	key_container.add_child(indicator)
	_active_notes.append(indicator)

	if is_hold:
		_hold_beats_remaining[indicator] = hold_beats

	if is_simultaneous and simultaneous_key != "":
		var second_indicator: Control = KEY_INDICATOR_SCENE.instantiate()
		var x2: float = randf_range(margin + indicator_size * 0.5, viewport_size.x - margin - indicator_size * 0.5)
		var y2: float = randf_range(margin + indicator_size * 0.5, viewport_size.y - margin - indicator_size * 0.5)
		second_indicator.position = Vector2(x2 - indicator_size * 0.5, y2 - indicator_size * 0.5)
		second_indicator.setup(
			simultaneous_key, false, 0,
			true, group_id,
			approach_time, _hit_window
		)
		second_indicator.note_hit.connect(_on_note_hit)
		second_indicator.note_missed.connect(_on_note_missed)
		key_container.add_child(second_indicator)
		_active_notes.append(second_indicator)


func _process_hold_releases() -> void:
	for note in _active_notes:
		if not is_instance_valid(note):
			continue
		if note.is_held() and not note.is_key_pressed():
			note.mark_hold_released_early()


func _check_hold_releases_on_beat() -> void:
	var to_remove: Array = []
	for note in _active_notes:
		if not is_instance_valid(note):
			to_remove.append(note)
			continue
		if note.is_held() and _hold_beats_remaining.has(note):
			_hold_beats_remaining[note] -= 1
			if _hold_beats_remaining[note] <= 0:
				note.mark_hold_release()
				to_remove.append(note)
	for note in to_remove:
		_active_notes.erase(note)
		_hold_beats_remaining.erase(note)


func _check_missed_notes() -> void:
	var to_remove: Array = []
	for note in _active_notes:
		if not is_instance_valid(note):
			to_remove.append(note)
			continue
		if note.get_time_overdue() > _hit_window:
			note.force_miss()
			to_remove.append(note)
	for note in to_remove:
		_active_notes.erase(note)


func _on_note_hit(indicator: Control, key_name: String) -> void:
	_phase_hit_count += 1
	_show_feedback("HIT!", Color(0.2, 0.9, 0.3))
	_flash_center(Color(0.2, 0.9, 0.3))
	if is_instance_valid(indicator):
		indicator.queue_free()


func _on_note_missed(indicator: Control, key_name: String) -> void:
	_phase_miss_count += 1
	_show_feedback("MISS", Color(0.9, 0.2, 0.2))
	_shake_screen()
	if is_instance_valid(indicator):
		indicator.queue_free()

	if _phase_miss_count > 0:
		var total: int = _phase_hit_count + _phase_miss_count
		if total > 0 and float(_phase_miss_count) / float(total) > (1.0 - PASS_THRESHOLD):
			_fail_phase()


func _on_hold_finished(indicator: Control, key_name: String, was_held: bool) -> void:
	if was_held:
		_show_feedback("HOLD!", Color(0.4, 0.8, 1.0))
	_hold_beats_remaining.erase(indicator)
	if is_instance_valid(indicator):
		indicator.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _is_game_over:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if _is_paused:
				_close_pause_overlay()
			else:
				_open_pause_overlay()
			get_viewport().set_input_as_handled()
			return

	if _is_paused:
		return

	if not _is_phase_active:
		return

	if event is InputEventKey and event.pressed:
		_handle_key_press(event)
	elif event is InputEventKey and not event.pressed:
		_handle_key_release(event)


func _handle_key_press(event: InputEventKey) -> void:
	var key_name: String = _scancode_to_key_name(event.keycode)
	if key_name.is_empty():
		return
	if not _keys.has(key_name):
		return

	for note in _active_notes:
		if not is_instance_valid(note):
			continue
		if note.get_key_name() != key_name:
			continue
		if note.is_resolved():
			continue
		if not note.is_in_hit_window():
			continue

		note.set_key_pressed(true)
		if note.was_just_pressed():
			if note.get_note_type() == 0:
				note.mark_hit()
			break


func _handle_key_release(event: InputEventKey) -> void:
	var key_name: String = _scancode_to_key_name(event.keycode)
	if key_name.is_empty():
		return

	for note in _active_notes:
		if not is_instance_valid(note):
			continue
		if note.get_key_name() != key_name:
			continue
		note.set_key_pressed(false)


func _scancode_to_key_name(scancode: int) -> String:
	for key in KEY_TO_SCANCODE:
		if KEY_TO_SCANCODE[key] == scancode:
			return key
	return ""


func _evaluate_phase() -> void:
	_is_phase_active = false

	var total: int = _phase_hit_count + _phase_miss_count
	if total == 0:
		_advance_module()
		return

	var hit_ratio: float = float(_phase_hit_count) / float(total)
	if hit_ratio >= PASS_THRESHOLD:
		_on_phase_passed()
	else:
		_fail_phase()


func _on_phase_passed() -> void:
	_total_hit_count += _phase_hit_count
	_total_miss_count += _phase_miss_count
	_show_feedback(
		"MODULE %d PASSED" % (_current_module_index + 1),
		Color(0.2, 0.9, 0.3)
	)
	_advance_module()


func _fail_phase() -> void:
	_consecutive_fails += 1
	_phase_failed = true
	_is_phase_active = false

	_show_feedback("PHASE FAILED", Color(0.9, 0.2, 0.2))

	if _consecutive_fails >= MAX_FAILS:
		_game_over_restart()
		return

	_restart_current_module()


func _restart_current_module() -> void:
	_clear_active_notes()
	_phase_hit_count = 0
	_phase_miss_count = 0
	_hold_beats_remaining.clear()

	if _rank >= 2:
		_begin_phase()
	else:
		_start_phase_pause()


func _start_phase_pause() -> void:
	_is_paused = true
	_show_feedback("NEXT PHASE...", Color(0.7, 0.7, 0.7))

	await get_tree().create_timer(PHASE_PAUSE_DURATION).timeout

	_is_paused = false
	_begin_phase()


func _advance_module() -> void:
	_current_module_index += 1

	if _current_module_index >= _modules.size():
		_on_all_modules_complete()
		return

	_clear_active_notes()
	_phase_hit_count = 0
	_phase_miss_count = 0
	_hold_beats_remaining.clear()

	if _rank >= 2:
		_begin_phase()
	else:
		_start_phase_pause()


func _on_all_modules_complete() -> void:
	var total: int = _total_hit_count + _total_miss_count
	if total == 0:
		_show_feedback("COMPLETE!", Color(0.2, 0.9, 0.3))
		emit_signal("puzzle_completed")
		return

	var hit_ratio: float = float(_total_hit_count) / float(total)
	if hit_ratio >= PASS_THRESHOLD:
		_show_feedback(
			"PASSED! %.0f%%" % (hit_ratio * 100.0),
			Color(0.2, 0.9, 0.3)
		)
		emit_signal("puzzle_completed")
	else:
		_show_feedback(
			"FAILED! %.0f%%" % (hit_ratio * 100.0),
			Color(0.9, 0.2, 0.2)
		)
		_game_over_restart()


func _game_over_restart() -> void:
	_is_game_over = true
	_show_feedback("RESTARTING ARCHITECTURE...", Color(0.9, 0.2, 0.2))

	await get_tree().create_timer(2.0).timeout

	_consecutive_fails = 0
	_total_hit_count = 0
	_total_miss_count = 0
	_is_game_over = false
	_current_module_index = 0

	_clear_active_notes()
	_load_modules()
	_show_ui()
	_start_countdown()


func _clear_active_notes() -> void:
	for note in _active_notes:
		if is_instance_valid(note):
			note.queue_free()
	_active_notes.clear()
	_hold_beats_remaining.clear()


func _begin_phase() -> void:
	_phase_hit_count = 0
	_phase_miss_count = 0
	_phase_failed = false
	_is_phase_active = true
	_current_beat = 0
	_beat_timer = 0.0

	_update_phase_label()

	var module: Dictionary = _modules[_current_module_index]
	var notes: Array = module.get("notes", [])

	_notes_to_spawn.clear()
	var approach_time: float = _approach_beats * _beat_interval
	var approach_beats: int = _approach_beats

	for i in range(notes.size()):
		var note_data: Dictionary = notes[i]
		var spawn_beat: int = approach_beats + (i * 2)
		note_data["beat"] = spawn_beat
		_notes_to_spawn.append(note_data)

	_next_note_index = 0
	_beat_timer = 0.0


func _start_countdown() -> void:
	_is_counting_down = true
	_countdown_timer = COUNTDOWN_DURATION
	_show_feedback("GET READY...", Color(0.7, 0.7, 0.7))


func _show_ui() -> void:
	_update_rank_label()
	_update_phase_label()
	_update_pass_label()


func _update_rank_label() -> void:
	if is_instance_valid(rank_label):
		rank_label.text = "RANK %d" % _rank
		rank_label.add_theme_font_override("font", preload("res://fonts/Impact.otf"))
		rank_label.add_theme_font_size_override("font_size", 24)
		rank_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))


func _update_phase_label() -> void:
	if is_instance_valid(phase_label):
		phase_label.text = "MODULE %d / %d" % [_current_module_index + 1, _modules.size()]
		phase_label.add_theme_font_override("font", preload("res://fonts/Impact.otf"))
		phase_label.add_theme_font_size_override("font_size", 20)
		phase_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))


func _update_pass_label() -> void:
	if is_instance_valid(pass_label):
		pass_label.text = "PASS: %d%%" % int(PASS_THRESHOLD * 100.0)
		pass_label.add_theme_font_override("font", preload("res://fonts/Impact.otf"))
		pass_label.add_theme_font_size_override("font_size", 18)
		pass_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))


func _show_feedback(text: String, color: Color) -> void:
	if is_instance_valid(pass_label):
		pass_label.text = text
		pass_label.add_theme_color_override("font_color", color)
		pass_label.visible = true


func _pulse_center() -> void:
	if not is_instance_valid(center_pulse):
		return
	center_pulse.color = Color(1.0, 1.0, 1.0, 0.6)
	center_pulse.scale = Vector2(1.3, 1.3)
	center_pulse.pivot_offset = center_pulse.size * 0.5


func _flash_center(color: Color) -> void:
	if not is_instance_valid(center_pulse):
		return
	center_pulse.color = Color(color.r, color.g, color.b, 0.5)
	center_pulse.scale = Vector2(1.1, 1.1)
	center_pulse.pivot_offset = center_pulse.size * 0.5


func _update_center_pulse(delta: float) -> void:
	if not is_instance_valid(center_pulse):
		return
	center_pulse.color.a = lerp(center_pulse.color.a, 0.0, delta * 6.0)
	center_pulse.scale = center_pulse.scale.lerp(Vector2(1.0, 1.0), delta * 8.0)


func _shake_screen() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var original_offset: Vector2 = cam.offset
	for i in range(4):
		cam.offset = original_offset + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		await get_tree().create_timer(0.05).timeout
	cam.offset = original_offset


func _open_pause_overlay() -> void:
	_is_paused = true
	if is_instance_valid(pause_overlay):
		pause_overlay.visible = true
	if is_instance_valid(modal_blur):
		modal_blur.visible = true


func _close_pause_overlay() -> void:
	_is_paused = false
	if is_instance_valid(pause_overlay):
		pause_overlay.visible = false
	if is_instance_valid(modal_blur):
		modal_blur.visible = false


func _on_pause_exit_pressed() -> void:
	_close_pause_overlay()
	_clear_active_notes()
	emit_signal("exit_requested")


func _on_pause_continue_pressed() -> void:
	_close_pause_overlay()


func toggle_pause_overlay_from_pause_menu() -> void:
	if not visible:
		return
	if _is_game_over:
		return
	if _is_paused:
		_close_pause_overlay()
	else:
		_open_pause_overlay()
