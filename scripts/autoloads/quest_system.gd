extends Node

# TODO: отрефакторить систему квестов
# - Вынести квесты в отдельный ресурс
# - Не вызывать sync_quest_progress() без необходимости

const DEFAULT_QUESTS_INFO := {
	"find_cola": {
		"title": "Найти колу",
		"description": "Нужно найти бутылку колы и положить ее в холодильник.",
		"is_active": true,
		"completion_flag": "3_cola_in_fridge",
	},
	"morning_routine": {
		"title": "Утренние дела",
		"description": "Нужно принять душ и привести себя в порядок.",
		"is_active": true,
		"completion_flag": "4_shower_use",
	},
	"debug_code": {
		"title": "Отладить код",
		"description": "Пройдите мини-игру \"Отладка кода\" в Programming Office.",
		"is_active": true,
		"completion_flag": "programming_office_samples_puzzle_completed",
	},
	"check_laptop": {
		"title": "Проверить ноутбук",
		"description": "Посмотреть сообщения и заметки на ноутбуке.",
		"is_active": false,
	},
}

const DEFAULT_GAME_FLAGS := {
	"1_morning_quest": false,
	"2_mike_room_bed": false,
	"3_cola_in_fridge": false,
	"4_shower_use": false,
	"programming_office_samples_puzzle_completed": false,
}

var quests_info: Dictionary = DEFAULT_QUESTS_INFO.duplicate(true)
var game_flags: Dictionary = DEFAULT_GAME_FLAGS.duplicate(true)


func _ready() -> void:
	sync_quest_progress()


func is_done(flag_name: String) -> bool:
	return bool(game_flags.get(flag_name, false))


func set_done(flag_name: String) -> void:
	game_flags[flag_name] = true
	sync_quest_progress()


func reload(flag_name: String) -> void:
	game_flags[flag_name] = false
	sync_quest_progress()


func reset_game_state() -> void:
	game_flags = DEFAULT_GAME_FLAGS.duplicate(true)
	quests_info = DEFAULT_QUESTS_INFO.duplicate(true)
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
