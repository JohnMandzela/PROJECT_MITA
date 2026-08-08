extends SceneTree


const SCENES_TO_VALIDATE := [
	"res://scenes/mom_home.tscn",
	"res://scenes/dorm/mike_room.tscn",
	"res://scenes/dorm/dorm.tscn",
	"res://scenes/dorm/dorm_1_floor.tscn",
	"res://scenes/Mihyung_Offices/reception_hall.tscn",
	"res://scenes/Mihyung_Offices/elevator_office.tscn",
	"res://scenes/Mihyung_Offices/corridors_offices.tscn",
	"res://scenes/Mihyung_Offices/Programming_Office.tscn",
	"res://scenes/Mihyung_Offices/manager's_cabinet.tscn",
	"res://scenes/Mihyung_Offices/conference_room.tscn",
	"res://scenes/Mihyung_Offices/mens_toilet.tscn",
	"res://scenes/Mihyung_Offices/utility_room.tscn",
]

const SCENE_RESOLUTION_CASES := {
	"Goshivon/mike_room": "res://scenes/dorm/mike_room.tscn",
	"Mike_Room": "res://scenes/dorm/mike_room.tscn",
	"res://scenes/mike_room.tscn": "res://scenes/dorm/mike_room.tscn",
	"Mihyung_Offices/corridors_offices": "res://scenes/Mihyung_Offices/corridors_offices.tscn",
	"Corridors_Offices": "res://scenes/Mihyung_Offices/corridors_offices.tscn",
}


func _initialize() -> void:
	if root.get_node_or_null("GameManager") == null:
		push_error("Autoload GameManager is missing")
		quit(1)
		return

	if not _validate_scene_resolution_cases():
		quit(1)
		return

	for scene_path in SCENES_TO_VALIDATE:
		if not _validate_scene(scene_path):
			quit(1)
			return

	print("scene dependency validation passed")
	quit(0)


func _validate_scene_resolution_cases() -> bool:
	var game_manager := root.get_node("GameManager")
	for scene_reference in SCENE_RESOLUTION_CASES:
		var resolved_path := str(game_manager.call("resolve_scene_path", scene_reference))
		if resolved_path != SCENE_RESOLUTION_CASES[scene_reference]:
			push_error(
				"Expected %s to resolve to %s, got %s"
				% [scene_reference, SCENE_RESOLUTION_CASES[scene_reference], resolved_path]
			)
			return false

	return true


func _validate_scene(scene_path: String) -> bool:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Failed to load source scene: %s" % scene_path)
		return false

	var instance := packed.instantiate()
	if instance == null:
		push_error("Failed to instantiate source scene: %s" % scene_path)
		return false

	for node in _walk_nodes(instance):
		if not _has_property(node, "target_scene"):
			continue

		var target_reference := str(node.get("target_scene"))
		if target_reference.is_empty():
			continue

		var game_manager := root.get_node("GameManager")
		var target_scene_path := str(game_manager.call("resolve_scene_path", target_reference))
		if target_scene_path.is_empty() or not ResourceLoader.exists(target_scene_path):
			instance.free()
			push_error("%s -> %s does not resolve to an existing scene" % [scene_path, target_reference])
			return false

		if not _validate_spawn_point(scene_path, node, target_scene_path):
			instance.free()
			return false

	instance.free()
	return true


func _validate_spawn_point(source_scene_path: String, transition_node: Node, target_scene_path: String) -> bool:
	if not _has_property(transition_node, "target_spawn_point"):
		return true

	var spawn_point := str(transition_node.get("target_spawn_point"))
	if spawn_point.is_empty():
		return true

	var target_packed := load(target_scene_path) as PackedScene
	if target_packed == null:
		push_error("Failed to load target scene: %s" % target_scene_path)
		return false

	var target_instance := target_packed.instantiate()
	if target_instance == null:
		push_error("Failed to instantiate target scene: %s" % target_scene_path)
		return false

	var exists := target_instance.get_node_or_null(spawn_point) != null
	target_instance.free()

	if not exists:
		push_error(
			"%s has transition %s -> %s, but spawn point %s is missing"
			% [source_scene_path, transition_node.get_path(), target_scene_path, spawn_point]
		)
		return false

	return true


func _walk_nodes(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_walk_nodes(child))
	return result


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true

	return false
