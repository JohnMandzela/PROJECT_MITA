extends Control


#---------------------------------------------------------------------------------------------------------------
# Переменные к путям главных окон
@onready var pause_label:= $Panel/Pause_Label                                   # Заголовок "Пауза"
@onready var pause_menu_ui: Panel = $Panel/Start_Display                        # Стартовое окно
@onready var menu_options: VBoxContainer = $Panel/VBoxOptions                   # Настройки

# Переменные к путям данных настроек
@onready var fullscren_checkbox_path: CheckBox = $Panel/VBoxOptions/Fullscreen_CheckBox
@onready var music_value_path: HSlider = $Panel/VBoxOptions/Music/Music_slider/music_slider
@onready var sounds_value_path: HSlider = $Panel/VBoxOptions/Sounds/sounds_slider/sounds_slider

# Флажки на события
var menu_open = 0                                      # Открыто меню или нет
var loading_settings := true                           # Загрузка настроек

# Переменные с анимацией
@onready var anim_on_off: AnimationPlayer = $Screen_Fader_Animation/OnOff_Screen_Fader/AnimationPlayer
@onready var anim_exit: AnimationPlayer = $Screen_Fader_Animation/Exit_Screen_Fader/AnimationPlayer
@onready var anim_phone: AnimationPlayer = $Panel/AnimationPlayer
@onready var anim_blur: AnimationPlayer = $Screen_Fader_Animation/Blur_Rect/AnimationPlayer

# Переменные с путями мессенджера и туториала
@onready var messenger: Panel = $Panel/Messenger
@onready var tutorial: Panel = $Panel/Tutorial
#---------------------------------------------------------------------------------------------------------------


# Сохраняем данные настроек
func save_settings():
	var config = ConfigFile.new()

	config.set_value("video", "fullscreen", fullscren_checkbox_path.button_pressed)
	config.set_value("audio", "music_volume", music_value_path.value)
	config.set_value("audio", "sounds_volume", sounds_value_path.value)

	config.save(GameManager.SETTINGS_PATH)


func _ready():
	# Ставим галочку на Fullscreen
	var mode = DisplayServer.window_get_mode()
	var is_full = (mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_FULLSCREEN)

	fullscren_checkbox_path.button_pressed = is_full
	
	visible = false
	pause_menu_ui.visible = false
	menu_options.visible = false
	pause_label.visible = false
	messenger.visible = false
	tutorial.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	var config = ConfigFile.new()
	var err = config.load(GameManager.SETTINGS_PATH)

	if err == OK:
		var music : float = config.get_value("audio", "music_volume", 100.0)
		var sound : float = config.get_value("audio", "sounds_volume", 100.0)
		music_value_path.value = music
		sounds_value_path.value = sound

	# Применяем всё c задержкой одного кадра
	await get_tree().process_frame
	_apply_settings()
	loading_settings = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if menu_open == 0:
			menu_open = menu_open + 1
			toggle()
		else:
			menu_open = menu_open - 1
			close_pause_menu()

func toggle() -> void:
	pause_menu_ui.visible = true
	pause_label.visible = true
	anim_blur.play("blur_on")
	anim_phone.play("on_phone")
	anim_on_off.play("open_pause_menu")
	var new_state := !get_tree().paused
	get_tree().paused = new_state
	visible = new_state
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _on_continue_pressed() -> void:
	if menu_open == 1:
		menu_open = menu_open - 1
	close_pause_menu()

func _on_options_pressed() -> void:
	pause_menu_ui.visible = false
	pause_label.visible = false
	menu_options.visible = true

# Сигнал слайдера эффектов
func _on_sounds_value_changed(value):
	var db
	if value == 0:
		db = -80
	else:
		db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), db)
	if loading_settings == false:
		save_settings()

# Сигнал слайдера музыки
func _on_music_value_changed(value):
	var db
	if value == 0:
		db = -80
	else:
		db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	if loading_settings == false:
		save_settings()

# Сигнал checkbox
func _on_fullscreen_toggled(pressed):
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed 
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if loading_settings == false:
		save_settings()

# Применение всех настроек при запуске сцены
func _apply_settings():
	_on_fullscreen_toggled(fullscren_checkbox_path.button_pressed)
	_on_music_value_changed(music_value_path.value)
	_on_sounds_value_changed(sounds_value_path.value)


func close_pause_menu() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	anim_blur.play("blur_off")
	anim_phone.play("off_phone")
	anim_on_off.play("close_pause_menu")
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = false
	visible = false
	pause_menu_ui.visible = false
	menu_options.visible = false
	pause_label.visible = false
	messenger.visible = false
	tutorial.visible = false

