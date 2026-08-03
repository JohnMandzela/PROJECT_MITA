extends Control

@onready var pause_label: Label = $Panel/PauseLabel
@onready var pause_menu_ui: Panel = $Panel/StartDisplay
@onready var inventory_view: Panel = $Panel/InventoryView
@onready var quest_view: Panel = $Panel/QuestContainer
@onready var menu_options: VBoxContainer = $Panel/VBoxOptions

@onready var inventory_scroll: ScrollContainer = $Panel/InventoryView/InventoryVBox/InventoryScroll
@onready var inventory_items_list: VBoxContainer = $Panel/InventoryView/InventoryVBox/InventoryScroll/ItemsList
@onready var inventory_item_template: HBoxContainer = $Panel/InventoryView/InventoryVBox/InventoryScroll/ItemsList/ItemRowTemplate
@onready var inventory_description: Label = $Panel/InventoryView/InventoryVBox/ItemDescriptionPanel/ItemDescription

@onready var quest_vbox: VBoxContainer = $Panel/QuestContainer/QuestVBox
@onready var quest_scroll: ScrollContainer = $Panel/QuestContainer/QuestVBox/QuestScroll
@onready var quest_list: VBoxContainer = $Panel/QuestContainer/QuestVBox/QuestScroll/QuestList
@onready var quest_row_template: Button = $Panel/QuestContainer/QuestVBox/QuestScroll/QuestList/QuestRowTemplate
@onready var quest_buttons: HBoxContainer = $Panel/QuestContainer/QuestVBox/QuestButtons
@onready var quest_details: Panel = $Panel/QuestContainer/QuestDetails
@onready var quest_details_title: Label = $Panel/QuestContainer/QuestDetails/QuestDetailsVBox/QuestDetailsTitle
@onready var quest_details_text: Label = $Panel/QuestContainer/QuestDetails/QuestDetailsVBox/QuestDetailsText

@onready var fullscren_checkbox_path: CheckBox = $Panel/VBoxOptions/FullscreenCheckBox
@onready var music_value_path: HSlider = $Panel/VBoxOptions/Music/MusicSlider/Slider
@onready var sounds_value_path: HSlider = $Panel/VBoxOptions/Sounds/SoundsSlider/Slider

@onready var anim_on_off: AnimationPlayer = $ScreenFaderAnimation/OnOffScreenFader/AnimationPlayer
@onready var anim_exit: AnimationPlayer = $ScreenFaderAnimation/ExitScreenFader/AnimationPlayer
@onready var anim_phone: AnimationPlayer = $Panel/AnimationPlayer
@onready var anim_blur: AnimationPlayer = $ScreenFaderAnimation/BlurRect/AnimationPlayer

@onready var messenger: Panel = $Panel/Messenger
@onready var tutorial: Panel = $Panel/Tutorial

var menu_open := 0
var loading_settings := true
var _inventory_rows := { }
var _selected_item_id := ""
var _active_quest_rows := { }
var _completed_quest_rows := { }
var _quest_details_source := "active_quests"
var _scroll_states := { }
var completed_quests_overlay: Panel
var completed_quest_vbox: VBoxContainer
var completed_quest_scroll: ScrollContainer
var completed_quest_list: VBoxContainer
var completed_quest_row_template: Button

const VISUAL_NORMAL := Color(1, 1, 1, 1)
const VISUAL_HOVER := Color(0.94, 0.94, 0.94, 1)
const VISUAL_PRESSED := Color(0.82, 0.82, 0.82, 1)

const SCROLL_INVENTORY := "inventory"
const SCROLL_ACTIVE_QUESTS := "active_quests"
const SCROLL_COMPLETED_QUESTS := "completed_quests"
const WHEEL_SCROLL_STEP := 84.0
const DRAG_SCROLL_MULTIPLIER := 1.0
const SCROLL_FOLLOW_SPEED := 14.0
const SCROLL_INERTIA_DAMP := 18.0
const SCROLL_INERTIA_SCALE := 120.0
const SCROLL_INERTIA_CUTOFF := 4.0
const QUEST_DONE_PREFIX := "[x] "
const QUEST_TODO_PREFIX := "[ ] "
const QUEST_STATUS_DONE := "\u0421\u0442\u0430\u0442\u0443\u0441: \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u043e"
const QUEST_STATUS_TODO := "\u0421\u0442\u0430\u0442\u0443\u0441: \u043d\u0435 \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u043e"
const EMPTY_LIST_TEXT := "\u041f\u0443\u0441\u0442\u043e"


