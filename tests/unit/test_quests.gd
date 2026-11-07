extends GutTest

# Проверки квестов и их сохранения


func before_each() -> void:
	Quests.reset()


func after_all() -> void:
	Quests.reset()


func test_quest_is_not_started_by_default() -> void:
	assert_false(Quests.is_started("find_cola"))
	assert_false(Quests.is_active("find_cola"))
	assert_false(Quests.is_completed("find_cola"))


func test_start_quest() -> void:
	Quests.start_quest("find_cola")

	assert_true(Quests.is_started("find_cola"))
	assert_true(Quests.is_active("find_cola"))


func test_complete_quest() -> void:
	Quests.start_quest("find_cola")
	Quests.complete_quest("find_cola")

	assert_true(Quests.is_completed("find_cola"))
	assert_false(Quests.is_active("find_cola"))


func test_reset_clears_progress() -> void:
	Quests.start_quest("find_cola")
	Quests.reset()

	assert_false(Quests.is_started("find_cola"))


func test_quest_data_survives_store_var_roundtrip() -> void:
	Quests.start_quest("find_cola")

	var path := "user://test_quests_roundtrip.bin"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var({ "quest_data": Quests.quest_data })
	file.close()

	Quests.reset()
	assert_false(Quests.is_started("find_cola"))

	file = FileAccess.open(path, FileAccess.READ)
	var loaded: Dictionary = file.get_var()
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	Quests.set("quest_data", loaded["quest_data"])

	assert_true(Quests.is_active("find_cola"))