func _on_exit_to_main_menu_pressed() -> void:
	anim_exit.play("exit_to_main_menu")
	await get_tree().create_timer(0.7).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_inventory_pressed() -> void:
	pass # Replace with function body.


func _on_messenger_pressed() -> void:
	pause_menu_ui.visible = false
	menu_options.visible = false
	pause_label.visible = false
	messenger.visible = true


func _on_tutorial_pressed() -> void:
	pause_menu_ui.visible = false
	tutorial.visible = true
	messenger.visible = false
	pause_label.visible = false


func _on_back_from_options_pressed() -> void:
	pause_menu_ui.visible = true
	pause_label.visible = true
	menu_options.visible = false

func _on_back_from_messenger_pressed() -> void:
	pause_menu_ui.visible = true
	pause_label.visible = true
	messenger.visible = false

func _on_back_from_tutorial_pressed() -> void:
	tutorial.visible = false
	messenger.visible = true
<<<<<<< Updated upstream
=======


func _on_save_pressed() -> void:
	SaveSystem.save_game()
	SaveSystem.save_game_to_next_manual_slot()


func _on_load_pressed() -> void:
	toggle()
	SaveSystem.load_game()


func _on_items_inventory_changed() -> void:
	_refresh_inventory_ui()


func _refresh_inventory_ui() -> void:
	for child in inventory_items_list.get_children():
		if child != inventory_item_template:
			child.queue_free()

	_inventory_rows.clear()
	_clear_inventory_selection()

	var has_items := false
	var ordered_ids := Items.get_ordered_item_ids()
	for item_id in ordered_ids:
		if not Items.is_known_item(item_id):
			continue

		var item_count := int(Items.items_inventory.get(item_id, 0))
		if item_count <= 0:
			continue

		has_items = true
		var row := inventory_item_template.duplicate() as HBoxContainer
		row.visible = true
		row.name = "ItemRow_%s" % item_id

		var icon := row.get_node("ItemIcon") as TextureRect
		var info_block := row.get_node("ItemInfoBlock") as PanelContainer
		var item_name := row.get_node("ItemInfoBlock/ItemInfoHBox/ItemName") as Label
		var item_count_label := row.get_node("ItemInfoBlock/ItemInfoHBox/ItemCount") as Label

		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		info_block.mouse_filter = Control.MOUSE_FILTER_STOP

		var item_info: Dictionary = Items.get_item_info(item_id)
		item_name.text = str(item_info.get("display_name", item_id))
		item_count_label.text = "x%d" % item_count
		icon.texture = _load_item_icon(str(item_info.get("icon_path", "")))

		icon.gui_input.connect(_on_item_cell_gui_input.bind(item_id))
		info_block.gui_input.connect(_on_item_cell_gui_input.bind(item_id))
		icon.mouse_entered.connect(_on_item_hover_entered.bind(item_id))
		info_block.mouse_entered.connect(_on_item_hover_entered.bind(item_id))
		icon.mouse_exited.connect(_on_item_hover_exited.bind(item_id))
		info_block.mouse_exited.connect(_on_item_hover_exited.bind(item_id))

		inventory_items_list.add_child(row)
		_inventory_rows[item_id] = {
			"icon": icon,
			"info": info_block,
			"hovered": false,
			"pressed": false,
		}
		_apply_row_visual(item_id)

	if not has_items:
		var empty_label := Label.new()
		empty_label.text = EMPTY_LIST_TEXT
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_items_list.add_child(empty_label)

	_reset_scroll_state(SCROLL_INVENTORY)


func _refresh_quests_ui() -> void:
	_refresh_active_quests_ui()
	_refresh_completed_quests_ui()
	quest_details.visible = false


func _refresh_active_quests_ui() -> void:
	for child in quest_list.get_children():
		if child != quest_row_template:
			child.queue_free()

	_active_quest_rows.clear()

	var has_active_quests := false
	for quest_id in GameManager.quests_info.keys():
		var info: Dictionary = GameManager.quests_info[quest_id]
		if not bool(info.get("is_active", false)) or bool(info.get("is_completed", false)):
			continue

		has_active_quests = true
		var row := quest_row_template.duplicate() as Button
		row.visible = true
		row.name = "QuestRow_%s" % quest_id
		row.text = _build_quest_row_text(info, quest_id)
		row.pressed.connect(_on_quest_row_pressed.bind(quest_id, SCROLL_ACTIVE_QUESTS))
		quest_list.add_child(row)
		_active_quest_rows[quest_id] = row

	if not has_active_quests:
		var empty_label := Label.new()
		empty_label.text = EMPTY_LIST_TEXT
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quest_list.add_child(empty_label)

	_reset_scroll_state(SCROLL_ACTIVE_QUESTS)


