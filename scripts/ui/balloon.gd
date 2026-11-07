class_name DialogueBalloon
extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.
##
## Здесь только UI: вёрстка, портреты, простой режим и методы, которые зовут
## из .dialogue-файлов. Поток диалога — в DialogueController, переменные и
## утилитарные вызовы — в DialogueContext.

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

## Строка, которая сейчас на экране (нужна портретам, индикатору и тегам)
var current_line: DialogueLine

## Контекст диалога и контроллер потока создаются в _ready()
var context: DialogueContext
var controller: DialogueController

## Режим простого текста: без портретов, панели и имени персонажа (для катсцен).
var _is_simple_mode := false

## The base balloon anchor
@onready var balloon: Control = %Balloon

## Панель с фоном, именем персонажа и обычным текстом
@onready var dialogue_panel: PanelContainer = %DialoguePanel

## Контейнер для простого режима: тот же [DialogueLabel], но по центру экрана
@onready var simple_area: MarginContainer = %SimpleArea

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
	simple_area.hide()

	context = DialogueContext.new()
	context.name = "DialogueContext"
	add_child(context)

	controller = DialogueController.new()
	controller.name = "DialogueController"
	controller.setup(self, context)
	add_child(controller)

	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.gui_input.connect(_on_skip_button_gui_input)
	skip_button.button_down.connect(_on_skip_button_button_down)
	skip_button.button_up.connect(_on_skip_button_button_up)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


func _process(_delta: float) -> void:
	if not is_instance_valid(current_line):
		return

	progress.visible = (
		not _is_simple_mode
		and not dialogue_label.is_typing
		and current_line.responses.is_empty()
	)
	skip_button.disabled = is_skip_disabled()


## Start some dialogue. Вызывается DialogueManager и сценами (auto_start).
## Логика потока — в контроллере, здесь только фасад.
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	await controller.start(with_dialogue_resource, title, extra_game_states)


## Показывает новую строку: имя, портреты, ответы и печать текста
func present_line(line: DialogueLine) -> void:
	current_line = line
	progress.hide()

	if not _is_simple_mode:
		_apply_character_and_portraits()

	dialogue_label.hide()
	dialogue_label.dialogue_line = line
	responses_menu.hide()
	responses_menu.responses = line.responses

	balloon.show()
	dialogue_label.show()

	if not line.text.is_empty():
		dialogue_label.type_out()
		if dialogue_label.is_typing:
			await dialogue_label.finished_typing

	if line.responses:
		clear_balloon_focus()
		responses_menu.show()

	skip_button.disabled = is_skip_disabled()


func focus_balloon() -> void:
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()


func clear_balloon_focus() -> void:
	balloon.focus_mode = Control.FOCUS_NONE


func has_focus() -> bool:
	var viewport := get_viewport()
	return viewport != null and viewport.gui_get_focus_owner() == balloon


func is_typing() -> bool:
	return dialogue_label.is_typing


func skip_typing() -> void:
	dialogue_label.skip_typing()


func typed_ratio() -> float:
	return dialogue_label.visible_ratio


func hide_balloon() -> void:
	balloon.hide()


## Кнопка «Пропустить» недоступна, пока игрок выбирает ответ
func is_skip_disabled() -> bool:
	return is_instance_valid(current_line) and not current_line.responses.is_empty() and not dialogue_label.is_typing


## Переключает балун в простой режим по имени. Используется в диалогах: do switch_balloon("simple")
func switch_balloon(balloon_name: String) -> void:
	if balloon_name != "simple":
		push_warning("Неизвестный режим балуна: '%s'" % balloon_name)
		return

	switch_to_simple_mode()


## Простой режим: тот же текст, но по центру экрана — без портретов, панели и имени персонажа.
func switch_to_simple_mode() -> void:
	if _is_simple_mode:
		return

	_is_simple_mode = true

	left_portrait.hide()
	right_portrait.hide()
	character_label.hide()
	progress.hide()
	responses_menu.hide()
	dialogue_panel.hide()
	simple_area.show()

	_move_dialogue_label(simple_area)

	dialogue_label.add_theme_color_override("default_color", Color.BLACK)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dialogue_label.fit_content = false
	dialogue_label.scroll_active = false
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func get_portrait_side(character: String) -> PortraitSide:
	assert(character, "get_portrait_side() вызвана для строки диалога без персонажа")

	var current_side = null
	if left_portrait.character == character:
		current_side = PortraitSide.LEFT
	elif right_portrait.character == character:
		current_side = PortraitSide.RIGHT

	var side := current_line.get_tag_value("side")
	if current_side != null and side:
		push_warning("Персонаж '%s' уже отображается с стороны '%s', но в строке диалога '%s' присутствует тег со стороной '%s'" % [character, current_side, current_line.id, side])

	if current_side != null:
		return current_side

	if side == "left":
		return PortraitSide.LEFT
	elif side == "right":
		return PortraitSide.RIGHT
	elif side:
		push_warning("Некорректная сторона '%s' для персонажа '%s' в строке диалога '%s'" % [side, character, current_line.id])

	if not left_portrait.character:
		return PortraitSide.LEFT
	elif not right_portrait.character:
		return PortraitSide.RIGHT

	push_warning("Оба портрета уже заняты, но в строке диалога '%s' нет тега со стороной для персонажа '%s'" % [current_line.id, character])
	return PortraitSide.LEFT


## Скрыть портрет персонажа по имени
func hide_portrait(character: String) -> void:
	if left_portrait.character == character:
		await left_portrait.hide_character()
	elif right_portrait.character == character:
		await right_portrait.hide_character()
	else:
		push_warning("Функция hide_portrait() вызвана с персонажем '%s', который не участвует в диалоге" % [character])


func _apply_character_and_portraits() -> void:
	var character := current_line.character
	character_label.visible = not character.is_empty()
	character_label.text = tr(character, "dialogue")

	if character.is_empty():
		# Реплика рассказчика: активный портрет гасим, но не убираем
		left_portrait.set_inactive()
		right_portrait.set_inactive()
		return

	var emotion := _get_line_emotion()
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


# Эмоция строки: [#happy], [#sad], [#angry], [#shame].
# Отсутствие тега означает «без эмоции» — базовый портрет.
func _get_line_emotion() -> String:
	for emotion_name in Enums.Emote.keys():
		var tag_name := str(emotion_name).to_lower()
		if current_line.has_tag(tag_name):
			return tag_name

	return ""


func _move_dialogue_label(target: Control) -> void:
	var current_parent := dialogue_label.get_parent()
	if current_parent == target:
		return

	if current_parent:
		current_parent.remove_child(dialogue_label)
	target.add_child(dialogue_label)

	dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_label.offset_left = 0.0
	dialogue_label.offset_top = 0.0
	dialogue_label.offset_right = 0.0
	dialogue_label.offset_bottom = 0.0


func _on_balloon_gui_input(event: InputEvent) -> void:
	controller.handle_gui_input(event)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	controller.handle_response_selected(response)


func _on_skip_button_button_down() -> void:
	if skip_button.disabled:
		return
	controller.set_skip_held(true)


func _on_skip_button_button_up() -> void:
	controller.set_skip_held(false)


func _on_skip_button_gui_input(event: InputEvent) -> void:
	if skip_button.disabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		controller.mark_input_handled()
		controller.set_skip_held(event.pressed)
	elif event is InputEventScreenTouch:
		controller.mark_input_handled()
		controller.set_skip_held(event.pressed)
