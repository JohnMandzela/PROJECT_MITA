extends Node

const QUESTS_PATH := "res://quests/"

# Состояние квеста
enum QuestState {
	NOT_STARTED,
	ACTIVE,
	COMPLETED
}

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)

var _quests: Dictionary[String, Quest] = {}

var quest_data: Dictionary[String, Dictionary] = {}

class JournalEntry:
	var quest_id: String
	var quest: Quest
	var state: QuestState
	var completed_stages: Array[String]

	func _init(_quest_id: String, stages: Array[String]) -> void:
		self.quest_id = _quest_id
		self.quest = Quests._quests[_quest_id]
		self.state = Quests.get_quest_state(_quest_id)
		self.completed_stages = stages

	func is_completed() -> bool:
		return self.state == QuestState.COMPLETED


func _ready() -> void:
	_init_quests()
	reset()


func _init_quests() -> void:
	var dir := DirAccess.open(QUESTS_PATH)
	if not dir:
		push_error("Не удалось открыть папку по пути: " + QUESTS_PATH)
		return

	dir.list_dir_begin()

	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var quest_id := file_name.get_basename()
			var quest: Quest = ResourceLoader.load(QUESTS_PATH + file_name, "Quest")
			_quests[quest_id] = quest
		
		file_name = dir.get_next()

	dir.list_dir_end()


# Возвращает список записей журнала для квестов с указанным состоянием
func get_journal_entries(state: QuestState) -> Array[JournalEntry]:
	var result: Array[JournalEntry] = []

	for quest_id in _quests.keys():
		if get_quest_state(quest_id) != state:
			continue

		var completed_stages: Array[String] = []
		for stage_name in _quests[quest_id].stages.keys():
			if get_quest_flag(quest_id, stage_name):
				completed_stages.append(stage_name)

		var entry := JournalEntry.new(quest_id, completed_stages)
		result.append(entry)
	
	return result


# Возвращает true, если квест с данным ID существует
func quest_exists(quest_id: String) -> bool:
	return _quests.has(quest_id)


# Возвращает состояние квеста по его ID
func get_quest_state(quest_id: String) -> QuestState:
	if not quest_exists(quest_id):
		push_error("Квест '%s' не найден." % quest_id)
	
	return quest_data.get(quest_id, {}).get("state", QuestState.NOT_STARTED)


# Возвращает true, если квест начат или завершён
func is_started(quest_id: String) -> bool:
	return get_quest_state(quest_id) != QuestState.NOT_STARTED


# Возвращает true, если квест начат, но ещё не завершён
func is_active(quest_id: String) -> bool:
	return get_quest_state(quest_id) == QuestState.ACTIVE


# Возвращает true, если квест завершён
func is_completed(quest_id: String) -> bool:
	return get_quest_state(quest_id) == QuestState.COMPLETED


func _set_quest_state(quest_id: String, state: QuestState) -> void:
	if not quest_data.has(quest_id):
		_init_quest_data(quest_id, state)
	else:
		quest_data[quest_id]["state"] = state


# Начинает квест с данным ID
func start_quest(quest_id: String) -> void:
	if not quest_exists(quest_id):
		push_error("Квест '%s' не найден." % quest_id)
		return
	
	if is_started(quest_id):
		push_warning("Квест '%s' уже начат." % quest_id)
		return

	_set_quest_state(quest_id, QuestState.ACTIVE)
	quest_started.emit(quest_id)


# Завершает квест с данным ID
func complete_quest(quest_id: String) -> void:
	if not quest_exists(quest_id):
		push_error("Квест '%s' не найден." % quest_id)
		return
	
	if is_completed(quest_id):
		push_warning("Квест '%s' уже завершён." % quest_id)
		return
	
	_set_quest_state(quest_id, QuestState.COMPLETED)
	quest_completed.emit(quest_id)


# Возвращает значение квестового флага
func get_quest_flag(quest_id: String, flag_id: String) -> bool:
	if not quest_exists(quest_id):
		push_error("Квест '%s' не найден." % quest_id)
		return false

	if not quest_data.has(quest_id):
		_init_quest_data(quest_id)

	var flags = quest_data[quest_id]["flags"]
	if not flags.has(flag_id):
		push_warning("Флаг '%s' не найден в квесте '%s'." % [flag_id, quest_id])
		return false

	return flags[flag_id]


# Устанавливает значение квестового флага на параметр value (по умолчанию true)
func set_quest_flag(quest_id: String, flag_id: String, value := true) -> void:
	if not quest_exists(quest_id):
		push_error("Квест '%s' не найден." % quest_id)
		return

	if not quest_data.has(quest_id):
		_init_quest_data(quest_id)

	var flags: Dictionary[String, bool] = quest_data[quest_id]["flags"]
	if not flags.has(flag_id):
		push_error("Флаг '%s' не найден в квесте '%s'." % [flag_id, quest_id])
	elif flags[flag_id] != value:
		flags[flag_id] = value
		quest_updated.emit(quest_id)


func _init_quest_data(quest_id: String, state := QuestState.NOT_STARTED) -> void:
	var flags := {}
	for flag_id in _quests[quest_id].stages.keys():
		flags[flag_id] = false

	quest_data[quest_id] = { 
		state = state,
		flags = flags
	}


# Сбрасывает состояние игры (флаги и квесты) в дефолтное
func reset() -> void:
	quest_data.clear()

	for quest_name in _quests.keys():
		_init_quest_data(quest_name, QuestState.NOT_STARTED)
