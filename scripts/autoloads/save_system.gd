extends Node


enum Mode {
	AUTO,
	QUICK,
	MANUAL,
}

const SLOT_COUNT := 3
const LEGACY_SAVE_PATH := "user://save.bin"

const GAME_MANAGER_PROPERTIES_TO_SAVE: PackedStringArray = [
	"game_flags",
	"quests_info",
]

const ITEMS_PROPERTIES_TO_SAVE: PackedStringArray = [
	"items_inventory",
	"inventory_order",
]

const PLAYER_PROPERTIES_TO_SAVE: PackedStringArray = [
	"global_position",
	"last_direction",
	"is_flashlight_on",
]

var is_loading := false
var _save_data = null


func get_save_file_path(mode: Mode = Mode.QUICK, slot := 0) -> String:
	match mode:
		Mode.AUTO:
			return "user://autosave.bin"
		Mode.QUICK:
			return "user://quicksave.bin"
		Mode.MANUAL:
			var safe_slot := clampi(slot, 0, SLOT_COUNT - 1)
			return "user://save_%d.bin" % safe_slot

	push_warning("Unsupported save mode: %s" % mode)
	return ""


func _get_save_file_path(mode: Mode = Mode.QUICK, slot := 0) -> String:
	return get_save_file_path(mode, slot)


func get_all_save_files() -> Array[String]:
	var save_files: Array[String] = []
	for mode in [Mode.AUTO, Mode.QUICK]:
		var path := get_save_file_path(mode)
		if FileAccess.file_exists(path):
			save_files.append(path)

	for slot in range(SLOT_COUNT):
		var path := get_save_file_path(Mode.MANUAL, slot)
		if FileAccess.file_exists(path):
			save_files.append(path)

	if FileAccess.file_exists(LEGACY_SAVE_PATH) and not save_files.has(LEGACY_SAVE_PATH):
		save_files.append(LEGACY_SAVE_PATH)

	return save_files


func get_latest_save_path() -> String:
	var latest_time := 0
	var latest_file := ""

	for path in get_all_save_files():
		var modified_time := FileAccess.get_modified_time(path)
		if modified_time >= latest_time:
			latest_time = modified_time
			latest_file = path

	return latest_file


func save_exists(mode = null, slot := 0) -> bool:
	if mode == null:
		return not get_all_save_files().is_empty()

	return FileAccess.file_exists(get_save_file_path(mode, slot))


func get_save_slot_infos() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []

	slots.append(_build_slot_info("quick", "Быстрое сохранение", Mode.QUICK, 0))
	slots.append(_build_slot_info("auto", "Автосохранение", Mode.AUTO, 0))

	for slot in range(SLOT_COUNT):
		slots.append(_build_slot_info("manual_%d" % slot, "Слот %d" % (slot + 1), Mode.MANUAL, slot))

	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		slots.append(_build_path_info("legacy", "Старое сохранение", LEGACY_SAVE_PATH))

	return slots


func get_save_summary(path: String) -> Dictionary:
	var info := {
		"scene_file_path": "",
		"scene_name": "Неизвестная сцена",
		"is_valid": false,
	}

	if path.is_empty() or not FileAccess.file_exists(path):
		return info

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return info

	var data = file.get_var()
	file.close()
	if not (data is Dictionary):
		return info

	var scene_path := str(data.get("scene_file_path", ""))
	info["scene_file_path"] = scene_path
	info["scene_name"] = _humanize_scene_name(scene_path)
	info["is_valid"] = not scene_path.is_empty()
	return info


func save_game(mode: Mode = Mode.QUICK, slot := 0) -> void:
	if is_loading:
		push_warning("Cannot save while loading")
		return

	var player := GameManager.player
	if not is_instance_valid(player):
		push_error("Cannot save: player node is missing")
		return

	var path := get_save_file_path(mode, slot)
	if path.is_empty():
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file %s: %s" % [path, FileAccess.get_open_error()])
		return

	var current_scene := get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path.is_empty():
		push_error("Cannot save: current scene path is empty")
		return

	var save_data := {
		"save_version": 2,
		"scene_file_path": current_scene.scene_file_path,
	}

	for property in GAME_MANAGER_PROPERTIES_TO_SAVE:
		save_data[property] = GameManager.get(property)

	for property in ITEMS_PROPERTIES_TO_SAVE:
		save_data[property] = Items.get(property)

	for property in PLAYER_PROPERTIES_TO_SAVE:
		save_data[property] = player.get(property)

	file.store_var(save_data)
	file.close()

	print("Game saved to %s" % path)