func _build_completed_quests_overlay() -> void:
	completed_quests_overlay = Panel.new()
	completed_quests_overlay.name = "CompletedQuestsOverlay"
	completed_quests_overlay.visible = false
	completed_quests_overlay.z_index = 22
	completed_quests_overlay.offset_right = 255.0
	completed_quests_overlay.offset_bottom = 469.0
	quest_view.add_child(completed_quests_overlay)
	quest_view.move_child(completed_quests_overlay, quest_details.get_index())

	completed_quest_vbox = VBoxContainer.new()
	completed_quest_vbox.name = "CompletedQuestVBox"
	completed_quest_vbox.anchor_right = 1.0
	completed_quest_vbox.anchor_bottom = 1.0
	completed_quest_vbox.offset_left = 8.0
	completed_quest_vbox.offset_top = 8.0
	completed_quest_vbox.offset_right = -7.0
	completed_quest_vbox.offset_bottom = -9.0
	completed_quest_vbox.add_theme_constant_override("separation", 8)
	completed_quests_overlay.add_child(completed_quest_vbox)

	var title := Label.new()
	title.name = "CompletedQuestTitle"
	title.add_theme_font_size_override("font_size", 16)
	title.text = "Завершенные задачи"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completed_quest_vbox.add_child(title)

	completed_quest_scroll = ScrollContainer.new()
	completed_quest_scroll.name = "CompletedQuestScroll"
	completed_quest_scroll.custom_minimum_size = Vector2(0, 300)
	completed_quest_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	completed_quest_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	completed_quest_vbox.add_child(completed_quest_scroll)

	completed_quest_list = VBoxContainer.new()
	completed_quest_list.name = "CompletedQuestList"
	completed_quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	completed_quest_list.add_theme_constant_override("separation", 4)
	completed_quest_scroll.add_child(completed_quest_list)

	completed_quest_row_template = quest_row_template.duplicate() as Button
	completed_quest_row_template.name = "CompletedQuestRow_Example"
	completed_quest_row_template.text = "Quest"
	completed_quest_list.add_child(completed_quest_row_template)

	var source_back_button := quest_buttons.get_node("CloseQuest") as Button
	var back_button := Button.new()
	back_button.name = "BackFromCompleted_Quests"
	back_button.process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.text = source_back_button.text
	completed_quest_vbox.add_child(back_button)
	back_button.pressed.connect(_on_back_from_completed_quests_pressed)


func _insert_completed_quests_button() -> void:
	var button := Button.new()
	button.name = "Show_Completed_Quests"
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "Завершенные"
	button.pressed.connect(_on_show_completed_quests_pressed)
	quest_vbox.add_child(button)
	quest_vbox.move_child(button, quest_buttons.get_index())


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscren_checkbox_path.button_pressed)
	config.set_value("audio", "music_volume", music_value_path.value)
	config.set_value("audio", "sounds_volume", sounds_value_path.value)
	config.save(GameManager.SETTINGS_PATH)


func _ready() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscren_checkbox_path.button_pressed = is_full

	visible = false
	pause_menu_ui.visible = false
	inventory_view.visible = false
	quest_vbox.visible = false
	quest_view.visible = false
	menu_options.visible = false
	pause_label.visible = false
	messenger.visible = false
	tutorial.visible = false
	quest_details.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_completed_quests_overlay()
	_insert_completed_quests_button()

	inventory_item_template.visible = false
	inventory_description.visible = false
	quest_row_template.visible = false
	completed_quest_row_template.visible = false

	_register_scroll_area(SCROLL_INVENTORY, inventory_scroll)
	_register_scroll_area(SCROLL_ACTIVE_QUESTS, quest_scroll)
	_register_scroll_area(SCROLL_COMPLETED_QUESTS, completed_quest_scroll)

	if not Inventory.inventory_changed.is_connected(_on_items_inventory_changed):
		Inventory.inventory_changed.connect(_on_items_inventory_changed)

	var config := ConfigFile.new()
	var err := config.load(GameManager.SETTINGS_PATH)
	if err == OK:
		var music: float = config.get_value("audio", "music_volume", 100.0)
		var sound: float = config.get_value("audio", "sounds_volume", 100.0)
		music_value_path.value = music
		sounds_value_path.value = sound

	await get_tree().process_frame
	_refresh_inventory_ui()
	_refresh_quests_ui()
	_apply_settings()
	loading_settings = false


