class_name DialogueController
extends Node

## Ведёт диалог: получает строки из DialogueResource, решает, когда ждать ввода,
## листает дальше, обрабатывает скип и мышиный режим.
##
## Отвечает только за поток. Как это выглядит, решает DialogueBalloon, а что
## доступно из .dialogue-файлов — DialogueContext.
##
## Ссылка на балун намеренно нетипизированная: DialogueBalloon хранит
## DialogueController, и типизация в обе стороны дала бы циклическую зависимость.

const SKIP_REPEAT_DELAY := 0.12
## Задержка, после которой балун прячется, если мутация длинная
const MUTATION_HIDE_DELAY := 0.1
## Сколько секунд на символ при переходе по времени "auto"
const AUTO_ADVANCE_SECONDS_PER_CHAR := 0.02

## Тайтл, наличие которого делает диалог пропускаемой катсценой
const CUTSCENE_SKIP_TITLE := "skip"
## Предохранитель от бесконечного прохода по циклам
const MAX_SKIP_STEPS := 500

## Балун, которым управляет контроллер (DialogueBalloon)
var balloon

## Контекст диалога — первый элемент temporary_game_states
var context: DialogueContext

var dialogue_resource: DialogueResource
var start_from_title := ""

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

var _locale: String = TranslationServer.get_locale()
var _skip_advance_cooldown := 0.0
var _is_advancing := false
var _is_skip_button_held := false
var _skip_advance_after_typing := false
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _has_dialogue_mouse_mode := false

## Идёт быстрый проход по катсцене (мутации без ожидания)
var _is_skipping_cutscene := false
## Катсцену уже пропустили — второй раз не предлагаем
var _cutscene_skipped := false
## Во время прохода встретили тайтл skip
var _passed_skip_title := false

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			_apply_dialogue_line()
		else:
			_restore_dialogue_mouse_mode()
			if balloon.owner == null:
				GameManager.disable_movement = false
				balloon.queue_free()
			else:
				balloon.hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()


func setup(balloon_ref, context_ref: DialogueContext) -> void:
	balloon = balloon_ref
	context = context_ref


func _ready() -> void:
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	Engine.get_singleton("DialogueManager").passed_title.connect(_on_passed_title)

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)


func _process(delta: float) -> void:
	if not is_instance_valid(dialogue_line):
		return

	_enter_dialogue_mouse_mode()
	if balloon.is_skip_disabled():
		_is_skip_button_held = false
	_handle_skip_held(delta)


func _input(event: InputEvent) -> void:
	if not _is_skip_button_held:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		set_skip_held(false)
	elif event is InputEventScreenTouch and not event.pressed:
		set_skip_held(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.CANCEL) and can_skip_cutscene():
		skip_cutscene()
		mark_input_handled()
		return

	if is_instance_valid(dialogue_line):
		if balloon.is_typing() and (event.is_action_pressed(balloon.next_action) or _event_is_skip(event)):
			balloon.skip_typing()
			mark_input_handled()
			return

		if is_waiting_for_input and dialogue_line.responses.is_empty() and event.is_action_pressed(balloon.next_action):
			next(dialogue_line.next_id)
			mark_input_handled()
			return

	mark_input_handled()


func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED:
		return
	if _locale == TranslationServer.get_locale():
		return
	if not is_instance_valid(dialogue_line):
		return

	_locale = TranslationServer.get_locale()
	var visible_ratio: float = balloon.typed_ratio()
	dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
	if visible_ratio < 1:
		balloon.skip_typing()


func _exit_tree() -> void:
	_restore_dialogue_mouse_mode()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [context, balloon] + extra_game_states
	is_waiting_for_input = false
	_cutscene_skipped = false
	_passed_skip_title = false
	GameManager.disable_movement = true
	_enter_dialogue_mouse_mode()

	dialogue_resource = with_dialogue_resource if is_instance_valid(with_dialogue_resource) else balloon.dialogue_resource
	start_from_title = title if not title.is_empty() else balloon.start_from_title

	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)


## Go to the next line
func next(next_id: String) -> void:
	if _is_advancing:
		return
	_is_advancing = true
	var next_dialogue_line: DialogueLine = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)
	_is_advancing = false
	dialogue_line = next_dialogue_line


## Обрабатывает событие gui_input балуна (клик по тексту, Enter и т.п.)
func handle_gui_input(event: InputEvent) -> void:
	if not is_instance_valid(dialogue_line):
		return

	if balloon.is_typing():
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = _event_is_skip(event)
		if mouse_was_clicked or skip_button_was_pressed:
			mark_input_handled()
			balloon.skip_typing()
			return

	if not is_waiting_for_input:
		return
	if dialogue_line.responses.size() > 0:
		return

	mark_input_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(balloon.next_action) and balloon.has_focus():
		next(dialogue_line.next_id)


## Выбор ответа в меню балуна
func handle_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


## Катсцену можно пропустить: в диалоге есть тайтл skip, сейчас не выбор,
## катсцена ещё не пропущена и балун не в простом режиме.
func can_skip_cutscene() -> bool:
	if _cutscene_skipped or _is_skipping_cutscene:
		return false
	if not is_instance_valid(dialogue_line) or not is_instance_valid(dialogue_resource):
		return false
	if not dialogue_line.responses.is_empty():
		return false
	if balloon.is_simple_mode():
		return false
	return dialogue_resource.titles.has(CUTSCENE_SKIP_TITLE)


