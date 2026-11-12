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

## Группа активных балунов: по ней пауза понимает, что открывать меню нельзя
const GROUP := &"dialogue_balloons"

## Сколько держится подсказка о пропуске и сколько длится её появление/исчезновение
const SKIP_PROMPT_VISIBLE_TIME := 3.0
const SKIP_PROMPT_FADE_TIME := 0.25

## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## The action to use for advancing the dialogue
@export var next_action: StringName = InputActions.NEXT

## The action to use while fast-forwarding dialogue.
@export var skip_action: StringName = InputActions.SKIP

## Строка, которая сейчас на экране (нужна портретам, индикатору и тегам)
var current_line: DialogueLine

## Контекст диалога и контроллер потока создаются в _ready()
var context: DialogueContext
var controller: DialogueController

## Режим простого текста: без портретов, панели и имени персонажа (для катсцен).
var _is_simple_mode := false
## id последней показанной строки — чтобы не дублировать её при переприменении
var _presented_line_id := ""
## Подсказку о пропуске показываем один раз за катсцену
var _skip_prompt_shown := false
var _skip_prompt_tween: Tween

## The base balloon anchor
@onready var balloon: Control = %Balloon

## Панель с фоном, именем персонажа и обычным текстом
@onready var dialogue_panel: PanelContainer = %DialoguePanel

## Контейнер для простого режима: лог из 4 строк по центру экрана
@onready var simple_area: MarginContainer = %SimpleArea

## Лог простого режима
@onready var simple_log: SimpleLog = %SimpleLog

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

## Подсказка «Пропустить катсцену» в правом верхнем углу
@onready var skip_prompt: PanelContainer = %SkipPrompt


func _ready() -> void:
	balloon.hide()
	simple_area.hide()
	skip_prompt.hide()
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

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
		and not is_typing()
		and current_line.responses.is_empty()
	)
	skip_button.disabled = is_skip_disabled()


## Start some dialogue. Вызывается DialogueManager и сценами (auto_start).
## Логика потока — в контроллере, здесь только фасад.
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	_presented_line_id = ""
	_skip_prompt_shown = false
	hide_skip_prompt()
	add_to_group(GROUP)
	await controller.start(with_dialogue_resource, title, extra_game_states)


## Показывает новую строку: имя, портреты, ответы и печать текста
func present_line(line: DialogueLine) -> void:
	current_line = line
	progress.hide()

	if not _is_simple_mode:
		_apply_character_and_portraits()

	dialogue_label.hide()
	responses_menu.hide()
	responses_menu.responses = line.responses

	balloon.show()
	_refresh_skip_prompt()

	if _is_simple_mode:
		if line.id == _presented_line_id:
			simple_log.replace_active_line(line)
		else:
			await simple_log.show_line(line)
	else:
		dialogue_label.dialogue_line = line
		dialogue_label.show()

		if not line.text.is_empty():
			dialogue_label.type_out()
			if dialogue_label.is_typing:
				await dialogue_label.finished_typing

	_presented_line_id = line.id

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
	return simple_log.is_typing() if _is_simple_mode else dialogue_label.is_typing


func skip_typing() -> void:
	if _is_simple_mode:
		simple_log.skip_typing()
	else:
		dialogue_label.skip_typing()


func typed_ratio() -> float:
	return simple_log.typed_ratio() if _is_simple_mode else dialogue_label.visible_ratio


func hide_balloon() -> void:
	balloon.hide()


## Кнопка «Пропустить» недоступна, пока игрок выбирает ответ
func is_skip_disabled() -> bool:
	return is_instance_valid(current_line) and not current_line.responses.is_empty() and not is_typing()


## Переключает балун в простой режим по имени. Используется в диалогах: do switch_balloon("simple")
func switch_balloon(balloon_name: String) -> void:
	if balloon_name != "simple":
		push_warning("Неизвестный режим балуна: '%s'" % balloon_name)
		return

	switch_to_simple_mode()


## Простой режим: лог из 4 строк по центру экрана — без портретов, панели и имени персонажа.
func switch_to_simple_mode() -> void:
	if _is_simple_mode:
		return

	_is_simple_mode = true
	_presented_line_id = ""

	left_portrait.hide()
	right_portrait.hide()
	character_label.hide()
	progress.hide()
	responses_menu.hide()
	dialogue_panel.hide()
	dialogue_label.hide()
	simple_area.show()
	simple_log.reset()
	hide_skip_prompt()


## Простой режим включён? В нём катсцену не пропускают — это уже эпилог.
func is_simple_mode() -> bool:
	return _is_simple_mode


## Прячет подсказку о пропуске (анимацию и таймер тоже)
func hide_skip_prompt() -> void:
	_stop_skip_prompt_tween()
	skip_prompt.modulate.a = 0.0
	skip_prompt.hide()


## Прячет подсказку и больше её не показывает — например, после пропуска
func dismiss_skip_prompt() -> void:
	_skip_prompt_shown = true
	hide_skip_prompt()


## Подсказка видна только там, где катсцену реально можно пропустить
func _refresh_skip_prompt() -> void:
	if _is_simple_mode or not controller.can_skip_cutscene():
		hide_skip_prompt()
		return

	if _skip_prompt_shown:
		return

	_show_skip_prompt()


func _show_skip_prompt() -> void:
	_skip_prompt_shown = true
	skip_prompt.modulate.a = 0.0
	skip_prompt.show()

	_skip_prompt_tween = create_tween()
	_skip_prompt_tween.tween_property(skip_prompt, "modulate:a", 1.0, SKIP_PROMPT_FADE_TIME)
	_skip_prompt_tween.tween_interval(SKIP_PROMPT_VISIBLE_TIME)
	_skip_prompt_tween.tween_property(skip_prompt, "modulate:a", 0.0, SKIP_PROMPT_FADE_TIME)
	_skip_prompt_tween.tween_callback(skip_prompt.hide)


func _stop_skip_prompt_tween() -> void:
	if _skip_prompt_tween and _skip_prompt_tween.is_valid():
		_skip_prompt_tween.kill()


func _on_dialogue_ended(resource: DialogueResource) -> void:
	if controller == null or controller.dialogue_resource != resource:
		return

	remove_from_group(GROUP)
	hide_skip_prompt()


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
	var portrait := _find_portrait(character)
	if portrait == null:
		# Портрет уже скрыт после предыдущего вызова — это нормально.
		# Предупреждаем только о неизвестном имени.
		if not DialogueGlobals.PORTRAIT_PREFIXES.has(character):
			push_warning("Функция hide_portrait() вызвана с персонажем '%s', который не участвует в диалоге" % [character])
		return

	if GameManager.is_skipping_cutscene:
		portrait.hide_character_instant()
		return

	await portrait.hide_character()


func _find_portrait(character: String) -> CharacterPortrait:
	if left_portrait.character == character:
		return left_portrait
	if right_portrait.character == character:
		return right_portrait
	return null


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
