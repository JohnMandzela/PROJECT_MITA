extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.

enum PortraitSide {
	LEFT,
	RIGHT,
}

enum BalloonMode {
	DEFAULT,
	SIMPLE,
}

const SKIP_REPEAT_DELAY := 0.12
const SIMPLE_LINE_COUNT := 4
const SIMPLE_BLOCK_MARGIN := 100.0
const SIMPLE_BALLOON_PATH := "res://scenes/ui/simple_balloon.tscn"

## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use while fast-forwarding dialogue.
@export var skip_action: StringName = &"skip_dialogue"

## A sound player for voice lines (if they exist).
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = { }

var _locale: String = TranslationServer.get_locale()
var _skip_advance_cooldown := 0.0
var _is_advancing := false
var _is_skip_button_held := false
var _skip_advance_after_typing := false
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _has_dialogue_mouse_mode := false
var _balloon_mode: BalloonMode = BalloonMode.DEFAULT
var _simple_lines_container: VBoxContainer = null
var _simple_line_slots: Array[Control] = []
var _simple_static_labels: Array[RichTextLabel] = []
var _simple_displayed_texts: PackedStringArray = []
var _simple_current_slot := -1

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			_restore_dialogue_mouse_mode()
			if owner == null:
				GameManager.disable_movement = false
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

@onready var left_portrait: CharacterPortrait = %LeftPortrait

@onready var right_portrait: CharacterPortrait = %RightPortrait

## Indicator to show that player can progress dialogue.
@onready var progress: Polygon2D = %Progress

## Button held by mouse/touch to fast-forward dialogue.
@onready var skip_button: Button = %SkipButton


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.gui_input.connect(_on_skip_button_gui_input)
	skip_button.button_down.connect(_on_skip_button_button_down)
	skip_button.button_up.connect(_on_skip_button_button_up)

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


func _process(delta: float) -> void:
	if is_instance_valid(dialogue_line):
		_enter_dialogue_mouse_mode()
		progress.visible = _balloon_mode != BalloonMode.SIMPLE and not dialogue_label.is_typing and dialogue_line.responses.is_empty() and not dialogue_line.has_tag("voice")
		skip_button.disabled = _should_disable_skip_button()
		if skip_button.disabled:
			_is_skip_button_held = false
		_handle_skip_held(delta)


func _input(event: InputEvent) -> void:
	if not _is_skip_button_held:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_set_skip_button_held(false)
	elif event is InputEventScreenTouch and not event.pressed:
		_set_skip_button_held(false)


func _unhandled_input(_event: InputEvent) -> void:
	if is_instance_valid(dialogue_line):
		if dialogue_label.is_typing and (_event.is_action_pressed(next_action) or _event_is_skip(_event)):
			dialogue_label.skip_typing()
			_mark_input_handled()
			return

		if is_waiting_for_input and dialogue_line.responses.is_empty() and _event.is_action_pressed(next_action):
			next(dialogue_line.next_id)
			_mark_input_handled()
			return

	_mark_input_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


func _exit_tree() -> void:
	_restore_dialogue_mouse_mode()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	GameManager.disable_movement = true
	_enter_dialogue_mouse_mode()
	_reset_simple_lines()

	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


