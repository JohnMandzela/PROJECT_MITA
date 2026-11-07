extends GutTest

# Проверки путей сохранений и чтения сводки (без записи в настоящие слоты)

const TEMP_SAVE_PATH := "user://test_save_summary.bin"


func after_each() -> void:
	if FileAccess.file_exists(TEMP_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SAVE_PATH))


func test_save_paths_per_mode() -> void:
	assert_eq(SaveSystem.get_save_file_path(SaveSystem.Mode.AUTO), "user://autosave.bin")
	assert_eq(SaveSystem.get_save_file_path(SaveSystem.Mode.QUICK), "user://quicksave.bin")
	assert_eq(SaveSystem.get_save_file_path(SaveSystem.Mode.MANUAL, 1), "user://save_1.bin")


func test_manual_slot_is_clamped() -> void:
	assert_eq(
		SaveSystem.get_save_file_path(SaveSystem.Mode.MANUAL, 99),
		"user://save_2.bin"
	)


func test_summary_of_missing_file() -> void:
	var info := SaveSystem.get_save_summary(TEMP_SAVE_PATH)

	assert_false(info["is_valid"])
	assert_eq(info["scene_file_path"], "")


func test_summary_reads_scene_path() -> void:
	var file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	file.store_var({
		"save_version": SaveSystem.SAVE_VERSION,
		"scene_file_path": "res://scenes/dorm/mike_room.tscn",
	})
	file.close()

	var info := SaveSystem.get_save_summary(TEMP_SAVE_PATH)

	assert_true(info["is_valid"])
	assert_eq(info["scene_file_path"], "res://scenes/dorm/mike_room.tscn")
	assert_eq(info["scene_name"], "Mike Room")


func test_summary_of_broken_file() -> void:
	var file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	file.store_var("not a dictionary")
	file.close()

	var info := SaveSystem.get_save_summary(TEMP_SAVE_PATH)

	assert_false(info["is_valid"])
