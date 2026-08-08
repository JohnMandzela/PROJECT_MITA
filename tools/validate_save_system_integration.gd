extends SceneTree


func _initialize() -> void:
	if not _validate_autoloads():
		quit(1)
		return

	if not await _validate_save_round_trip():
		quit(1)
		return

	if not _validate_player_spawn_scene():
		quit(1)
		return

	print("save system integration validation passed")
	quit(0)


func _validate_autoloads() -> bool:
	for autoload_name in ["GameManager", "SaveSystem", "Items", "Quests"]:
		if root.get_node_or_null(autoload_name) == null:
			push_error("%s autoload is missing" % autoload_name)
			return false

	var save_system = root.get_node("SaveSystem")
	for method_name in ["save_game", "save_game_to_next_manual_slot", "load_game", "load_game_from_file", "get_all_save_files", "get_latest_save_path", "get_save_slot_infos", "save_exists"]:
		if not save_system.has_method(method_name):
			push_error("SaveSystem is missing %s" % method_name)
			return false

	return true


func _validate_save_round_trip() -> bool:
	var game_manager = root.get_node("GameManager")
	var save_system = root.get_node("SaveSystem")
	var items = root.get_node("Items")

	var fake_scene := Node2D.new()
	fake_scene.name = "FakeCurrentScene"
	fake_scene.scene_file_path = "res://scenes/dorm/mike_room.tscn"
	root.add_child(fake_scene)
	current_scene = fake_scene

	var player_scene: PackedScene = load("res://scenes/player.tscn")
	if player_scene == null:
		push_error("player.tscn failed to load")
		return false

	var player := player_scene.instantiate()
	fake_scene.add_child(player)
	await process_frame

	game_manager.player = player
	game_manager.set_done("3_cola_in_fridge")
	items.apply_inventory_state({"buttle_cola": 1, "coffee_cup": 0}, ["buttle_cola", "coffee_cup"])

	save_system.save_game(save_system.Mode.QUICK)
	save_system.save_game_to_next_manual_slot()
	if not save_system.save_exists(save_system.Mode.QUICK):
		push_error("Quick save was not created")
		return false

	if not save_system.save_exists(save_system.Mode.MANUAL, 0):
		push_error("Manual save slot was not created")
		return false

	var slot_infos: Array = save_system.get_save_slot_infos()
	if slot_infos.size() < 5:
		push_error("Save slot info list does not include quick, auto, and manual slots")
		return false

	var latest_path: String = save_system.get_latest_save_path()
	if latest_path.is_empty():
		push_error("Latest save path is empty after saving")
		return false

	game_manager.reload("3_cola_in_fridge")
	items.apply_inventory_state({"buttle_cola": 0, "coffee_cup": 0}, ["coffee_cup", "buttle_cola"])

	save_system.load_game_from_file(latest_path)
	save_system.load_game_data()
	save_system.load_player_data()

	if not game_manager.is_done("3_cola_in_fridge"):
		push_error("Quest flag was not restored from save")
		return false

	if items.item_check("buttle_cola") != 1:
		push_error("Inventory was not restored from save")
		return false

	if not await _validate_main_menu_slots():
		return false

	current_scene = null
	fake_scene.queue_free()
	await process_frame
	return true


func _validate_player_spawn_scene() -> bool:
	var script := load("res://scripts/autoloads/player_spawn_scene.gd") as Script
	if script == null:
		push_error("player_spawn_scene.gd failed to load")
		return false

	if not script.can_instantiate():
		push_error("player_spawn_scene.gd cannot instantiate")
		return false

	return true


func _validate_main_menu_slots() -> bool:
	var main_menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	if main_menu_scene == null:
		push_error("main_menu.tscn failed to load")
		return false

	var main_menu := main_menu_scene.instantiate()
	root.add_child(main_menu)
	await process_frame
	await process_frame

	var continue_button := main_menu.get_node_or_null("Buttons_VBox/Continue") as Button
	if continue_button == null or not continue_button.visible:
		push_error("Continue button is missing or hidden when saves exist")
		return false

	var overlay := main_menu.get_node_or_null("SaveSlotsOverlay") as Panel
	if overlay == null:
		push_error("SaveSlotsOverlay was not created")
		return false

	main_menu.call("_on_load_button_pressed")
	await process_frame

	if not overlay.visible:
		push_error("Save slots overlay did not open from Load")
		return false

	main_menu.queue_free()
	await process_frame
	return true
