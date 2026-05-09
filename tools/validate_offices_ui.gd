extends SceneTree


func _initialize() -> void:
	root.size = Vector2i(1152, 648)
	var items := root.get_node("/root/Items")
	items.call("apply_inventory_state", {"buttle_cola": 0, "coffee_cup": 1}, ["coffee_cup", "buttle_cola"])
	var game_manager := root.get_node("/root/GameManager")
	game_manager.call("reset_game_state")

	var scene: PackedScene = load("res://scenes/test_room_vr.tscn")
	if scene == null:
		_fail("test_room_vr.tscn failed to load")
		return

	var instance := scene.instantiate()
	root.add_child(instance)
	current_scene = instance
	await process_frame
	await process_frame

	var offices := instance as Node2D
	if offices == null:
		_fail("Offices root is not a Node2D")
		return
	if offices.get_node_or_null("Pause_Menu") != null:
		_fail("Offices should not include the old Pause_Menu")
		return
	if offices.get_node_or_null("spawn_marker") == null:
		_fail("Offices is missing spawn_marker")
		return
	if offices.get("default_spawn_point") != "spawn_marker":
		_fail("Offices default spawn point is incorrect")
		return

	var player_scene: PackedScene = offices.get("player_scene")
	if player_scene == null or player_scene.resource_path != "res://scenes/player_with_camera.tscn":
		_fail("Offices must spawn player from player_with_camera.tscn")
		return
	var player: Node = game_manager.get("player")
	if player == null:
		_fail("Offices failed to spawn the player")
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		_fail("Offices player should include Camera2D")
		return
	if camera.position != Vector2.ZERO:
		_fail("Offices should center the player camera on the player")
		return
	if camera.offset != Vector2(127.0, 63.0):
		_fail("Offices camera offset should center the player inside the overlay window")
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		_fail("Offices overlay should keep the mouse cursor visible")
		return

	var background := offices.get_node_or_null("Test_Room_Texture") as Sprite2D
	if background == null or background.texture == null:
		_fail("Offices background texture is missing")
		return
	if background.texture.resource_path != "res://images/scene/test_room_VR.png":
		_fail("Offices background texture path is incorrect")
		return

	var overlay := offices.get_node_or_null("Game_Interface_Overlay") as CanvasLayer
	if overlay == null:
		_fail("Game interface overlay is missing")
		return
	var overlay_root := overlay.get_node_or_null("OverlayRoot") as Control
	if overlay_root == null:
		_fail("OverlayRoot was not built")
		return
	if overlay_root.get_node_or_null("RightPanel/WebcamFrame/MikeWebcam") == null:
		_fail("Mike webcam texture node is missing")
		return
	if overlay_root.get_node_or_null("BottomPanel/DialogueScroll/DialogueContent/DialogueLabel") == null:
		_fail("Dialogue label is missing")
		return
	if overlay_root.get_node_or_null("BottomPanel/DialogueScroll/DialogueContent/Responses") == null:
		_fail("Dialogue responses container is missing")
		return

	var inventory_button := overlay_root.get_node("RightPanel/InventoryHeader/InventoryButton") as Button
	var inventory_drawer := overlay_root.get_node("RightPanel/InventoryDrawer") as Panel
	if inventory_button == null or inventory_drawer == null:
		_fail("Inventory controls are missing")
		return
	if inventory_drawer.visible:
		_fail("Inventory drawer should start closed")
		return

	inventory_button.pressed.emit()
	for _i in range(20):
		await process_frame
	if not inventory_drawer.visible or inventory_drawer.size.y < 120.0:
		_fail("Inventory drawer did not open")
		return

	var inventory_grid := overlay_root.get_node_or_null("RightPanel/InventoryDrawer/InventoryGrid") as GridContainer
	if inventory_grid == null or inventory_grid.get_child_count() != 12:
		_fail("Inventory grid should contain 12 item cells")
		return
	if inventory_grid.get_node_or_null("ItemCell_00/ItemContent/ItemIcon") == null:
		_fail("Inventory should show the default coffee item")
		return
	if not ResourceLoader.exists("res://images/items/Coffe_cup_paper.png"):
		_fail("Coffee cup icon is missing or not imported")
		return

	var cell := inventory_grid.get_node("ItemCell_00") as PanelContainer
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	overlay.call("_on_inventory_cell_gui_input", click_event, cell)
	await process_frame

	var dialogue_text := overlay_root.get_node("BottomPanel/DialogueScroll/DialogueContent/DialogueLabel") as DialogueLabel
	var use_button := overlay_root.get_node("BottomPanel/UseItemButton") as Button
	if not dialogue_text.text.contains("Бодрость"):
		_fail("Selecting coffee should show item description/action text")
		return
	if not use_button.visible:
		_fail("Selecting coffee should show Use button")
		return

	var vigor_before := float(overlay.get("vigor"))
	use_button.pressed.emit()
	await process_frame
	if float(overlay.get("vigor")) != vigor_before + 5.0:
		_fail("Using coffee should increase vigor by 5")
		return
	if use_button.visible:
		_fail("Use button should hide after using coffee")
		return

	items.call("apply_inventory_state", {"buttle_cola": 0, "coffee_cup": 1}, ["coffee_cup", "buttle_cola"])
	await process_frame
	overlay.call("_refresh_inventory")
	overlay.call("_on_inventory_cell_gui_input", click_event, cell)
	await process_frame
	if not use_button.visible:
		_fail("Coffee should be selectable after inventory refresh")
		return
	var outside_event := InputEventMouseButton.new()
	outside_event.button_index = MOUSE_BUTTON_LEFT
	outside_event.pressed = true
	outside_event.position = Vector2(30.0, 30.0)
	overlay.call("_input", outside_event)
	await process_frame
	if use_button.visible or dialogue_text.text != "":
		_fail("Clicking outside selected item should clear item text and Use button")
		return

	var inventory_button_style = inventory_button.get_theme_stylebox("hover")
	if inventory_button_style == null:
		_fail("Inventory button hover style is missing")
		return

	var settings_button := overlay_root.get_node("RightPanel/SettingsButton") as Button
	var settings_drawer := overlay_root.get_node("RightPanel/SettingsDrawer") as Panel
	settings_button.pressed.emit()
	for _i in range(20):
		await process_frame
	if not settings_drawer.visible or settings_drawer.size.y < 140.0:
		_fail("Settings drawer did not open upward")
		return
	if settings_drawer.position.y >= settings_button.position.y:
		_fail("Settings drawer should open above the settings button")
		return
	if settings_drawer.get_node_or_null("SettingsMargin/SettingsVBox/FullscreenCheckBox") == null:
		_fail("Settings drawer is missing fullscreen checkbox")
		return
	if settings_drawer.get_node_or_null("SettingsMargin/SettingsVBox/МузыкаBlock/HSlider") == null:
		_fail("Settings drawer is missing music slider")
		return

	items.call("apply_inventory_state", {"buttle_cola": 0, "coffee_cup": 0}, ["coffee_cup", "buttle_cola"])
	game_manager.call("reload", "offices_coffee_picked_up")
	var coffee_zone := offices.get_node("Ivents/Coffee_Zone")
	coffee_zone.call("_on_body_entered", player)
	player.set("last_direction", "left")
	coffee_zone.call("_start_interaction")
	await process_frame
	await process_frame

	for _i in range(6):
		if overlay_root.get_node("BottomPanel/DialogueScroll/DialogueContent/Responses").visible:
			break
		if dialogue_text.is_typing:
			dialogue_text.skip_typing()
			await process_frame
		var advance_event := InputEventMouseButton.new()
		advance_event.button_index = MOUSE_BUTTON_LEFT
		advance_event.pressed = true
		overlay.call("_on_dialogue_window_gui_input", advance_event)
		await process_frame
		await process_frame

	var responses := overlay_root.get_node("BottomPanel/DialogueScroll/DialogueContent/Responses") as VBoxContainer
	if not responses.visible or responses.get_child_count() < 2:
		_fail("Coffee dialogue should show pickup/leave responses")
		return
	(responses.get_child(0) as Button).pressed.emit()
	await process_frame
	await process_frame
	if int(items.get("items_inventory").get("coffee_cup", 0)) != 1:
		_fail("Choosing pickup should add coffee to inventory")
		return

	var main_menu_button := overlay_root.get_node("RightPanel/MainMenuButton") as Button
	main_menu_button.pressed.emit()
	for _i in range(120):
		await process_frame
	if current_scene == instance:
		_fail("Main menu button did not leave Offices")
		return

	print("offices ui validation passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
