extends SceneTree


const ELEVATOR_SCENE_PATH := "res://scenes/Mihyung_Offices/elevator_office.tscn"


class DialogueContext:
	extends RefCounted

	var locals: Dictionary = {}


func _initialize() -> void:
	root.size = Vector2i(1152, 648)

	var without_shower: Variant = await _collect_scene_dialogue(false)
	if without_shower == null:
		return

	var with_shower: Variant = await _collect_scene_dialogue(true)
	if with_shower == null:
		return

	if with_shower.size() <= without_shower.size():
		_fail("Elevator Office dialogue did not expand after the shower flag changed")
		return

	print("elevator_office validation passed")
	quit(0)


func _collect_scene_dialogue(shower_used: bool) -> Variant:
	var game_manager := root.get_node("GameManager")
	game_manager.call("reset_game_state")
	game_manager.set("player", null)
	if shower_used:
		game_manager.call("set_done", "4_shower_use")

	var scene: PackedScene = load(ELEVATOR_SCENE_PATH)
	if scene == null:
		_fail("Failed to load Elevator Office scene")
		return null

	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame

	var dialogue_resource: DialogueResource = instance.get("dialogue")
	if dialogue_resource == null:
		_fail("Elevator Office scene has no dialogue resource")
		return null

	var context := DialogueContext.new()
	var lines := await _collect_dialogue_lines(dialogue_resource, [context, instance])

	instance.queue_free()
	await process_frame
	await process_frame

	if lines.is_empty():
		_fail("Elevator Office dialogue returned no lines")
		return null

	return lines


func _collect_dialogue_lines(resource: DialogueResource, extra_states: Array) -> Array:
	var lines: Array = []
	var next_id := "start"

	for _i in range(32):
		var line: DialogueLine = await resource.get_next_dialogue_line(next_id, extra_states)
		if line == null:
			break

		lines.append(line)
		next_id = line.next_id
		if not line.responses.is_empty():
			break

	return lines


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