func save_game_to_next_manual_slot() -> void:
	save_game(Mode.MANUAL, get_next_manual_slot_index())


func get_next_manual_slot_index() -> int:
	var oldest_slot := 0
	var oldest_time := INF

	for slot in range(SLOT_COUNT):
		var path := get_save_file_path(Mode.MANUAL, slot)
		if not FileAccess.file_exists(path):
			return slot

		var modified_time := FileAccess.get_modified_time(path)
		if modified_time < oldest_time:
			oldest_time = modified_time
			oldest_slot = slot

	return oldest_slot


func load_game(mode = null, slot := 0) -> void:
	var path := ""
	if mode == null:
		path = get_latest_save_path()
	else:
		path = get_save_file_path(mode, slot)

	load_game_from_file(path)


func load_game_from_file(path: String) -> void:
	if path.is_empty():
		push_warning("Save file path is empty")
		return

	if not FileAccess.file_exists(path):
		push_warning("Save file %s was not found" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open save file %s: %s" % [path, FileAccess.get_open_error()])
		return

	var loaded_data = file.get_var()
	file.close()

	if not (loaded_data is Dictionary):
		push_error("Save file %s has invalid data" % path)
		return

	if not loaded_data.has("scene_file_path") or str(loaded_data["scene_file_path"]).is_empty():
		push_error("Save file %s does not contain a scene path" % path)
		return

	_save_data = loaded_data
	is_loading = true
	GameManager.screen_fader.fade_out()


func load_game_data() -> void:
	if not is_loading:
		return

	if not (_save_data is Dictionary):
		cancel_loading()
		return

	for property in GAME_MANAGER_PROPERTIES_TO_SAVE:
		if _save_data.has(property):
			GameManager.set(property, _save_data[property])
	GameManager.sync_quest_progress()

	var loaded_inventory := Items.items_inventory
	if _save_data.has("items_inventory"):
		loaded_inventory = _save_data["items_inventory"]

	var loaded_order := Items.inventory_order
	if _save_data.has("inventory_order"):
		loaded_order = _save_data["inventory_order"]

	Items.apply_inventory_state(loaded_inventory, loaded_order)
	GameManager._pending_scene_path = GameManager.resolve_scene_path(str(_save_data["scene_file_path"]))

	print("Loaded GameManager data")


func load_player_data() -> void:
	if not is_loading:
		return

	if not is_instance_valid(GameManager.player):
		push_error("Cannot load player data: player node is missing")
		cancel_loading()
		return

	for property in PLAYER_PROPERTIES_TO_SAVE:
		if _save_data.has(property):
			GameManager.player.set(property, _save_data[property])

	print("Loaded player data")
	cancel_loading()


func cancel_loading() -> void:
	is_loading = false
	_save_data = null


func _build_slot_info(id: String, title: String, mode: Mode, slot: int) -> Dictionary:
	return _build_path_info(id, title, get_save_file_path(mode, slot), mode, slot)


func _build_path_info(id: String, title: String, path: String, mode = null, slot := -1) -> Dictionary:
	var exists := FileAccess.file_exists(path)
	var summary := get_save_summary(path) if exists else {}
	return {
		"id": id,
		"title": title,
		"mode": mode,
		"slot": slot,
		"path": path,
		"exists": exists,
		"modified_time": FileAccess.get_modified_time(path) if exists else 0,
		"scene_file_path": str(summary.get("scene_file_path", "")),
		"scene_name": str(summary.get("scene_name", "Пусто")),
		"is_valid": bool(summary.get("is_valid", false)),
	}


func _humanize_scene_name(scene_path: String) -> String:
	if scene_path.is_empty():
		return "Неизвестная сцена"

	var file_name := scene_path.get_file().get_basename()
	if file_name.is_empty():
		return scene_path

	return file_name.replace("_", " ").capitalize()
