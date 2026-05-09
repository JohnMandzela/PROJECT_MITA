extends SceneTree


const MOCKUP_SCENES := [
	"res://scenes/Mihyung_Offices/corridors_offices.tscn",
	"res://scenes/Mihyung_Offices/manager's_cabinet.tscn",
	"res://scenes/Mihyung_Offices/conference_room.tscn",
	"res://scenes/Mihyung_Offices/utility_room.tscn",
	"res://scenes/Mihyung_Offices/reception_hall.tscn",
	"res://scenes/Mihyung_Offices/toilet_man.tscn",
]

const DIALOGUES := [
	"res://dialogues/1_mom_home/sleep_flashback.dialogue",
	"res://dialogues/Этап2.dialogue",
	"res://dialogues/Этап3.dialogue",
	"res://dialogues/Этап4.dialogue",
	"res://dialogues/Этап5.dialogue",
	"res://dialogues/Этап6.dialogue",
]


func _initialize() -> void:
	for scene_path in MOCKUP_SCENES:
		if not _validate_mockup_scene(scene_path):
			quit(1)
			return

	if not _validate_mom_home():
		quit(1)
		return

	for dialogue_path in DIALOGUES:
		if not _validate_dialogue(dialogue_path):
			quit(1)
			return

	print("diogen integration validation passed")
	quit(0)


func _validate_mockup_scene(scene_path: String) -> bool:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("%s failed to load" % scene_path)
		return false

	var inst := packed.instantiate()
	if inst == null:
		push_error("%s failed to instantiate" % scene_path)
		return false

	if inst.get_script() == null:
		push_error("%s root has no PlayerSpawnScene script" % scene_path)
		inst.free()
		return false

	if inst.get("player_scene") == null:
		push_error("%s has no player_scene configured" % scene_path)
		inst.free()
		return false

	var default_spawn_point := str(inst.get("default_spawn_point"))
	if default_spawn_point.is_empty():
		push_error("%s has no default_spawn_point configured" % scene_path)
		inst.free()
		return false

	if inst.get_node_or_null(default_spawn_point) == null:
		push_error("%s has no default spawn point node: %s" % [scene_path, default_spawn_point])
		inst.free()
		return false

	if inst.get_node_or_null("Pause_Menu") == null:
		push_error("%s has no Pause_Menu instance" % scene_path)
		inst.free()
		return false

	var collision_count := 0
	for child in _walk_nodes(inst):
		if child is CollisionPolygon2D or child is CollisionShape2D:
			collision_count += 1

	if collision_count == 0:
		push_error("%s has no collision geometry" % scene_path)
		inst.free()
		return false

	inst.free()
	return true


func _validate_mom_home() -> bool:
	var packed := load("res://scenes/mom_home.tscn") as PackedScene
	if packed == null:
		push_error("mom_home.tscn failed to load")
		return false

	var inst := packed.instantiate()
	if inst == null:
		push_error("mom_home.tscn failed to instantiate")
		return false

	var event_root := inst.get_node_or_null("Sleep_Flashback")
	if event_root == null:
		push_error("mom_home.tscn has no Sleep_Flashback node")
		inst.free()
		return false

	for method_name in ["darken_screen", "darken_screen_backwards", "lighten_screen", "lighten_screen_backwards", "dialogue_end"]:
		if not event_root.has_method(method_name):
			push_error("Sleep_Flashback is missing %s" % method_name)
			inst.free()
			return false

	for node_path in ["CanvasLayer/AnimationDarken", "CanvasLayer/AnimationLighten", "Collisions/StaticBody2D/Walls"]:
		if event_root.get_node_or_null(node_path) == null:
			push_error("Sleep_Flashback is missing %s" % node_path)
			inst.free()
			return false

	inst.free()
	return true


func _validate_dialogue(dialogue_path: String) -> bool:
	if not ResourceLoader.exists(dialogue_path):
		push_error("%s does not exist" % dialogue_path)
		return false

	var dialogue := load(dialogue_path)
	if dialogue == null:
		push_error("%s failed to load" % dialogue_path)
		return false

	return true


func _walk_nodes(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_walk_nodes(child))
	return result