func _refresh_completed_quests_ui() -> void:
	for child in completed_quest_list.get_children():
		if child != completed_quest_row_template:
			child.queue_free()

	_completed_quest_rows.clear()

	var has_completed_quests := false
	for quest_id in GameManager.quests_info.keys():
		var info: Dictionary = GameManager.quests_info[quest_id]
		if not bool(info.get("is_completed", false)):
			continue

		has_completed_quests = true
		var row := completed_quest_row_template.duplicate() as Button
		row.visible = true
		row.name = "CompletedQuestRow_%s" % quest_id
		row.text = _build_quest_row_text(info, quest_id)
		row.pressed.connect(_on_quest_row_pressed.bind(quest_id, SCROLL_COMPLETED_QUESTS))
		completed_quest_list.add_child(row)
		_completed_quest_rows[quest_id] = row

	if not has_completed_quests:
		var empty_label := Label.new()
		empty_label.text = EMPTY_LIST_TEXT
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		completed_quest_list.add_child(empty_label)

	_reset_scroll_state(SCROLL_COMPLETED_QUESTS)


func _on_quest_row_pressed(quest_id: String, source: String) -> void:
	if not GameManager.quests_info.has(quest_id):
		return
	var info: Dictionary = GameManager.quests_info[quest_id]
	quest_details_title.text = str(info.get("title", quest_id))
	quest_details_text.text = _build_quest_details_text(info)
	_quest_details_source = source
	quest_details.visible = true
	quest_vbox.visible = false
	completed_quests_overlay.visible = false


func _build_quest_row_text(info: Dictionary, quest_id: String) -> String:
	var prefix := QUEST_DONE_PREFIX if bool(info.get("is_completed", false)) else QUEST_TODO_PREFIX
	return prefix + str(info.get("title", quest_id))


func _build_quest_details_text(info: Dictionary) -> String:
	var description := str(info.get("description", ""))
	var status := QUEST_STATUS_DONE if bool(info.get("is_completed", false)) else QUEST_STATUS_TODO
	if description.is_empty():
		return status
	return "%s\n\n%s" % [description, status]


