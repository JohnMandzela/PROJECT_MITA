extends SceneTree


func _game_manager() -> Node:
	# В headless-валидаторе берем автозагрузку явно из корня дерева.
	return root.get_node("/root/GameManager")


func _initialize() -> void:
	# Поднимаем сцену в том же размере окна, в котором обычно работает проект.
	root.size = Vector2i(1152, 648)

	var scene: PackedScene = load("res://scenes/Mihyung_Offices/Programming_Office.tscn")
	if scene == null:
		_fail("Programming_Office.tscn failed to load")
		return

	var instance: Node = scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame

	# Проверяем базовые узлы новой локации и настройки спавна.
	var office: Node2D = instance as Node2D
	if office == null:
		_fail("Programming_Office root is not a Node2D")
		return
	if office.get_node_or_null("Pause_Menu") == null:
		_fail("Programming Office is missing Pause_Menu")
		return
	if office.get_node_or_null("spawn_marker") == null:
		_fail("Programming Office is missing spawn_marker")
		return
	if office.get("default_spawn_point") != "spawn_marker":
		_fail("Programming Office default spawn point is incorrect")
		return

	# Убеждаемся, что игрок берется из Player.tscn без встроенной камеры.
	var player_scene: PackedScene = office.get("player_scene")
	if player_scene == null or player_scene.resource_path != "res://scenes/player.tscn":
		_fail("Programming Office must spawn player from Player.tscn")
		return
	if _game_manager().get("player") == null:
		_fail("Programming Office failed to spawn the player")
		return

	# Камера сцены должна быть статичной, как в небольших комнатах, и использовать комнатный zoom.
	var camera: Camera2D = office.get_node("Camera2D")
	if camera.zoom != Vector2(1.4, 1.4):
		_fail("Programming Office camera zoom is incorrect")
		return
	var player: CharacterBody2D = _game_manager().get("player")
	var initial_camera_position: Vector2 = camera.global_position
	player.global_position = Vector2(120.0, 240.0)
	await process_frame
	if camera.global_position.distance_to(initial_camera_position) > 0.01:
		_fail("Programming Office camera should remain static inside the room")
		return

	# Проверяем ивент-зону, направление взгляда и запуск мини-игры.
	var zone: Area2D = office.get_node("Ivents/Samples_Puzzle_Zone")
	if int(zone.get("required_direction")) != 2:
		_fail("Programming Office interaction zone must require LEFT look direction")
		return
	zone.call("_on_body_entered", player)
	player.last_direction = "left"
	zone.call("_start_interaction")
	await process_frame
	await process_frame

	if not bool(_game_manager().get("disable_movement")):
		_fail("Player movement was not blocked after opening samples puzzle")
		return
	if not bool(office.call("is_samples_puzzle_open")):
		_fail("Samples puzzle did not open from the interaction zone")
		return
	if not bool(_game_manager().get("is_minigame_active")):
		_fail("GameManager should mark the minigame as active while the puzzle is open")
		return

	var puzzle_container: Control = office.get_node("PuzzleLayer/PuzzleContainer")
	if puzzle_container.get_child_count() != 1:
		_fail("Samples puzzle was not added into the puzzle container")
		return
	var cached_puzzle: Node = puzzle_container.get_child(0)
	var pause_menu: Control = office.get_node("Pause_Menu")
	var puzzle_pause_overlay: Control = cached_puzzle.get_node("PauseOverlay")

	# Escape через общий pause menu должен открыть локальный overlay мини-игры, а не системную паузу.
	var escape_event := InputEventAction.new()
	escape_event.action = "ui_cancel"
	escape_event.pressed = true
	pause_menu.call("_input", escape_event)
	await process_frame
	if not puzzle_pause_overlay.visible:
		_fail("Pause menu should redirect Escape into the puzzle pause overlay")
		return
	if pause_menu.visible or paused:
		_fail("Global pause menu should stay closed while the puzzle is active")
		return
	cached_puzzle.call("_on_pause_continue_pressed")
	await process_frame

	# После закрытия мини-игры движение игрока должно вернуться, но сам узел пазла должен остаться в контейнере.
	office.call("close_samples_puzzle")
	await process_frame
	if bool(_game_manager().get("disable_movement")):
		_fail("Player movement stayed blocked after closing samples puzzle")
		return
	if bool(_game_manager().get("is_minigame_active")):
		_fail("GameManager should clear the active minigame flag after closing the puzzle")
		return
	if bool(office.call("is_samples_puzzle_open")):
		_fail("Samples puzzle remained open after close_samples_puzzle")
		return
	if puzzle_container.get_child_count() != 1 or puzzle_container.get_child(0) != cached_puzzle:
		_fail("Samples puzzle node should stay cached after closing")
		return

	# После успешного завершения флаг должен блокировать повторный запуск мини-игры из зоны.
	office.call("_on_puzzle_completed")
	zone.call("_start_interaction")
	await process_frame
	if bool(office.call("is_samples_puzzle_open")):
		_fail("Completed puzzle should not reopen from the interaction zone")
		return

	print("programming_office validation passed")
	quit(0)


func _fail(message: String) -> void:
	# Любая ошибка проверки завершает валидатор с кодом 1.
	push_error(message)
	quit(1)
