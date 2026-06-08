extends SceneTree


const MIKE_ROOM_SCENE_PATH := "res://scenes/Goshivon/mike_room.tscn"
const BED_SCRIPT_PATH := "res://scripts/2_mike_room/furniture/bed.gd"
const FRIDGE_SCRIPT_PATH := "res://scripts/2_mike_room/furniture/fridge.gd"
const SHOWER_SCRIPT_PATH := "res://scripts/2_mike_room/furniture/shower.gd"
const LAPTOP_SCRIPT_PATH := "res://scripts/2_mike_room/furniture/laptop.gd"


class DialogueContext:
	extends RefCounted

	var locals: Dictionary = {}


func _game_manager() -> Node:
	return root.get_node_or_null("GameManager")


func _items() -> Node:
	return root.get_node_or_null("Items")


func _initialize() -> void:
	root.size = Vector2i(1152, 648)

	if _game_manager() == null or _items() == null:
		_fail("Autoloads GameManager/Items are missing")
		return

	if not await _validate_intro_flag():
		return
	if not await _validate_room_flags_and_dialogues():
		return

	print("mike_room validation passed")
	quit(0)


func _validate_intro_flag() -> bool:
	var game_manager := _game_manager()
	game_manager.reset_game_state()
	game_manager.player = null

	var room := await _instantiate_scene(MIKE_ROOM_SCENE_PATH)
	if room == null:
		return false

	if not game_manager.is_done("1_morning_quest"):
		_fail("Mike Room intro did not set 1_morning_quest")
		return false

	await _free_scene(room)
	return true


func _validate_room_flags_and_dialogues() -> bool:
	var game_manager := _game_manager()
	var items := _items()
	game_manager.reset_game_state()
	game_manager.set_done("1_morning_quest")
	game_manager.player = null
	items.items_inventory["bottle_cola"] = 0

	var room := await _instantiate_scene(MIKE_ROOM_SCENE_PATH)
	if room == null:
		return false

	var player: CharacterBody2D = game_manager.player
	if player == null:
		_fail("Mike Room did not spawn the player")
		return false

	var bed := _find_node_by_script(room, BED_SCRIPT_PATH)
	var fridge := _find_node_by_script(room, FRIDGE_SCRIPT_PATH)
	var shower := _find_node_by_script(room, SHOWER_SCRIPT_PATH)
	var laptop := _find_node_by_script(room, LAPTOP_SCRIPT_PATH)
	if bed == null or fridge == null or shower == null or laptop == null:
		_fail("Mike Room is missing one of the quest interaction nodes")
		return false

	if not await _interact_with_area(bed, player):
		return false
	if not game_manager.is_done("2_mike_room_bed"):
		_fail("Bed interaction did not set 2_mike_room_bed")
		return false

	if not await _interact_with_area(shower, player):
		return false
	if not game_manager.is_done("4_shower_use"):
		_fail("Shower interaction did not set 4_shower_use")
		return false

	game_manager.reload("3_cola_in_fridge")
	items.items_inventory["bottle_cola"] = 1

	var laptop_before := await _collect_dialogue_until_choice(
		laptop.get("dialogue"),
		[_create_dialogue_context(), laptop]
	)
	if laptop_before.is_empty() or laptop_before.back().responses.size() != 5:
		_fail("Laptop dialogue did not expose the unfinished cola branch")
		return false

	var fridge_before := await _collect_dialogue_until_choice(
		fridge.get("dialogue"),
		[_create_dialogue_context(), fridge]
	)
	if fridge_before.is_empty() or fridge_before.back().responses.size() != 3:
		_fail("Fridge dialogue did not expose the cola placement choices")
		return false

	fridge.call("cola_in_fridge", "3_cola_in_fridge")
	if not game_manager.is_done("3_cola_in_fridge"):
		_fail("Fridge action did not set 3_cola_in_fridge")
		return false

	var fridge_after := await _collect_dialogue_until_choice(
		fridge.get("dialogue"),
		[_create_dialogue_context(), fridge]
	)
	if fridge_after.size() != 2 or not fridge_after.back().responses.is_empty():
		_fail("Fridge dialogue did not switch to the completed branch")
		return false

	var laptop_after := await _collect_dialogue_until_choice(
		laptop.get("dialogue"),
		[_create_dialogue_context(), laptop]
	)
	if laptop_after.is_empty() or laptop_after.back().responses.size() != 4:
		_fail("Laptop dialogue did not react to the completed cola quest")
		return false

	await _free_scene(room)
	return true


func _instantiate_scene(scene_path: String) -> Node:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		_fail("Failed to load scene: %s" % scene_path)
		return null

	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	return instance


func _free_scene(scene_root: Node) -> void:
	if scene_root != null and is_instance_valid(scene_root):
		scene_root.queue_free()
	await process_frame
	await process_frame
	_game_manager().player = null


func _find_node_by_script(scene_root: Node, script_path: String) -> Node:
	var nodes := [scene_root]
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		var script = node.get_script()
		if script != null and script.resource_path == script_path:
			return node
		for child in node.get_children():
			nodes.append(child)
	return null


func _interact_with_area(area: Node, player: CharacterBody2D) -> bool:
	if area == null:
		_fail("Attempted to interact with a missing area")
		return false

	area.call("_on_body_entered", player)
	player.last_direction = _direction_to_name(int(area.get("required_direction")))

	var press_event := InputEventAction.new()
	press_event.action = "interact"
	press_event.pressed = true
	Input.parse_input_event(press_event)
	area.call("_process", 0.016)
	await process_frame

	var release_event := InputEventAction.new()
	release_event.action = "interact"
	release_event.pressed = false
	Input.parse_input_event(release_event)
	await process_frame
	return true


func _direction_to_name(direction: int) -> String:
	match direction:
		0:
			return "up"
		1:
			return "down"
		2:
			return "left"
		3:
			return "right"
	return "down"


func _collect_dialogue_until_choice(resource: DialogueResource, extra_states: Array) -> Array:
	var lines: Array = []
	var next_id := "start"

	for _i in range(24):
		var line: DialogueLine = await resource.get_next_dialogue_line(next_id, extra_states)
		if line == null:
			break

		lines.append(line)
		if not line.responses.is_empty():
			break

		next_id = line.next_id

	return lines


func _create_dialogue_context() -> DialogueContext:
	return DialogueContext.new()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