func _process(delta: float) -> void:
	_update_scroll(SCROLL_INVENTORY, delta)
	_update_scroll(SCROLL_ACTIVE_QUESTS, delta)
	_update_scroll(SCROLL_COMPLETED_QUESTS, delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.is_minigame_active:
			if GameManager.minigame_pause_target and GameManager.minigame_pause_target.has_method("toggle_pause_overlay_from_pause_menu"):
				GameManager.minigame_pause_target.call("toggle_pause_overlay_from_pause_menu")
				get_viewport().set_input_as_handled()
			return
		if menu_open == 0:
			menu_open += 1
			toggle()
		else:
			menu_open -= 1
			close_pause_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not inventory_view.visible:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not _is_position_over_inventory_widget(event.global_position):
				_clear_inventory_selection()
	elif event is InputEventScreenTouch:
		if event.pressed and not _is_position_over_inventory_widget(event.position):
			_clear_inventory_selection()


func toggle() -> void:
	pause_menu_ui.visible = true
	inventory_view.visible = false
	quest_view.visible = false
	menu_options.visible = false
	messenger.visible = false
	tutorial.visible = false
	pause_label.visible = true

	anim_blur.play("blur_on")
	anim_phone.play("on_phone")
	anim_on_off.play("open_pause_menu")

	var new_state := !get_tree().paused
	get_tree().paused = new_state
	visible = new_state
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_continue_button_pressed() -> void:
	if menu_open == 1:
		menu_open -= 1
	close_pause_menu()


func _on_options_pressed() -> void:
	pause_menu_ui.visible = false
	inventory_view.visible = false
	quest_view.visible = false
	pause_label.visible = false
	menu_options.visible = true


func _on_quests_pressed() -> void:
	_refresh_quests_ui()
	pause_menu_ui.visible = false
	inventory_view.visible = false
	menu_options.visible = false
	messenger.visible = false
	tutorial.visible = false
	pause_label.visible = false
	quest_view.visible = true
	_show_active_quests_page()


func _on_sounds_value_changed(value: float) -> void:
	var db: float
	if value == 0:
		db = -80
	else:
		db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), db)
	if not loading_settings:
		save_settings()


func _on_music_value_changed(value: float) -> void:
	var db: float
	if value == 0:
		db = -80
	else:
		db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	if not loading_settings:
		save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED,
	)
	if not loading_settings:
		save_settings()


func _apply_settings() -> void:
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
	inventory_view.visible = false
	quest_view.visible = false
	menu_options.visible = false
	pause_label.visible = false
	messenger.visible = false
	tutorial.visible = false
	completed_quests_overlay.visible = false
	quest_details.visible = false
	_cancel_scroll_drag()
	_clear_inventory_selection()


func _on_exit_to_main_menu_pressed() -> void:
	anim_exit.play("exit_to_main_menu")
	await get_tree().create_timer(0.7).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_inventory_pressed() -> void:
	_refresh_inventory_ui()
	pause_menu_ui.visible = false
	quest_view.visible = false
	menu_options.visible = false
	messenger.visible = false
	tutorial.visible = false
	pause_label.visible = false
	inventory_view.visible = true


func _on_back_from_inventory_pressed() -> void:
	inventory_view.visible = false
	pause_menu_ui.visible = true
	pause_label.visible = true
	_clear_inventory_selection()


func _on_back_from_quests_pressed() -> void:
	_show_active_quests_page()
	quest_view.visible = false
	pause_menu_ui.visible = true
	pause_label.visible = true


func _on_back_from_quest_details_pressed() -> void:
	if _quest_details_source == SCROLL_COMPLETED_QUESTS:
		_show_completed_quests_page()
	else:
		_show_active_quests_page()


func _on_show_completed_quests_pressed() -> void:
	_show_completed_quests_page()


func _on_back_from_completed_quests_pressed() -> void:
	_show_active_quests_page()


func _on_messenger_pressed() -> void:
	pause_menu_ui.visible = false
	inventory_view.visible = false
	quest_view.visible = false
	menu_options.visible = false
	pause_label.visible = false
	messenger.visible = true


func _on_tutorial_pressed() -> void:
	pause_menu_ui.visible = false
	inventory_view.visible = false
	quest_view.visible = false
	tutorial.visible = true
	messenger.visible = false
	pause_label.visible = false


func _on_back_from_options_pressed() -> void:
	pause_menu_ui.visible = true
	inventory_view.visible = false
	quest_view.visible = false
	pause_label.visible = true
	menu_options.visible = false


func _on_back_from_messenger_pressed() -> void:
	pause_menu_ui.visible = true
	inventory_view.visible = false
	quest_view.visible = false
	pause_label.visible = true
	messenger.visible = false


func _on_back_from_tutorial_pressed() -> void:
	tutorial.visible = false
	messenger.visible = true


# TODO: добавить диалог выбора слота сохранения в телефоне
func _on_save_pressed() -> void:
	SaveSystem.save_game(SaveSystem.Mode.QUICK)