func _on_item_cell_gui_input(event: InputEvent, item_id: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_set_row_pressed(item_id, true)
			_select_inventory_item(item_id)
			get_viewport().set_input_as_handled()
		else:
			_set_row_pressed(item_id, false)
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_set_row_pressed(item_id, true)
			_select_inventory_item(item_id)
			get_viewport().set_input_as_handled()
		else:
			_set_row_pressed(item_id, false)


func _on_item_hover_entered(item_id: String) -> void:
	if not _inventory_rows.has(item_id):
		return
	_inventory_rows[item_id]["hovered"] = true
	_apply_row_visual(item_id)


func _on_item_hover_exited(item_id: String) -> void:
	if not _inventory_rows.has(item_id):
		return
	_inventory_rows[item_id]["hovered"] = false
	_inventory_rows[item_id]["pressed"] = false
	_apply_row_visual(item_id)


func _set_row_pressed(item_id: String, pressed: bool) -> void:
	if not _inventory_rows.has(item_id):
		return
	_inventory_rows[item_id]["pressed"] = pressed
	_apply_row_visual(item_id)


func _apply_row_visual(item_id: String) -> void:
	if not _inventory_rows.has(item_id):
		return

	var state: Dictionary = _inventory_rows[item_id]
	var visual_color := VISUAL_NORMAL
	if state["pressed"]:
		visual_color = VISUAL_PRESSED
	elif state["hovered"]:
		visual_color = VISUAL_HOVER

	(state["icon"] as CanvasItem).modulate = visual_color
	(state["info"] as CanvasItem).modulate = visual_color


func _select_inventory_item(item_id: String) -> void:
	_selected_item_id = item_id
	var item_info: Dictionary = Items.get_item_info(item_id)
	inventory_description.text = str(item_info.get("description", ""))
	inventory_description.visible = true


func _clear_inventory_selection() -> void:
	_selected_item_id = ""
	inventory_description.text = ""
	inventory_description.visible = false


func _load_item_icon(icon_path: String) -> Texture2D:
	var fallback_icon := (inventory_item_template.get_node("ItemIcon") as TextureRect).texture
	if icon_path.is_empty():
		return fallback_icon

	var loaded_icon = load(icon_path)
	if loaded_icon is Texture2D:
		return loaded_icon
	return fallback_icon


func _is_position_over_inventory_widget(global_position: Vector2) -> bool:
	for state in _inventory_rows.values():
		var icon := state["icon"] as Control
		var info := state["info"] as Control
		if icon.get_global_rect().has_point(global_position):
			return true
		if info.get_global_rect().has_point(global_position):
			return true
	return false


func _show_active_quests_page() -> void:
	quest_vbox.visible = true
	completed_quests_overlay.visible = false
	quest_details.visible = false
	_cancel_scroll_drag()


func _show_completed_quests_page() -> void:
	quest_vbox.visible = false
	completed_quests_overlay.visible = true
	quest_details.visible = false
	_cancel_scroll_drag()


func _register_scroll_area(scroll_id: String, scroll: ScrollContainer) -> void:
	_scroll_states[scroll_id] = {
		"scroll": scroll,
		"target": 0.0,
		"velocity": 0.0,
		"dragging": false,
	}
	scroll.gui_input.connect(_on_scroll_gui_input.bind(scroll_id))


func _reset_scroll_state(scroll_id: String) -> void:
	if not _scroll_states.has(scroll_id):
		return

	var state: Dictionary = _scroll_states[scroll_id]
	var scroll := state["scroll"] as ScrollContainer
	scroll.scroll_vertical = 0
	state["target"] = 0.0
	state["velocity"] = 0.0
	state["dragging"] = false


func _cancel_scroll_drag() -> void:
	for scroll_id in _scroll_states.keys():
		_scroll_states[scroll_id]["dragging"] = false


func _on_scroll_gui_input(event: InputEvent, scroll_id: String) -> void:
	if not _is_scroll_area_visible(scroll_id):
		return

	var state: Dictionary = _scroll_states[scroll_id]
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			state["target"] = _clamp_scroll_target(scroll_id, float(state["target"]) - WHEEL_SCROLL_STEP)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			state["target"] = _clamp_scroll_target(scroll_id, float(state["target"]) + WHEEL_SCROLL_STEP)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				state["dragging"] = true
				state["velocity"] = 0.0
			else:
				state["dragging"] = false
			return

	if event is InputEventMouseMotion and bool(state["dragging"]):
		state["target"] = _clamp_scroll_target(
			scroll_id,
			float(state["target"]) - event.relative.y * DRAG_SCROLL_MULTIPLIER
		)
		state["velocity"] = -event.relative.y * SCROLL_INERTIA_SCALE
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			state["dragging"] = true
			state["velocity"] = 0.0
		else:
			state["dragging"] = false
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag and bool(state["dragging"]):
		state["target"] = _clamp_scroll_target(
			scroll_id,
			float(state["target"]) - event.relative.y * DRAG_SCROLL_MULTIPLIER
		)
		state["velocity"] = -event.relative.y * SCROLL_INERTIA_SCALE
		get_viewport().set_input_as_handled()


func _update_scroll(scroll_id: String, delta: float) -> void:
	if not _is_scroll_area_visible(scroll_id) or not _scroll_states.has(scroll_id):
		return

	var state: Dictionary = _scroll_states[scroll_id]
	if not bool(state["dragging"]):
		state["target"] = float(state["target"]) + float(state["velocity"]) * delta
		state["velocity"] = move_toward(
			float(state["velocity"]),
			0.0,
			SCROLL_INERTIA_DAMP * SCROLL_INERTIA_SCALE * delta
		)
		if absf(float(state["velocity"])) < SCROLL_INERTIA_CUTOFF:
			state["velocity"] = 0.0

	state["target"] = _clamp_scroll_target(scroll_id, float(state["target"]))

	var scroll := state["scroll"] as ScrollContainer
	var current_scroll := float(scroll.scroll_vertical)
	var next_scroll := lerpf(
		current_scroll,
		float(state["target"]),
		minf(1.0, SCROLL_FOLLOW_SPEED * delta)
	)
	scroll.scroll_vertical = int(round(next_scroll))


func _is_scroll_area_visible(scroll_id: String) -> bool:
	match scroll_id:
		SCROLL_INVENTORY:
			return inventory_view.visible
		SCROLL_ACTIVE_QUESTS:
			return quest_view.visible and quest_vbox.visible
		SCROLL_COMPLETED_QUESTS:
			return quest_view.visible and completed_quests_overlay.visible
	return false


func _clamp_scroll_target(scroll_id: String, value: float) -> float:
	var state: Dictionary = _scroll_states.get(scroll_id, {})
	var scroll := state.get("scroll", null) as ScrollContainer
	if scroll == null:
		return 0.0

	var scrollbar := scroll.get_v_scroll_bar()
	var max_scroll := maxf(0.0, scrollbar.max_value - scrollbar.page)
	return clampf(value, 0.0, max_scroll)
>>>>>>> Stashed changes
