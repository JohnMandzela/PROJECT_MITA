extends GutTest

# Проверки сцены игрока: одна сцена, камера на Phantom Camera

const REMOVED_PLAYER_UID := "uid://ckrm4qu32khu7"


func test_player_scene_has_camera_rig() -> void:
	var player: Node = load("res://scenes/characters/player.tscn").instantiate()
	add_child_autofree(player)
	await wait_process_frames(1)

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	var host: Node = player.get_node_or_null("Camera2D/PhantomCameraHost")
	var pcam: Node = player.get_node_or_null("PhantomCamera2D")

	assert_not_null(camera, "в player.tscn должна быть Camera2D")
	assert_not_null(host, "PhantomCameraHost должен быть ребёнком Camera2D")
	assert_not_null(pcam, "в player.tscn должен быть PhantomCamera2D")
	assert_same(pcam.get("follow_target"), player, "PCam должен следовать за игроком")


func test_player_with_camera_is_removed() -> void:
	assert_false(
		ResourceLoader.exists("res://scenes/characters/player_with_camera.tscn"),
		"player_with_camera больше не нужна: камера живёт в player.tscn"
	)


func test_no_scene_references_removed_player_scene() -> void:
	var scenes: Array[String] = []
	_collect_scenes("res://scenes", scenes)

	for path in scenes:
		var text := FileAccess.get_file_as_string(path)
		assert_false(
			text.contains(REMOVED_PLAYER_UID),
			"%s всё ещё ссылается на player_with_camera" % path
		)


func _collect_scenes(path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := path + "/" + name
		if dir.current_is_dir():
			_collect_scenes(full, out)
		elif name.ends_with(".tscn"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
