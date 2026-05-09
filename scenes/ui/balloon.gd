extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.

enum PortraitSide {
	LEFT,
	RIGHT,
}

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

var _locale: String = TranslationServer.get_locale()
var _skip_advance_cooldown := 0.0
var _is_advancing := false
var _is_skip_button_held := false
var _skip_advance_after_typing := false
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _has_dialogue_mouse_mode := false

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
<<<<<<< Updated upstream
			# The dialogue has finished so close the balloon
=======
			_restore_dialogue_mouse_mode()
>>>>>>> Stashed changes
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

	# If the responses menu doesn't have a next action set, use this one
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
<<<<<<< Updated upstream
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")
=======
		_enter_dialogue_mouse_mode()
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.is_empty() and not dialogue_line.has_tag("voice")
		skip_button.disabled = not dialogue_line.responses.is_empty()
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
>>>>>>> Stashed changes


func _unhandled_input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
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

	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()

<<<<<<< Updated upstream
=======

func get_portrait_side(character: String) -> PortraitSide:
	if left_portrait._character == character:
		return PortraitSide.LEFT
	if right_portrait._character == character:
		return PortraitSide.RIGHT

	var side := dialogue_line.get_tag_value("side")
	if side == "left":
		return PortraitSide.LEFT
	if side == "right":
		return PortraitSide.RIGHT
	if not side.is_empty():
		push_warning("Invalid portrait side '%s' for character '%s' in line '%s'" % [side, character, dialogue_line.id])

	if left_portrait._character.is_empty():
		return PortraitSide.LEFT
	if right_portrait._character.is_empty():
		return PortraitSide.RIGHT

	push_warning("Both portrait slots are occupied; using left slot for '%s'" % character)
	return PortraitSide.LEFT


>>>>>>> Stashed changes
## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	_enter_dialogue_mouse_mode()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	var character := dialogue_line.character
	character_label.visible = not character.is_empty()
	character_label.text = tr(character, "dialogue")
	
	# временный хардкод
	# TODO: сделать нормально
	if character == 'Майк':
		left_portrait.set_active()
		right_portrait.set_inactive()
	elif not character.is_empty():
		left_portrait.set_inactive()
		right_portrait.set_active()

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses
	skip_button.disabled = not dialogue_line.responses.is_empty()

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		if _is_skip_held():
			dialogue_label.skip_typing()
		if dialogue_label.is_typing:
			await dialogue_label.finished_typing

	# TODO: а будет ли озвучка? если нет, можно это убрать
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
		return
	
	# Отображаем варианты ответа
	if dialogue_line.responses:
		_skip_advance_after_typing = false
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		return
	
	if dialogue_line.time != "":
<<<<<<< Updated upstream
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
=======
		_skip_advance_after_typing = false
		var line_time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(line_time).timeout
>>>>>>> Stashed changes
		next(dialogue_line.next_id)
		return
	
	# Иначе захватываем фокус и ждём ввода игрока
	is_waiting_for_input = true
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()
	if (_is_skip_held() or _skip_advance_after_typing) and _advance_from_skip_hold():
		return


## Go to the next line
func next(next_id: String) -> void:
	if _is_advancing:
		return
	_is_advancing = true
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)
	_is_advancing = false


<<<<<<< Updated upstream
#region Signals
=======
func fade_out(seconds: Variant = null) -> void:
	GameManager.screen_fader.fade_out(seconds)

	if seconds == null:
		await GameManager.screen_fader.fade_out_finished
	else:
		await GameManager.screen_fader.fade_in_finished


func fade_in() -> void:
	GameManager.screen_fader.fade_in()
	await GameManager.screen_fader.fade_in_finished


func hide_portrait(character: String) -> void:
	if left_portrait._character == character:
		await left_portrait.hide_character()
		return

	if right_portrait._character == character:
		await right_portrait.hide_character()
		return

	push_warning("Tried to hide portrait for '%s', but it is not visible" % character)


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

	var emotion := ""
	for emotion_name in DialogueGlobals.EMOTES:
		if emotion_name in dialogue_line.tags:
			emotion = emotion_name
			break

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
>>>>>>> Stashed changes


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	if not _mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = _event_is_skip(event)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


<<<<<<< Updated upstream
#endregion
=======
func _handle_skip_held(delta: float) -> void:
	if not _is_skip_held():
		_skip_advance_cooldown = 0.0
		return

	if dialogue_label.is_typing:
		dialogue_label.skip_typing()
		_skip_advance_cooldown = 0.08
		return

	_skip_advance_cooldown -= delta
	if _skip_advance_cooldown <= 0.0:
		_skip_advance_cooldown = 0.08
		_advance_from_skip_hold()


func _advance_from_skip_hold() -> bool:
	if not is_waiting_for_input:
		return false
	if dialogue_label.is_typing:
		return false
	if not is_instance_valid(dialogue_line):
		return false
	if dialogue_line.responses.size() > 0:
		return false

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
		_set_skip_button_held(event.pressed)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		_set_skip_button_held(event.pressed)
		get_viewport().set_input_as_handled()


func _set_skip_button_held(held: bool) -> void:
	if held and skip_button.disabled:
		return

	_is_skip_button_held = held
	if not held:
		return

	_enter_dialogue_mouse_mode()
	_skip_advance_cooldown = 0.0
	_skip_advance_after_typing = true
	if is_instance_valid(dialogue_line) and dialogue_label.is_typing:
		dialogue_label.skip_typing()
	elif is_instance_valid(dialogue_line):
		_advance_from_skip_hold()


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
>>>>>>> Stashed changes