## Switch to simple centered text mode (no portraits, no background panel)
func switch_to_simple_mode() -> void:
	_balloon_mode = BalloonMode.SIMPLE
	_reset_simple_lines()
	_ensure_simple_lines_container()

	left_portrait.hide()
	right_portrait.hide()
	character_label.hide()
	progress.hide()
	responses_menu.hide()

	_move_dialogue_label_to_simple_slot(0)

	var panel := balloon.find_child("PanelContainer", true, false)
	if panel:
		panel.hide()

	var outer_margin := balloon.find_child("MarginContainer", false, false)
	if outer_margin:
		outer_margin.hide()

	dialogue_label.add_theme_color_override("default_color", Color(0, 0, 0, 1))
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dialogue_label.fit_content = false
	dialogue_label.scroll_active = false
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func switch_balloon(balloon_name: String) -> void:
	if balloon_name == "simple":
		switch_to_simple_mode()


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func get_portrait_side(character: String) -> PortraitSide:
	assert(character, "get_portrait_side() вызвана для строки диалога без персонажа")

	var current_side = null
	if left_portrait._character == character:
		current_side = PortraitSide.LEFT
	elif right_portrait._character == character:
		current_side = PortraitSide.RIGHT

	var side := dialogue_line.get_tag_value("side")
	if current_side != null and side:
		push_warning("Персонаж '%s' уже отображается с стороны '%s', но в строке диалога '%s' присутствует тег со стороной '%s'" % [character, current_side, dialogue_line.id, side])

	if current_side != null:
		return current_side

	if side == "left":
		return PortraitSide.LEFT
	elif side == "right":
		return PortraitSide.RIGHT
	elif side:
		push_warning("Некорректная сторона '%s' для персонажа '%s' в строке диалога '%s'" % [side, character, dialogue_line.id])

	if not left_portrait._character:
		return PortraitSide.LEFT
	elif not right_portrait._character:
		return PortraitSide.RIGHT

	push_warning("Оба портрета уже заняты, но в строке диалога '%s' нет тега со стороной для персонажа '%s'" % [dialogue_line.id, character])
	return PortraitSide.LEFT


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	_enter_dialogue_mouse_mode()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	if _balloon_mode == BalloonMode.SIMPLE:
		dialogue_label.hide()
		_simple_current_slot = min(_simple_displayed_texts.size(), SIMPLE_LINE_COUNT - 1)
		_move_dialogue_label_to_simple_slot(_simple_current_slot)
		_refresh_simple_static_labels(_simple_current_slot)
		dialogue_label.dialogue_line = dialogue_line
		responses_menu.hide()
		responses_menu.responses = dialogue_line.responses
		skip_button.disabled = _should_disable_skip_button()
		balloon.show()
		will_hide_balloon = false
		dialogue_label.show()
	else:
		var character := dialogue_line.character
		character_label.visible = not character.is_empty()
		character_label.text = tr(character, "dialogue")

		if character:
			var emotion := &""
			for emotion_name in Enums.Emote.keys():
				if emotion_name.to_lower() in dialogue_line.tags:
					emotion = emotion_name.to_lower()
					break

			var current_portrait: CharacterPortrait
			var other_portrait: CharacterPortrait

			if get_portrait_side(character) == PortraitSide.LEFT:
				current_portrait = left_portrait
				other_portrait = right_portrait
			else:
				current_portrait = right_portrait
				other_portrait = left_portrait

			current_portrait.set_character(character, emotion)
			current_portrait.set_active()
			other_portrait.set_inactive()

		dialogue_label.hide()
		dialogue_label.dialogue_line = dialogue_line

		responses_menu.hide()
		responses_menu.responses = dialogue_line.responses
		skip_button.disabled = _should_disable_skip_button()

		balloon.show()
		will_hide_balloon = false

		dialogue_label.show()

	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		if dialogue_label.is_typing:
			await dialogue_label.finished_typing
		_record_simple_line_after_typing()

	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
		return

	if dialogue_line.responses:
		_skip_advance_after_typing = false
		skip_button.disabled = true
		_is_skip_button_held = false
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		return

	if dialogue_line.time != "":
		_skip_advance_after_typing = false
		var line_time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(line_time).timeout
		next(dialogue_line.next_id)
		return

	is_waiting_for_input = true
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()
	if _skip_advance_after_typing and _advance_from_skip_request():
		return


## Go to the next line
func next(next_id: String) -> void:
	if _is_advancing:
		return
	_is_advancing = true
	var next_dialogue_line: DialogueLine = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)
	_is_advancing = false
	dialogue_line = next_dialogue_line

#region Dialogue Functions

# Затухание
func fade_out(seconds: Variant = null) -> void:
	GameManager.screen_fader.fade_out(seconds)

	# Если передана длительность, ставим диалог на паузу до конца плавного появления
	# Если не передана, то продолжаем после конца затенения
	if seconds != null:
		await GameManager.screen_fader.fade_in_finished
	else:
		await GameManager.screen_fader.fade_out_finished