func _on_load_pressed() -> void:
	toggle()
	SaveSystem.load_game(SaveSystem.Mode.QUICK)


func _on_items_inventory_changed() -> void:
	_refresh_inventory_ui()


func _refresh_inventory_ui() -> void:
	for child in inventory_items_list.get_children():
		if child != inventory_item_template:
			child.queue_free()

	_inventory_rows.clear()
	_clear_inventory_selection()
	
	if Inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = EMPTY_LIST_TEXT
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_items_list.add_child(empty_label)

	for stack in Inventory.contents:
		var row := inventory_item_template.duplicate() as HBoxContainer
		row.visible = true
		row.name = "ItemRow_%s" % stack.item_id

		var icon := row.get_node("ItemIcon") as TextureRect
		var info_block := row.get_node("ItemInfoBlock") as PanelContainer
		var item_name := row.get_node("ItemInfoBlock/ItemInfoHBox/ItemName") as Label
		var item_count_label := row.get_node("ItemInfoBlock/ItemInfoHBox/ItemCount") as Label

		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		info_block.mouse_filter = Control.MOUSE_FILTER_STOP

		var item_info: Dictionary = stack.item.to_dictionary()
		item_name.text = str(item_info.get("display_name", stack.item_id))
		item_count_label.text = "x%d" % stack.count
		icon.texture = _load_item_icon(str(item_info.get("icon_path", "")))

		icon.gui_input.connect(_on_item_cell_gui_input.bind(stack.item_id))
		info_block.gui_input.connect(_on_item_cell_gui_input.bind(stack.item_id))
		icon.mouse_entered.connect(_on_item_hover_entered.bind(stack.item_id))
		info_block.mouse_entered.connect(_on_item_hover_entered.bind(stack.item_id))
		icon.mouse_exited.connect(_on_item_hover_exited.bind(stack.item_id))
		info_block.mouse_exited.connect(_on_item_hover_exited.bind(stack.item_id))

		inventory_items_list.add_child(row)
		_inventory_rows[stack.item_id] = {
			"icon": icon,
			"info": info_block,
			"hovered": false,
			"pressed": false,
		}
		_apply_row_visual(stack.item_id)

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
	for entry in Quests.get_journal_entries():
		has_active_quests = true

		var row := quest_row_template.duplicate() as Button
		row.visible = true
		row.name = "QuestRow_%s" % entry.quest_id
		row.text = _build_quest_row_text(entry)
		row.pressed.connect(_on_quest_row_pressed.bind(entry.quest_id, SCROLL_ACTIVE_QUESTS))
		quest_list.add_child(row)
		_active_quest_rows[entry.quest_id] = row

	if not has_active_quests:
		var empty_label := Label.new()
		empty_label.text = EMPTY_LIST_TEXT
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quest_list.add_child(empty_label)

	_reset_scroll_state(SCROLL_ACTIVE_QUESTS)


# TODO
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


func _build_quest_row_text(entry: Quests.JournalEntry) -> String:
	var prefix := QUEST_DONE_PREFIX if entry.is_completed() else QUEST_TODO_PREFIX
	return prefix + entry.quest.title


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
	var item_info: Dictionary = Inventory.get_item_info(item_id)
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


func _is_position_over_inventory_widget(pos: Vector2) -> bool:
	for state in _inventory_rows.values():
		var icon := state["icon"] as Control
		var info := state["info"] as Control
		if icon.get_global_rect().has_point(pos):
			return true
		if info.get_global_rect().has_point(pos):
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
			float(state["target"]) - event.relative.y * DRAG_SCROLL_MULTIPLIER,
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
			float(state["target"]) - event.relative.y * DRAG_SCROLL_MULTIPLIER,
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
			SCROLL_INERTIA_DAMP * SCROLL_INERTIA_SCALE * delta,
		)
		if absf(float(state["velocity"])) < SCROLL_INERTIA_CUTOFF:
			state["velocity"] = 0.0

	state["target"] = _clamp_scroll_target(scroll_id, float(state["target"]))

	var scroll := state["scroll"] as ScrollContainer
	var current_scroll := float(scroll.scroll_vertical)
	var next_scroll := lerpf(
		current_scroll,
		float(state["target"]),
		minf(1.0, SCROLL_FOLLOW_SPEED * delta),
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
	var state: Dictionary = _scroll_states.get(scroll_id, { })
	var scroll := state.get("scroll", null) as ScrollContainer
	if scroll == null:
		return 0.0

	var scrollbar := scroll.get_v_scroll_bar()
	var max_scroll := maxf(0.0, scrollbar.max_value - scrollbar.page)
	return clampf(value, 0.0, max_scroll)
