extends CanvasLayer
## A simple dialogue balloon with centered text for use with Dialogue Manager.

const SKIP_REPEAT_DELAY := 0.12
const SIMPLE_LINE_COUNT := 4

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
var locals: Dictionary = {}

## Store the current dialogue resource
var _dialogue_resource: DialogueResource

var _locale: String = TranslationServer.get_locale()
var _skip_advance_cooldown := 0.0
var _is_advancing := false
var _is_skip_button_held := false
var _skip_advance_after_typing := false
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _has_dialogue_mouse_mode := false
var _simple_line_index := 0
var _current_line_prefix_characters := 0

## The current line (backing field)
var _dialogue_line: DialogueLine

var dialogue_line: DialogueLine:
	set(value):
		if value:
			_dialogue_line = value
			apply_dialogue_line()
		else:
			_restore_dialogue_mouse_mode()
			if owner == null:
				GameManager.disable_movement = false
				queue_free()
			else:
				hide()
	get:
		return _dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: Control = %ResponsesMenu if has_node("%ResponsesMenu") else null

## Button held by mouse/touch to fast-forward dialogue.
@onready var skip_button: Button = %SkipButton


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if responses_menu and responses_menu.has_method("set_next_action"):
		responses_menu.set_next_action(next_action)

	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.gui_input.connect(_on_skip_button_gui_input)
	skip_button.button_down.connect(_on_skip_button_button_down)
	skip_button.button_up.connect(_on_skip_button_button_up)

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, "Missing dialogue resource for autostart")
		start()


func _process(delta: float) -> void:
	if is_instance_valid(dialogue_line):
		skip_button.disabled = false
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


func _exit_tree() -> void:
	_restore_dialogue_mouse_mode()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	_simple_line_index = 0
	_current_line_prefix_characters = 0
	GameManager.disable_movement = true
	_enter_dialogue_mouse_mode()

	if is_instance_valid(with_dialogue_resource):
		_dialogue_resource = with_dialogue_resource
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await _dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	_enter_dialogue_mouse_mode()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	dialogue_label.dialogue_line = _build_display_dialogue_line(dialogue_line)

	if responses_menu:
		responses_menu.hide()
	if responses_menu and dialogue_line.responses:
		responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		if _current_line_prefix_characters > 0:
			dialogue_label.visible_characters = _current_line_prefix_characters
		if dialogue_label.is_typing:
			await dialogue_label.finished_typing

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
		if responses_menu:
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
	var next_dialogue_line: DialogueLine = await _dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)
	_is_advancing = false
	dialogue_line = next_dialogue_line


func _on_skip_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_set_skip_button_held(true)
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_set_skip_button_held(false)


func _on_skip_button_button_down() -> void:
	_set_skip_button_held(true)


func _on_skip_button_button_up() -> void:
	_set_skip_button_held(false)


func _on_mutated(mutation: Dictionary) -> void:
	var mutation_type: String = mutation.get("type", "")

	if mutation_type == "run_logic":
		var should_hide_balloon: bool = false
		var title: String = mutation.get("title", "")
		var is_long_running: bool = mutation.get("is_long_running", false)

		if is_long_running:
			should_hide_balloon = true
			will_hide_balloon = true

		if should_hide_balloon:
			mutation_cooldown.wait_time = 0.1
			mutation_cooldown.timeout.connect(balloon.hide)
			mutation_cooldown.one_shot = true
			mutation_cooldown.start()

		if mutation.has("function_name"):
			_run_mutation(mutation)


func _run_mutation(mutation: Dictionary) -> void:
	var states: Array = [self] + temporary_game_states + DialogueManager.game_states

	var targets: Array = mutation.get("targets", [])
	var target: String = mutation.get("target", "")

	if not target.is_empty():
		targets = [target]

	var function_name: String = mutation.get("function_name", "")

	## Try to find the target
	for t in targets:
		for state in states:
			if state and state.has_method(function_name):
				state.call(function_name, mutation)
				## If there's a line to go to after the mutation
				if mutation.has("next_line"):
					await get_tree().process_frame
					if _dialogue_resource and dialogue_line:
						dialogue_line = await _dialogue_resource.get_next_dialogue_line(dialogue_line.id)
				return