# Плавное появление
func fade_in() -> void:
	GameManager.screen_fader.fade_in()
	await GameManager.screen_fader.fade_in_finished


# Скрыть портрет персонажа по имени
func hide_portrait(character: String) -> void:
	if left_portrait._character == character:
		await left_portrait.hide_character()
	elif right_portrait._character == character:
		await right_portrait.hide_character()
	else:
		push_warning("Функция hide_portrait() вызвана с персонажем '%s', который не участвует в диалоге" % [character])


func _update_portraits(character: String) -> void:
	if character.is_empty():
		left_portrait.set_inactive()
		right_portrait.set_inactive()
		return

	var prefix: String = str(DialogueGlobals.PORTRAIT_PREFIXES.get(character, ""))
	if prefix.is_empty():
		left_portrait.set_inactive()
		right_portrait.set_inactive()
		return

	var emotion := _get_line_emotion()

	var current_portrait: CharacterPortrait
	var other_portrait: CharacterPortrait

	match get_portrait_side(character):
		PortraitSide.LEFT:
			current_portrait = left_portrait
			other_portrait = right_portrait
		PortraitSide.RIGHT:
			current_portrait = right_portrait
			other_portrait = left_portrait

	if current_portrait._character != character and not current_portrait._character.is_empty():
		await current_portrait.hide_character()

	await current_portrait.set_character(character, emotion)
	current_portrait.set_active()
	if not other_portrait._character.is_empty():
		other_portrait.set_inactive()
	else:
		other_portrait.visible = false


func _get_line_emotion() -> String:
	var emotion := dialogue_line.get_tag_value("emotion").to_lower()
	if emotion.to_upper() in Enums.Emote.keys():
		return emotion.to_lower()

	for emotion_name in Enums.Emote.keys():
		if dialogue_line.has_tag(emotion_name.to_lower()):
			return emotion_name.to_lower()

	return ""


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = _event_is_skip(event)
		if mouse_was_clicked or skip_button_was_pressed:
			_mark_input_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input:
		return
	if dialogue_line.responses.size() > 0:
		return

	_mark_input_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and _balloon_has_focus():
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


func _handle_skip_held(delta: float) -> void:
	if not _is_skip_held():
		_skip_advance_cooldown = 0.0
		return

	_skip_advance_cooldown -= delta
	if _skip_advance_cooldown <= 0.0:
		_skip_advance_cooldown = SKIP_REPEAT_DELAY
		_skip_current_line()


func _skip_current_line() -> bool:
	if not is_instance_valid(dialogue_line):
		return false
	if _is_advancing:
		return false

	if dialogue_label.is_typing:
		_skip_advance_after_typing = true
		dialogue_label.skip_typing()
		return true

	if dialogue_line.responses.size() > 0:
		return false

	if is_waiting_for_input:
		return _advance_from_skip_request()

	return false


func _advance_from_skip_request() -> bool:
	if not is_waiting_for_input:
		return false
	if dialogue_label.is_typing:
		return false
	if not is_instance_valid(dialogue_line):
		return false
	if _is_advancing:
		return false
	if dialogue_line.responses.size() > 0:
		return false

	is_waiting_for_input = false
	_skip_advance_after_typing = false
	next(dialogue_line.next_id)
	return true


func _is_skip_held() -> bool:
	if _is_skip_button_held:
		return true
	if InputMap.has_action(skip_action) and Input.is_action_pressed(skip_action):
		return true
	return Input.is_physical_key_pressed(KEY_TAB)


func _event_is_skip(event: InputEvent) -> bool:
	if InputMap.has_action(skip_action) and event.is_action_pressed(skip_action):
		return true
	return event is InputEventKey and event.physical_keycode == KEY_TAB and event.pressed


func _on_skip_button_button_down() -> void:
	_set_skip_button_held(true)


func _on_skip_button_button_up() -> void:
	_set_skip_button_held(false)


func _on_skip_button_gui_input(event: InputEvent) -> void:
	if skip_button.disabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mark_input_handled()
		_set_skip_button_held(event.pressed)
	elif event is InputEventScreenTouch:
		_mark_input_handled()
		_set_skip_button_held(event.pressed)


