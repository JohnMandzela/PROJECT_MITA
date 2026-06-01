extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.

enum PortraitSide {
	LEFT,
	RIGHT
}

## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

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

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
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


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")


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


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [ self ] + extra_game_states
	is_waiting_for_input = false
	GameManager.disable_movement = true

	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()

func get_portrait_side() -> PortraitSide:
	var character := dialogue_line.character
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
		print("explicitly left")
		return PortraitSide.LEFT
	elif side == "right": 
		print("explicitly right")
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

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	var character := dialogue_line.character
	character_label.visible = not character.is_empty()
	character_label.text = tr(character, "dialogue")
	
	if character:
		var emotion := &""
		for emotion_name in DialogueGlobals.EMOTES:
			if emotion_name in dialogue_line.tags:
				emotion = emotion_name
				break

		var current_portrait: CharacterPortrait
		var other_portrait: CharacterPortrait
		
		if get_portrait_side() == PortraitSide.LEFT:
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

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
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
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		return
	
	if dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
		return
	
	# Иначе захватываем фокус и ждём ввода игрока
	is_waiting_for_input = true
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)

#region Dialogue Functions

# Затухание
func fade_out(seconds = null) -> void:
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
		left_portrait.hide_character()
	elif right_portrait._character == character:
		right_portrait.hide_character()
	else:
		push_warning("Функция hide_portrait() вызвана с персонажем '%s', который не участвует в диалоге" % [character])


#region Signals

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
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
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


#endregion
