class_name SimpleLog
extends Control

## Лог для простого режима балуна: 4 строки, новые реплики дописываются снизу,
## старые поднимаются вверх и сереют, самая старая плавно исчезает.

const LINE_COUNT := 4
const LINE_SCENE: PackedScene = preload("res://addons/dialogue_manager/dialogue_label.tscn")
const SLIDE_OFFSET := 24.0

## Цвет активной (печатающейся) строки
@export var line_color := Color.BLACK
## Цвет уже прочитанных строк
@export var old_line_color := Color(0.75, 0.75, 0.75, 1.0)
## Длительность сдвига/появления/перекраски
@export var animation_duration := 0.25
@export var animation_transition := Tween.TRANS_CUBIC
@export var animation_ease := Tween.EASE_OUT

var _rows: Array[DialogueLabel] = []
var _move_tweens: Dictionary = {}
var _color_tweens: Dictionary = {}
var _active_row: DialogueLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)
	call_deferred("_on_resized")


## Очищает лог (вызывается при переходе в простой режим)
func reset() -> void:
	for row in _rows:
		_kill_move_tween(row)
		_kill_color_tween(row)
		row.queue_free()

	_rows.clear()
	_move_tweens.clear()
	_color_tweens.clear()
	_active_row = null


## Добавляет строку и печатает её. Возвращается после окончания печати.
func show_line(line: DialogueLine) -> void:
	_gray_active_row()

	if _rows.size() >= LINE_COUNT:
		_remove_oldest_row()

	_shift_rows()

	var row := _create_row()
	var target_y := _slot_y(_rows.size())
	add_child(row)
	_rows.append(row)
	_active_row = row

	row.position = Vector2(0.0, target_y + SLIDE_OFFSET)
	row.modulate = Color(1, 1, 1, 0)
	row.dialogue_line = line
	_animate_row_in(row, target_y)

	if not line.text.is_empty():
		row.type_out()
		if row.is_typing:
			await row.finished_typing


## Обновляет текст активной строки без добавления новой (например, при смене локали)
func replace_active_line(line: DialogueLine) -> void:
	if _active_row == null:
		return

	_active_row.dialogue_line = line
	_active_row.visible_characters = -1


func is_typing() -> bool:
	return _active_row != null and _active_row.is_typing


func skip_typing() -> void:
	if _active_row:
		_active_row.skip_typing()


func typed_ratio() -> float:
	return _active_row.visible_ratio if _active_row else 0.0


func _create_row() -> DialogueLabel:
	var row: DialogueLabel = LINE_SCENE.instantiate()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.bbcode_enabled = true
	row.fit_content = false
	row.scroll_active = false
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	row.clip_contents = true
	row.add_theme_color_override("default_color", line_color)
	# Строки расставляются вручную, анкоры из шаблона DialogueLabel не нужны
	row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	row.size = Vector2(size.x, _row_height())
	return row


func _gray_active_row() -> void:
	var row := _active_row
	if row == null:
		return

	_active_row = null

	var from: Color = row.get_theme_color("default_color")
	_kill_color_tween(row)
	var tween := create_tween()
	tween.set_trans(animation_transition).set_ease(animation_ease)
	tween.tween_method(_set_row_color.bind(row), from, old_line_color, animation_duration)
	_color_tweens[row] = tween


func _remove_oldest_row() -> void:
	var oldest: DialogueLabel = _rows.pop_front()
	if oldest == _active_row:
		_active_row = null

	_kill_move_tween(oldest)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(animation_transition).set_ease(animation_ease)
	tween.tween_property(oldest, "position:y", oldest.position.y - SLIDE_OFFSET, animation_duration)
	tween.tween_property(oldest, "modulate:a", 0.0, animation_duration)
	tween.chain().tween_callback(oldest.queue_free)
	_move_tweens[oldest] = tween


func _shift_rows() -> void:
	for index in range(_rows.size()):
		var row := _rows[index]
		var target_y := _slot_y(index)
		if is_equal_approx(row.position.y, target_y):
			continue

		_kill_move_tween(row)
		var tween := create_tween()
		tween.set_trans(animation_transition).set_ease(animation_ease)
		tween.tween_property(row, "position:y", target_y, animation_duration)
		_move_tweens[row] = tween


func _animate_row_in(row: DialogueLabel, target_y: float) -> void:
	_kill_move_tween(row)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(animation_transition).set_ease(animation_ease)
	tween.tween_property(row, "position:y", target_y, animation_duration)
	tween.tween_property(row, "modulate:a", 1.0, animation_duration)
	_move_tweens[row] = tween


func _set_row_color(color: Color, row: DialogueLabel) -> void:
	row.add_theme_color_override("default_color", color)


func _kill_move_tween(row: DialogueLabel) -> void:
	var tween: Tween = _move_tweens.get(row)
	if tween and tween.is_valid():
		tween.kill()
	_move_tweens.erase(row)


func _kill_color_tween(row: DialogueLabel) -> void:
	var tween: Tween = _color_tweens.get(row)
	if tween and tween.is_valid():
		tween.kill()
	_color_tweens.erase(row)


func _on_resized() -> void:
	var row_size := Vector2(size.x, _row_height())
	for index in range(_rows.size()):
		var row := _rows[index]
		row.size = row_size
		row.position.y = _slot_y(index)


func _row_height() -> float:
	return maxf(1.0, size.y / float(LINE_COUNT))


func _slot_y(index: int) -> float:
	return index * _row_height()