## Пропуск катсцены: быстро проходим строки, выполняя мутации без ожидания,
## и останавливаемся на первой реплике с ответами или на тайтле skip.
func skip_cutscene() -> void:
	if not can_skip_cutscene():
		return

	var skip_id: String = dialogue_resource.titles.get(CUTSCENE_SKIP_TITLE, "")
	var target: DialogueLine = null
	var reached_skip := false
	# Тайтл встретился, но DM обрабатывает его внутри того же вызова
	var stopped_before_skip := false

	_is_skipping_cutscene = true
	_passed_skip_title = false
	GameManager.is_skipping_cutscene = true
	is_waiting_for_input = false
	_skip_advance_after_typing = false
	_is_skip_button_held = false
	balloon.skip_typing()
	balloon.dismiss_skip_prompt()

	var next_id: String = dialogue_line.next_id
	for _step in MAX_SKIP_STEPS:
		if _is_end_id(next_id) or _is_skip_id(next_id, skip_id) or _is_goto_to_skip(next_id, skip_id):
			break

		var line: DialogueLine = await _get_line_without_waiting(next_id)

		if _passed_skip_title:
			reached_skip = true
			stopped_before_skip = is_instance_valid(line) and _is_skip_id(line.next_id, skip_id)
			if is_instance_valid(line) and not stopped_before_skip:
				target = line
			break

		if not is_instance_valid(line):
			break

		if not line.responses.is_empty():
			target = line
			break

		next_id = line.next_id

	_is_skipping_cutscene = false
	GameManager.is_skipping_cutscene = false

	if is_instance_valid(target):
		_cutscene_skipped = reached_skip
		dialogue_line = target
		return

	if reached_skip and not stopped_before_skip:
		_cutscene_skipped = true
		_finish_dialogue()
		return

	# До skip не дошли (ветка закончилась или сработал предохранитель) —
	# переходим на тайтл напрямую, чтобы его блок отработал как обычно.
	_cutscene_skipped = true
	await next(CUTSCENE_SKIP_TITLE)


## Проход строк для пропуска. Используем внутренний метод DialogueManager:
## публичный эмитит dialogue_ended при достижении конца, а проход может
## закончиться уже внутри блока skip.
func _get_line_without_waiting(next_id: String) -> DialogueLine:
	return await Engine.get_singleton("DialogueManager")._get_next_dialogue_line(
		dialogue_resource,
		next_id,
		temporary_game_states,
		DMConstants.MutationBehaviour.DoNotWait,
	)


func _finish_dialogue() -> void:
	dialogue_line = null
	Engine.get_singleton("DialogueManager").dialogue_ended.emit(dialogue_resource)


func _is_end_id(id: String) -> bool:
	return _base_id(id) in [DMConstants.ID_END, DMConstants.ID_END_CONVERSATION, DMConstants.ID_NULL]


func _is_skip_id(id: String, skip_id: String) -> bool:
	return not skip_id.is_empty() and _base_id(id) == _base_id(skip_id)


## Строка — это переход => skip? Тогда останавливаемся до него, чтобы блок skip
## отработал обычным образом (с ожиданием фейдов и пауз).
func _is_goto_to_skip(id: String, skip_id: String) -> bool:
	var data: Dictionary = dialogue_resource.lines.get(_base_id(id), {})
	if data.is_empty() or data.get("type", "") != DMConstants.TYPE_GOTO:
		return false

	var target: String = data.get("next_id", "")
	var target_id: String = dialogue_resource.titles.get(target, target)
	return _is_skip_id(target_id, skip_id)


## id строки может быть "12", "12|трейл" или "uid@12"
func _base_id(id: String) -> String:
	var base := id.split("|")[0]
	if "@" in base:
		base = base.split("@")[1]
	return base


## Кнопку «Пропустить» зажали/отпустили (кнопка гасится в самом балуне)
func set_skip_held(held: bool) -> void:
	if held == _is_skip_button_held:
		return

	_is_skip_button_held = held
	if not held:
		return

	_enter_dialogue_mouse_mode()
	_skip_advance_cooldown = SKIP_REPEAT_DELAY
	_skip_current_line()


func mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	_enter_dialogue_mouse_mode()

	is_waiting_for_input = false
	will_hide_balloon = false
	balloon.focus_balloon()

	await balloon.present_line(dialogue_line)

	if dialogue_line.responses:
		_skip_advance_after_typing = false
		_is_skip_button_held = false
		return

	if dialogue_line.time != "":
		_skip_advance_after_typing = false
		var line_time: float = dialogue_line.text.length() * AUTO_ADVANCE_SECONDS_PER_CHAR if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(line_time).timeout
		next(dialogue_line.next_id)
		return

	is_waiting_for_input = true
	balloon.focus_balloon()
	if _skip_advance_after_typing and _advance_from_skip_request():
		return


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

	if balloon.is_typing():
		_skip_advance_after_typing = true
		balloon.skip_typing()
		return true

	if dialogue_line.responses.size() > 0:
		return false

	if is_waiting_for_input:
		return _advance_from_skip_request()

	return false


func _advance_from_skip_request() -> bool:
	if not is_waiting_for_input:
		return false
	if balloon.is_typing():
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
	if InputMap.has_action(balloon.skip_action) and Input.is_action_pressed(balloon.skip_action):
		return true
	return Input.is_physical_key_pressed(KEY_TAB)


func _event_is_skip(event: InputEvent) -> bool:
	if InputMap.has_action(balloon.skip_action) and event.is_action_pressed(balloon.skip_action):
		return true
	return event is InputEventKey and event.physical_keycode == KEY_TAB and event.pressed


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide_balloon()


func _on_mutated(mutation: Dictionary) -> void:
	if _is_skipping_cutscene:
		return

	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(MUTATION_HIDE_DELAY)


func _on_passed_title(title: String) -> void:
	if not _is_skipping_cutscene or title != CUTSCENE_SKIP_TITLE:
		return

	_passed_skip_title = true
	# Внутри блока skip мутации должны отработать как обычно (фейды, паузы)
	GameManager.is_skipping_cutscene = false


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