func _on_mutation_cooldown_timeout() -> void:
	pass


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	"""Called when a response is selected from the responses menu"""
	if response and response.next_id:
		next(response.next_id)


func _mark_input_handled() -> void:
	get_tree().root.set_input_as_handled()


func _event_is_skip(event: InputEvent) -> bool:
	return event.is_action_pressed(skip_action)


func _enter_dialogue_mouse_mode() -> void:
	if not _has_dialogue_mouse_mode:
		_previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_has_dialogue_mouse_mode = true


func _restore_dialogue_mouse_mode() -> void:
	if _has_dialogue_mouse_mode:
		Input.mouse_mode = _previous_mouse_mode
		_has_dialogue_mouse_mode = false


func _set_skip_button_held(held: bool) -> void:
	_is_skip_button_held = held
	if held:
		_skip_advance_cooldown = SKIP_REPEAT_DELAY


func _handle_skip_held(delta: float) -> void:
	_skip_advance_cooldown -= delta
	if _is_skip_button_held and _skip_advance_cooldown <= 0.0:
		if dialogue_label.is_typing:
			dialogue_label.skip_typing()
		_skip_advance_cooldown = SKIP_REPEAT_DELAY


func _advance_from_skip_request() -> bool:
	if _skip_advance_after_typing:
		_is_advancing = true
		next(dialogue_line.next_id)
		_skip_advance_after_typing = false
		return true
	return false


func _build_display_dialogue_line(source_line: DialogueLine) -> DialogueLine:
	var prefix_text := ""
	for _index in range(min(_simple_line_index, SIMPLE_LINE_COUNT - 1)):
		prefix_text += "\n"

	_current_line_prefix_characters = _get_parsed_character_count(prefix_text)

	if not source_line.text.is_empty():
		_simple_line_index += 1

	var display_line := DialogueLine.new()
	display_line.id = source_line.id
	display_line.type = source_line.type
	display_line.next_id = source_line.next_id
	display_line.character = source_line.character
	display_line.character_replacements = source_line.character_replacements
	display_line.text = prefix_text + source_line.text
	display_line.text_replacements = source_line.text_replacements
	display_line.translation_key = source_line.translation_key
	display_line.speeds = _shift_text_indices(source_line.speeds, _current_line_prefix_characters)
	display_line.inline_mutations = _shift_inline_mutations(source_line.inline_mutations, _current_line_prefix_characters)
	display_line.responses = source_line.responses
	display_line.concurrent_lines = source_line.concurrent_lines
	display_line.extra_game_states = source_line.extra_game_states
	display_line.time = source_line.time
	display_line.tags = source_line.tags
	display_line.mutation = source_line.mutation
	display_line.conditions = source_line.conditions
	return display_line


func _get_parsed_character_count(text_to_measure: String) -> int:
	if text_to_measure.is_empty():
		return 0

	var original_text := dialogue_label.text
	dialogue_label.text = text_to_measure
	var character_count := dialogue_label.get_total_character_count()
	dialogue_label.text = original_text
	return character_count


func _shift_text_indices(indices: Dictionary, offset: int) -> Dictionary:
	if offset <= 0:
		return indices.duplicate(true)

	var shifted := {}
	for index in indices:
		shifted[index + offset] = indices[index]
	return shifted


func _shift_inline_mutations(mutations: Array[Array], offset: int) -> Array[Array]:
	if offset <= 0:
		return mutations.duplicate(true)

	var shifted: Array[Array] = []
	for mutation in mutations:
		if mutation.size() < 2:
			shifted.append(mutation.duplicate(true))
			continue
		var shifted_mutation := mutation.duplicate(true)
		shifted_mutation[0] = shifted_mutation[0] + offset
		shifted.append(shifted_mutation)
	return shifted