func _set_skip_button_held(held: bool) -> void:
	if held and skip_button.disabled:
		return
	if held == _is_skip_button_held:
		return

	_is_skip_button_held = held
	if not held:
		return

	_enter_dialogue_mouse_mode()
	_skip_advance_cooldown = SKIP_REPEAT_DELAY
	_skip_current_line()


func _should_disable_skip_button() -> bool:
	return is_instance_valid(dialogue_line) and not dialogue_line.responses.is_empty() and not dialogue_label.is_typing


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _balloon_has_focus() -> bool:
	var viewport := get_viewport()
	return viewport != null and viewport.gui_get_focus_owner() == balloon


func _enter_dialogue_mouse_mode() -> void:
	if not _has_dialogue_mouse_mode:
		_previous_mouse_mode = Input.get_mouse_mode()
		_has_dialogue_mouse_mode = true

	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _restore_dialogue_mouse_mode() -> void:
	_is_skip_button_held = false
	_skip_advance_after_typing = false
	if not _has_dialogue_mouse_mode:
		return

	Input.set_mouse_mode(_previous_mouse_mode)
	_has_dialogue_mouse_mode = false


func _ensure_simple_lines_container() -> void:
	if _simple_lines_container != null:
		return

	_simple_lines_container = VBoxContainer.new()
	_simple_lines_container.name = "SimpleLinesContainer"
	_simple_lines_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_simple_lines_container.offset_left = SIMPLE_BLOCK_MARGIN
	_simple_lines_container.offset_top = SIMPLE_BLOCK_MARGIN
	_simple_lines_container.offset_right = -SIMPLE_BLOCK_MARGIN
	_simple_lines_container.offset_bottom = -SIMPLE_BLOCK_MARGIN
	_simple_lines_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_simple_lines_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	balloon.add_child(_simple_lines_container)

	for index in range(SIMPLE_LINE_COUNT):
		var slot := MarginContainer.new()
		slot.name = "SimpleLineSlot%d" % [index + 1]
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_simple_lines_container.add_child(slot)
		_simple_line_slots.append(slot)

		var static_label := RichTextLabel.new()
		static_label.name = "SimpleStaticLine%d" % [index + 1]
		static_label.bbcode_enabled = true
		static_label.fit_content = false
		static_label.scroll_active = false
		static_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		static_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		static_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		static_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		static_label.add_theme_color_override("default_color", Color(0, 0, 0, 1))
		static_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		static_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		slot.add_child(static_label)
		_simple_static_labels.append(static_label)


func _reset_simple_lines() -> void:
	_simple_displayed_texts.clear()
	_simple_current_slot = -1
	if _simple_static_labels.is_empty():
		return
	for static_label in _simple_static_labels:
		static_label.text = ""
		static_label.hide()


func _move_dialogue_label_to_simple_slot(slot_index: int) -> void:
	if _simple_line_slots.is_empty():
		return
	slot_index = clampi(slot_index, 0, _simple_line_slots.size() - 1)
	var target_slot := _simple_line_slots[slot_index]
	if dialogue_label.get_parent() != target_slot:
		var label_parent := dialogue_label.get_parent()
		if label_parent:
			label_parent.remove_child(dialogue_label)
		target_slot.add_child(dialogue_label)
	dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_label.offset_left = 0
	dialogue_label.offset_top = 0
	dialogue_label.offset_right = 0
	dialogue_label.offset_bottom = 0


func _refresh_simple_static_labels(_active_slot: int = -1) -> void:
	for index in range(_simple_static_labels.size()):
		var static_label := _simple_static_labels[index]
		static_label.text = ""
		static_label.hide()


func _record_simple_line_after_typing() -> void:
	if _balloon_mode != BalloonMode.SIMPLE:
		return
	if _simple_current_slot < 0:
		return
	if _simple_current_slot < _simple_displayed_texts.size():
		return
	if _simple_displayed_texts.size() >= SIMPLE_LINE_COUNT:
		return

	_simple_displayed_texts.append(dialogue_line.text)
	_refresh_simple_static_labels(_simple_current_slot)
