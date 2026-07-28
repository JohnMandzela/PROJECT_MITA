extends Node

# TODO: отрефакторить систему квестов
# - Не вызывать sync_quest_progress() без необходимости

# Состояние квеста
enum QuestState {
	NOT_STARTED,
	ACTIVE,
	COMPLETED
}

# TODO удалить
# const DEFAULT_GAME_FLAGS := {
# 	"1_morning_quest": false,
# 	"2_mike_room_bed": false,
# 	"3_cola_in_fridge": false,
# 	"4_shower_use": false,
# 	"programming_office_samples_puzzle_completed": false,
# }

var quests_info: Dictionary

var quest_states: Dictionary[String, QuestState] = {}
var game_flags: Dictionary[String, bool] = {}


func _set_quest_state(quest_id: String, state: int) -> void:
	if not quests_info.has(quest_id):
		push_error("Quest ID '%s' not found in quests_info." % quest_id)
		return

	match state:
		QuestState.NOT_STARTED:
			quests_info[quest_id]["is_active"] = false
			quests_info[quest_id]["is_completed"] = false
		QuestState.ACTIVE:
			quests_info[quest_id]["is_active"] = true
			quests_info[quest_id]["is_completed"] = false
		QuestState.COMPLETED:
			quests_info[quest_id]["is_active"] = false
			quests_info[quest_id]["is_completed"] = true
		_:
			push_error("Invalid quest state: %d" % state)

	sync_quest_progress(q)

func get_quest_state(quest_id: )


# Возвращает значение флага
func get_flag(flag_name: String) -> bool:
	return game_flags.get(flag_name, false)


# Устанавливает значение флага на параметр value (по умолчанию true)
func set_flag(flag_name: String, value := true) -> void:
	game_flags[flag_name] = value
	sync_quest_progress()


func reset_game_state() -> void:
	game_flags = {}
	quests_info = {}
	sync_quest_progress()


func sync_quest_progress() -> void:
	for flag_name in DEFAULT_GAME_FLAGS.keys():
		if not game_flags.has(flag_name):
			game_flags[flag_name] = DEFAULT_GAME_FLAGS[flag_name]

	var synced_quests: Dictionary = { }
	for quest_id in DEFAULT_QUESTS_INFO.keys():
		var merged_info: Dictionary = DEFAULT_QUESTS_INFO[quest_id].duplicate(true)
		if quests_info.has(quest_id):
			merged_info.merge(quests_info[quest_id], true)

		var completion_flag := str(merged_info.get("completion_flag", ""))
		if not completion_flag.is_empty():
			if not game_flags.has(completion_flag):
				game_flags[completion_flag] = bool(DEFAULT_GAME_FLAGS.get(completion_flag, false))
			merged_info["is_completed"] = bool(game_flags.get(completion_flag, false))
		else:
			merged_info["is_completed"] = bool(merged_info.get("is_completed", false))

		synced_quests[quest_id] = merged_info

	for quest_id in quests_info.keys():
		if not synced_quests.has(quest_id):
			synced_quests[quest_id] = quests_info[quest_id]

	quests_info = synced_quests
