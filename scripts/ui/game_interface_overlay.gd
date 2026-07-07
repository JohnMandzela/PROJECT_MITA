class_name GameInterfaceOverlay
extends CanvasLayer

signal settings_requested
signal main_menu_requested
signal exit_requested
signal hud_dialogue_finished

const PANEL_COLOR := Color(0.965, 0.96, 0.94, 1.0)
const DOT_COLOR := Color(0.62, 0.62, 0.62, 0.55)
const INK_COLOR := Color(0.08, 0.08, 0.08, 1.0)
const BORDER_COLOR := Color(0.12, 0.12, 0.12, 1.0)
const CENTER_RECT := Rect2(18.0, 22.0, 862.0, 478.0)
const RIGHT_PANEL_RECT := Rect2(880.0, 0.0, 272.0, 648.0)
const INVENTORY_OPEN_HEIGHT := 150.0
const INVENTORY_CLOSED_HEIGHT := 0.0
const SETTINGS_OPEN_HEIGHT := 178.0
const SETTINGS_CLOSED_HEIGHT := 0.0
const INVENTORY_COLUMNS := 4
const INVENTORY_ROWS := 3
const WEBCAM_TEXTURE_PATH := "res://images/characters/Mike_webcam.png"
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

@export_range(0.0, 100.0, 1.0) var vigor := 72.0:
	set(value):
		vigor = clampf(value, 0.0, 100.0)
		_update_status_bars()

@export_range(0.0, 100.0, 1.0) var psyche := 96.0:
	set(value):
		psyche = clampf(value, 0.0, 100.0)
		_update_status_bars()

@export var show_mouse_cursor := true
@export var webcam_texture: Texture2D

var root_control: Control
var dialogue_scroll: ScrollContainer
var dialogue_content: VBoxContainer
var dialogue_label: DialogueLabel
var response_buttons: VBoxContainer
var use_item_button: Button
var active_dialogue_resource: DialogueResource
var active_dialogue_line = null
var active_dialogue_states: Array = []
var active_dialogue_next_id := ""
var is_dialogue_waiting_for_input := false
var vigor_fill: ColorRect
var psyche_fill: ColorRect
var inventory_button: Button
var inventory_drawer: Panel
var inventory_grid: GridContainer
var inventory_cells: Array[PanelContainer] = []
var inventory_cell_items := { }
var selected_item_id := ""
var selected_item_cell: PanelContainer
var inventory_open := false
var inventory_tween: Tween
var settings_button: Button
var settings_drawer: Panel
var fullscreen_checkbox: CheckBox
var Slider: HSlider
var SoundsSlider: HSlider
var settings_open := false
var settings_tween: Tween
var loading_settings := true
var _is_transitioning_to_main_menu := false
var _is_quitting := false
var screen_fader_rect: ColorRect


class DottedPanel:
	extends Control

	var fill_color := Color(0.965, 0.96, 0.94, 1.0)
	var dot_color := Color(0.62, 0.62, 0.62, 0.55)


	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), fill_color, true)
		var step := 24
		for y in range(10, int(size.y), step):
			for x in range(12, int(size.x), step):
				draw_circle(Vector2(x, y), 1.0, dot_color)


func _ready() -> void:
	if webcam_texture == null and ResourceLoader.exists(WEBCAM_TEXTURE_PATH):
		webcam_texture = load(WEBCAM_TEXTURE_PATH)

	_build_overlay()
	_refresh_inventory()
	_update_status_bars()
	_load_settings()
	_apply_settings()
	loading_settings = false
	call_deferred("_apply_mouse_cursor_mode")

	var items := get_node_or_null("/root/Items")
	if items:
		if items.has_signal("inventory_changed") and not items.inventory_changed.is_connected(_refresh_inventory):
			items.inventory_changed.connect(_refresh_inventory)


func _process(_delta: float) -> void:
	if dialogue_label and dialogue_label.is_typing:
		_scroll_dialogue_to_bottom()


func set_dialogue_text(text: String) -> void:
	_stop_dialogue()
	if dialogue_label:
		dialogue_label.text = text
		dialogue_label.visible_characters = -1
		_clear_dialogue_responses()
		call_deferred("_scroll_dialogue_to_bottom")


func clear_dialogue_text() -> void:
	if dialogue_label:
		dialogue_label.text = ""
		_clear_dialogue_responses()


func set_vigor(value: float) -> void:
	vigor = value


func set_psyche(value: float) -> void:
	psyche = value


func start_dialogue(resource: DialogueResource, title: String = "", extra_game_states: Array = []) -> void:
	if resource == null:
		return

	_clear_item_selection()
	active_dialogue_resource = resource
	active_dialogue_states = [self] + extra_game_states
	active_dialogue_next_id = title
	GameManager.disable_movement = true
	await _show_next_dialogue_line(active_dialogue_next_id)


func _show_next_dialogue_line(next_id: String) -> void:
	if active_dialogue_resource == null:
		return

	active_dialogue_line = await active_dialogue_resource.get_next_dialogue_line(next_id, active_dialogue_states)
	if active_dialogue_line == null:
		_stop_dialogue()
		clear_dialogue_text()
		GameManager.disable_movement = false
		hud_dialogue_finished.emit()
		return

	is_dialogue_waiting_for_input = false
	active_dialogue_next_id = active_dialogue_line.next_id
	_clear_dialogue_responses()
	use_item_button.visible = false

	dialogue_label.dialogue_line = active_dialogue_line
	dialogue_label.type_out()
	call_deferred("_scroll_dialogue_to_bottom")


func _stop_dialogue() -> void:
	active_dialogue_resource = null
	active_dialogue_line = null
	active_dialogue_states.clear()
	active_dialogue_next_id = ""
	is_dialogue_waiting_for_input = false
	_clear_dialogue_responses()


func _on_dialogue_finished_typing() -> void:
	_scroll_dialogue_to_bottom()
	if active_dialogue_line == null:
		return
	if not active_dialogue_line.responses.is_empty():
		_show_dialogue_responses(active_dialogue_line.responses)
		return
	is_dialogue_waiting_for_input = true


func _on_dialogue_spoke(_letter: String, _letter_index: int, _speed: float) -> void:
	_scroll_dialogue_to_bottom()


func _on_dialogue_window_gui_input(event: InputEvent) -> void:
	if active_dialogue_line == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if dialogue_label.is_typing:
			dialogue_label.skip_typing()
			get_viewport().set_input_as_handled()
			return
		if is_dialogue_waiting_for_input and active_dialogue_line.responses.is_empty():
			_show_next_dialogue_line(active_dialogue_next_id)
			get_viewport().set_input_as_handled()


func _show_dialogue_responses(responses: Array) -> void:
	_clear_dialogue_responses()
	response_buttons.visible = true
	for response in responses:
		if not response.is_allowed:
			continue
		var button := Button.new()
		button.text = response.text
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		_apply_hover_darken_button_theme(button)
		button.pressed.connect(_on_dialogue_response_pressed.bind(response))
		response_buttons.add_child(button)
	call_deferred("_scroll_dialogue_to_bottom")


func _clear_dialogue_responses() -> void:
	if response_buttons == null:
		return
	for child in response_buttons.get_children():
		child.queue_free()
	response_buttons.visible = false


func _on_dialogue_response_pressed(response) -> void:
	_clear_dialogue_responses()
	_show_next_dialogue_line(response.next_id)


func _scroll_dialogue_to_bottom() -> void:
	if dialogue_scroll == null:
		return
	await get_tree().process_frame
	var scrollbar := dialogue_scroll.get_v_scroll_bar()
	scrollbar.value = scrollbar.max_value


func _apply_mouse_cursor_mode() -> void:
	if show_mouse_cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event: InputEvent) -> void:
	if selected_item_id.is_empty():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not _is_selection_click_position(event.position):
				_clear_item_selection()


func _is_selection_click_position(position: Vector2) -> bool:
	if selected_item_cell and is_instance_valid(selected_item_cell):
		if selected_item_cell.get_global_rect().has_point(position):
			return true
	if use_item_button and use_item_button.visible:
		if use_item_button.get_global_rect().has_point(position):
			return true
	return false


func _build_overlay() -> void:
	root_control = Control.new()
	root_control.name = "OverlayRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	#root_control.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root_control)

	_add_band("TopPanel", Rect2(0.0, 0.0, 880.0, CENTER_RECT.position.y))
	_add_band("LeftPanel", Rect2(0.0, CENTER_RECT.position.y, CENTER_RECT.position.x, CENTER_RECT.size.y))

	var bottom_panel := _add_band("BottomPanel", Rect2(0.0, CENTER_RECT.end.y, 880.0, 148.0))
	_build_dialogue_area(bottom_panel)

	var right_panel := _add_band("RightPanel", RIGHT_PANEL_RECT)
	_build_right_panel(right_panel)

	_add_frame(CENTER_RECT)
	_add_vertical_separator(RIGHT_PANEL_RECT.position.x)
	_build_screen_fader()


func _add_band(node_name: String, rect: Rect2) -> DottedPanel:
	var panel := DottedPanel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	#panel.mouse_filter = Control.MOUSE_FILTER_PASS
	root_control.add_child(panel)
	return panel


func _build_dialogue_area(parent: Control) -> void:
	dialogue_scroll = ScrollContainer.new()
	dialogue_scroll.name = "DialogueScroll"
	dialogue_scroll.position = Vector2(226.0, 18.0)
	dialogue_scroll.size = Vector2(610.0, 110.0)
	dialogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialogue_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	dialogue_scroll.gui_input.connect(_on_dialogue_window_gui_input)
	parent.add_child(dialogue_scroll)

	dialogue_content = VBoxContainer.new()
	dialogue_content.name = "DialogueContent"
	dialogue_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_content.add_theme_constant_override("separation", 8)
	dialogue_scroll.add_child(dialogue_content)

	dialogue_label = DialogueLabel.new()
	dialogue_label.name = "DialogueLabel"
	dialogue_label.bbcode_enabled = true
	dialogue_label.fit_content = true
	dialogue_label.scroll_active = false
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_label.custom_minimum_size = Vector2(590.0, 0.0)
	dialogue_label.seconds_per_step = 0.015
	dialogue_label.add_theme_color_override("default_color", INK_COLOR)
	dialogue_label.add_theme_font_size_override("normal_font_size", 18)
	dialogue_label.finished_typing.connect(_on_dialogue_finished_typing)
	dialogue_label.spoke.connect(_on_dialogue_spoke)
	dialogue_content.add_child(dialogue_label)

	response_buttons = VBoxContainer.new()
	response_buttons.name = "Responses"
	response_buttons.visible = false
	response_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	response_buttons.add_theme_constant_override("separation", 5)
	dialogue_content.add_child(response_buttons)

	use_item_button = Button.new()
	use_item_button.name = "UseItemButton"
	use_item_button.position = Vector2(740.0, 58.0)
	use_item_button.size = Vector2(108.0, 32.0)
	use_item_button.text = "Использовать"
	use_item_button.visible = false
	use_item_button.focus_mode = Control.FOCUS_NONE
	use_item_button.add_theme_font_size_override("font_size", 14)
	_apply_hover_darken_button_theme(use_item_button)
	use_item_button.pressed.connect(_on_use_item_pressed)
	parent.add_child(use_item_button)


func _build_right_panel(parent: Control) -> void:
	_build_status_bar(parent, "VigorBar", "Бодрость", Vector2(8.0, 22.0), Color(0.74, 0.0, 0.0, 1.0))
	_build_status_bar(parent, "PsycheBar", "Психика", Vector2(8.0, 60.0), Color(0.48, 0.39, 0.88, 1.0))

	var webcam_frame := Panel.new()
	webcam_frame.name = "WebcamFrame"
	webcam_frame.position = Vector2(8.0, 110.0)
	webcam_frame.size = Vector2(244.0, 194.0)
	webcam_frame.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 1), BORDER_COLOR, 4))
	parent.add_child(webcam_frame)

	var webcam := TextureRect.new()
	webcam.name = "MikeWebcam"
	webcam.position = Vector2(6.0, 6.0)
	webcam.size = Vector2(232.0, 182.0)
	webcam.texture = webcam_texture
	webcam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	webcam.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	#webcam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	webcam_frame.add_child(webcam)

	_build_inventory(parent)
	_build_system_status(parent)
	_build_settings_drawer(parent)
	_build_system_buttons(parent)


func _build_status_bar(parent: Control, node_name: String, label_text: String, position: Vector2, color: Color) -> void:
	var track := Panel.new()
	track.name = node_name
	track.position = position
	track.size = Vector2(244.0, 14.0)
	track.add_theme_stylebox_override("panel", _style(Color(0.02, 0.02, 0.02, 1.0), BORDER_COLOR, 1))
	parent.add_child(track)

	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.position = Vector2(2.0, 2.0)
	fill.size = Vector2(240.0, 10.0)
	fill.color = color
	#fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)

	if node_name == "VigorBar":
		vigor_fill = fill
	else:
		psyche_fill = fill

	var label := Label.new()
	label.name = node_name + "Label"
	label.position = position + Vector2(0.0, 14.0)
	label.size = Vector2(244.0, 24.0)
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", INK_COLOR)
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)


func _build_inventory(parent: Control) -> void:
	var header := Panel.new()
	header.name = "InventoryHeader"
	header.position = Vector2(6.0, 316.0)
	header.size = Vector2(248.0, 28.0)
	header.add_theme_stylebox_override("panel", _style(Color(0.98, 0.98, 0.96, 1.0), Color(0.58, 0.58, 0.58, 1.0), 1))
	parent.add_child(header)

	inventory_button = Button.new()
	inventory_button.name = "InventoryButton"
	inventory_button.position = Vector2.ZERO
	inventory_button.size = header.size
	inventory_button.text = "Инвентарь"
	inventory_button.focus_mode = Control.FOCUS_NONE
	inventory_button.add_theme_font_size_override("font_size", 15)
	_apply_inventory_button_theme(inventory_button)
	inventory_button.pressed.connect(_toggle_inventory)
	header.add_child(inventory_button)

	var led := Panel.new()
	led.name = "InventoryLed"
	led.position = Vector2(230.0, 7.0)
	led.size = Vector2(14.0, 14.0)
	led.add_theme_stylebox_override("panel", _style(Color(1.0, 0.32, 0.32, 1.0), Color(0.72, 0.18, 0.18, 1.0), 1, 7))
	header.add_child(led)

	inventory_drawer = Panel.new()
	inventory_drawer.name = "InventoryDrawer"
	inventory_drawer.position = Vector2(8.0, 344.0)
	inventory_drawer.size = Vector2(244.0, INVENTORY_CLOSED_HEIGHT)
	inventory_drawer.visible = false
	inventory_drawer.clip_contents = true
	inventory_drawer.add_theme_stylebox_override("panel", _style(Color(0.94, 0.94, 0.91, 1.0), BORDER_COLOR, 2))
	parent.add_child(inventory_drawer)

	var tray_line := ColorRect.new()
	tray_line.name = "DriveSlot"
	tray_line.position = Vector2(12.0, 8.0)
	tray_line.size = Vector2(220.0, 3.0)
	tray_line.color = Color(0.2, 0.2, 0.2, 1.0)
	inventory_drawer.add_child(tray_line)

	inventory_grid = GridContainer.new()
	inventory_grid.name = "InventoryGrid"
	inventory_grid.columns = INVENTORY_COLUMNS
	inventory_grid.position = Vector2(12.0, 20.0)
	inventory_grid.size = Vector2(220.0, 118.0)
	inventory_grid.add_theme_constant_override("h_separation", 7)
	inventory_grid.add_theme_constant_override("v_separation", 7)
	inventory_drawer.add_child(inventory_grid)

	for index in range(INVENTORY_COLUMNS * INVENTORY_ROWS):
		var cell := PanelContainer.new()
		cell.name = "ItemCell_%02d" % index
		cell.custom_minimum_size = Vector2(49.0, 34.0)
		cell.add_theme_stylebox_override("panel", _style(Color(0.99, 0.99, 0.97, 1.0), Color(0.66, 0.66, 0.66, 1.0), 1))
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		cell.gui_input.connect(_on_inventory_cell_gui_input.bind(cell))
		inventory_grid.add_child(cell)
		inventory_cells.append(cell)


func _build_system_status(parent: Control) -> void:
	var status_panel := Panel.new()
	status_panel.name = "SystemStatus"
	status_panel.position = Vector2(8.0, 508.0)
	status_panel.size = Vector2(244.0, 66.0)
	status_panel.add_theme_stylebox_override("panel", _style(Color(0.98, 0.98, 0.96, 1.0), Color(0.43, 0.72, 0.51, 1.0), 1))
	parent.add_child(status_panel)

	var status_text := Label.new()
	status_text.name = "SystemStatusText"
	status_text.position = Vector2(6.0, 14.0)
	status_text.size = Vector2(232.0, 40.0)
	status_text.text = "Вирусов в системе не обнаружено."
	status_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_text.add_theme_color_override("font_color", INK_COLOR)
	status_text.add_theme_font_size_override("font_size", 11)
	status_panel.add_child(status_text)


func _build_settings_drawer(parent: Control) -> void:
	settings_drawer = Panel.new()
	settings_drawer.name = "SettingsDrawer"
	settings_drawer.position = Vector2(8.0, 596.0)
	settings_drawer.size = Vector2(244.0, SETTINGS_CLOSED_HEIGHT)
	settings_drawer.visible = false
	settings_drawer.clip_contents = true
	settings_drawer.add_theme_stylebox_override("panel", _style(Color(0.94, 0.94, 0.91, 1.0), BORDER_COLOR, 2))
	parent.add_child(settings_drawer)

	var margin := MarginContainer.new()
	margin.name = "SettingsMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	settings_drawer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "SettingsVBox"
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "SettingsTitle"
	title.text = "Настройки"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", INK_COLOR)
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	fullscreen_checkbox = CheckBox.new()
	fullscreen_checkbox.name = "FullscreenCheckBox"
	fullscreen_checkbox.text = "Полный экран"
	fullscreen_checkbox.focus_mode = Control.FOCUS_NONE
	fullscreen_checkbox.add_theme_color_override("font_color", INK_COLOR)
	fullscreen_checkbox.add_theme_color_override("font_hover_color", INK_COLOR)
	fullscreen_checkbox.add_theme_color_override("font_pressed_color", INK_COLOR)
	fullscreen_checkbox.add_theme_color_override("font_focus_color", INK_COLOR)
	fullscreen_checkbox.add_theme_font_size_override("font_size", 12)
	_apply_hover_darken_button_theme(fullscreen_checkbox)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(fullscreen_checkbox)

	Slider = _add_settings_slider(vbox, "Музыка")
	Slider.value_changed.connect(_on_music_value_changed)
	SoundsSlider = _add_settings_slider(vbox, "Звуки")
	SoundsSlider.value_changed.connect(_on_sounds_value_changed)


func _add_settings_slider(parent: VBoxContainer, label_text: String) -> HSlider:
	var block := VBoxContainer.new()
	block.name = label_text + "Block"
	block.add_theme_constant_override("separation", 2)
	parent.add_child(block)

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", INK_COLOR)
	label.add_theme_font_size_override("font_size", 11)
	block.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = 100.0
	slider.custom_minimum_size = Vector2(0.0, 18.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_child(slider)
	return slider


func _build_system_buttons(parent: Control) -> void:
	var labels := ["S", "M", "X"]
	var tooltips := ["Настройки", "Главное меню", "Выход"]
	var callbacks := [
		Callable(self, "_on_settings_pressed"),
		Callable(self, "_on_main_menu_pressed"),
		Callable(self, "_on_exit_pressed"),
	]
	for index in range(labels.size()):
		var button := Button.new()
		button.name = ["SettingsButton", "MainMenuButton", "ExitButton"][index]
		button.position = Vector2(10.0 + float(index) * 50.0, 600.0)
		button.size = Vector2(32.0, 32.0)
		button.text = labels[index]
		button.tooltip_text = tooltips[index]
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 15)
		_apply_hover_darken_button_theme(button)
		button.pressed.connect(callbacks[index])
		parent.add_child(button)
		if index == 0:
			settings_button = button


func _build_screen_fader() -> void:
	screen_fader_rect = ColorRect.new()
	screen_fader_rect.name = "ScreenFader"
	screen_fader_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_fader_rect.color = Color(0, 0, 0, 0)
	screen_fader_rect.visible = false
	screen_fader_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(screen_fader_rect)


func _add_frame(rect: Rect2) -> void:
	_add_line(Rect2(rect.position.x, rect.position.y, rect.size.x, 2.0), BORDER_COLOR)
	_add_line(Rect2(rect.position.x, rect.end.y - 2.0, rect.size.x, 2.0), BORDER_COLOR)
	_add_line(Rect2(rect.position.x, rect.position.y, 2.0, rect.size.y), BORDER_COLOR)
	_add_line(Rect2(rect.end.x - 2.0, rect.position.y, 2.0, rect.size.y), BORDER_COLOR)


func _add_vertical_separator(x_position: float) -> void:
	_add_line(Rect2(x_position - 2.0, 0.0, 2.0, 648.0), Color(0.45, 0.45, 0.45, 1.0))


func _add_line(rect: Rect2, color: Color) -> void:
	var line := ColorRect.new()
	line.name = "FrameLine"
	line.position = rect.position
	line.size = rect.size
	line.color = color
	#line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(line)


func _toggle_inventory() -> void:
	set_inventory_open(not inventory_open)


func set_inventory_open(open: bool) -> void:
	if open:
		set_settings_open(false)
	else:
		_clear_item_selection()

	inventory_open = open
	if inventory_tween and inventory_tween.is_running():
		inventory_tween.kill()

	inventory_drawer.visible = true
	var target_height := INVENTORY_OPEN_HEIGHT if inventory_open else INVENTORY_CLOSED_HEIGHT
	inventory_tween = create_tween()
	inventory_tween.set_trans(Tween.TRANS_BACK)
	inventory_tween.set_ease(Tween.EASE_OUT)
	inventory_tween.tween_property(inventory_drawer, "size:y", target_height, 0.22)
	if not inventory_open:
		inventory_tween.tween_callback(func(): inventory_drawer.visible = false)


func _toggle_settings() -> void:
	set_settings_open(not settings_open)


func set_settings_open(open: bool) -> void:
	if open:
		set_inventory_open(false)

	settings_open = open
	if settings_tween and settings_tween.is_running():
		settings_tween.kill()

	settings_drawer.visible = true
	var target_height := SETTINGS_OPEN_HEIGHT if settings_open else SETTINGS_CLOSED_HEIGHT
	var target_y := 596.0 - target_height
	settings_tween = create_tween()
	settings_tween.set_parallel(true)
	settings_tween.set_trans(Tween.TRANS_BACK)
	settings_tween.set_ease(Tween.EASE_OUT)
	settings_tween.tween_property(settings_drawer, "position:y", target_y, 0.22)
	settings_tween.tween_property(settings_drawer, "size:y", target_height, 0.22)
	settings_tween.set_parallel(false)
	if not settings_open:
		settings_tween.tween_callback(func(): settings_drawer.visible = false)


func _refresh_inventory() -> void:
	if inventory_cells.is_empty():
		return

	for cell in inventory_cells:
		for child in cell.get_children():
			child.queue_free()
		cell.add_theme_stylebox_override("panel", _style(Color(0.99, 0.99, 0.97, 1.0), Color(0.66, 0.66, 0.66, 1.0), 1))

	inventory_cell_items.clear()
	var item_ids: Array[String] = []
	var items_node := get_node_or_null("/root/Items")
	if items_node:
		for item_id in items_node.call("get_ordered_item_ids"):
			if int(items_node.get("items_inventory").get(item_id, 0)) > 0:
				item_ids.append(str(item_id))

	for index in range(min(item_ids.size(), inventory_cells.size())):
		_fill_inventory_cell(inventory_cells[index], item_ids[index], items_node)


func _fill_inventory_cell(cell: PanelContainer, item_id: String, items_node: Node) -> void:
	var item_info: Dictionary = items_node.call("get_item_info", item_id)
	var count := int(items_node.get("items_inventory").get(item_id, 0))
	inventory_cell_items[cell] = item_id
	cell.tooltip_text = str(item_info.get("display_name", item_id))

	var content := VBoxContainer.new()
	content.name = "ItemContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(content)

	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.custom_minimum_size = Vector2(24.0, 20.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_path := str(item_info.get("icon_path", ""))
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	content.add_child(icon)

	var count_label := Label.new()
	count_label.name = "ItemCount"
	count_label.text = "x%d" % count
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.add_theme_color_override("font_color", INK_COLOR)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(count_label)


func _on_inventory_cell_gui_input(event: InputEvent, cell: PanelContainer) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if inventory_cell_items.has(cell):
				_select_inventory_item(str(inventory_cell_items[cell]), cell)


func _select_inventory_item(item_id: String, cell: PanelContainer) -> void:
	_stop_dialogue()
	selected_item_id = item_id
	selected_item_cell = cell

	for inventory_cell in inventory_cells:
		inventory_cell.add_theme_stylebox_override("panel", _style(Color(0.99, 0.99, 0.97, 1.0), Color(0.66, 0.66, 0.66, 1.0), 1))
	cell.add_theme_stylebox_override("panel", _style(Color(0.92, 0.94, 0.98, 1.0), Color(0.18, 0.28, 0.42, 1.0), 2))

	var items_node := get_node_or_null("/root/Items")
	if items_node == null:
		return

	var item_info: Dictionary = items_node.call("get_item_info", item_id)
	var title := str(item_info.get("display_name", item_id))
	var description := _get_item_description(item_id, item_info)
	var action := str(item_info.get("action", "Действие пока не назначено."))
	set_dialogue_text("[b]%s[/b]\n%s\n%s" % [title, description, action])
	use_item_button.text = str(item_info.get("use_text", "Использовать"))
	if use_item_button.text.is_empty():
		use_item_button.text = "Использовать"
	use_item_button.visible = _can_use_item(item_id)


func _clear_item_selection() -> void:
	selected_item_id = ""
	selected_item_cell = null
	for inventory_cell in inventory_cells:
		inventory_cell.add_theme_stylebox_override("panel", _style(Color(0.99, 0.99, 0.97, 1.0), Color(0.66, 0.66, 0.66, 1.0), 1))
	if dialogue_label:
		dialogue_label.text = ""
		_clear_dialogue_responses()
	if use_item_button:
		use_item_button.visible = false


func _get_item_description(item_id: String, item_info: Dictionary) -> String:
	return str(item_info.get("description", "Описание предмета пока не добавлено."))


func _can_use_item(item_id: String) -> bool:
	var items_node := get_node_or_null("/root/Items")
	if items_node == null:
		return false
	var item_info: Dictionary = items_node.call("get_item_info", item_id)
	return not Dictionary(item_info.get("use_effects", { })).is_empty()


func _on_use_item_pressed() -> void:
	if selected_item_id.is_empty():
		return

	var items_node := get_node_or_null("/root/Items")
	if items_node == null:
		return

	var item_info: Dictionary = items_node.call("get_item_info", selected_item_id)
	var effects := Dictionary(item_info.get("use_effects", { }))
	var vigor_bonus := float(effects.get("vigor", 0.0))
	if vigor_bonus != 0.0:
		vigor = vigor + vigor_bonus

	if items_node and items_node.has_method("item_was_dropped"):
		items_node.call("item_was_dropped", selected_item_id)

	var item_name := str(item_info.get("display_name", selected_item_id))
	set_dialogue_text("%s использован. Бодрость +%d." % [item_name, int(vigor_bonus)])
	use_item_button.visible = false
	selected_item_id = ""
	selected_item_cell = null


func _update_status_bars() -> void:
	if vigor_fill:
		vigor_fill.size.x = 240.0 * (vigor / 100.0)
	if psyche_fill:
		psyche_fill.size.x = 240.0 * (psyche / 100.0)


func _on_settings_pressed() -> void:
	settings_requested.emit()
	_toggle_settings()


func _load_settings() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_checkbox.button_pressed = is_fullscreen

	var config := ConfigFile.new()
	var err := config.load(GameManager.SETTINGS_PATH)
	if err == OK:
		Slider.value = float(config.get_value("audio", "music_volume", 100.0))
		SoundsSlider.value = float(config.get_value("audio", "sounds_volume", 100.0))
	else:
		Slider.value = 100.0
		SoundsSlider.value = 100.0


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscreen_checkbox.button_pressed)
	config.set_value("audio", "music_volume", Slider.value)
	config.set_value("audio", "sounds_volume", SoundsSlider.value)
	config.save(GameManager.SETTINGS_PATH)


func _apply_settings() -> void:
	_apply_fullscreen(fullscreen_checkbox.button_pressed)
	_apply_bus_volume("Music", Slider.value)
	_apply_bus_volume("Sounds", SoundsSlider.value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	_apply_fullscreen(pressed)
	if not loading_settings:
		_save_settings()


func _on_music_value_changed(value: float) -> void:
	_apply_bus_volume("Music", value)
	if not loading_settings:
		_save_settings()


func _on_sounds_value_changed(value: float) -> void:
	_apply_bus_volume("Sounds", value)
	if not loading_settings:
		_save_settings()


func _apply_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED,
	)


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	var db := -80.0 if value <= 0.0 else linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(bus_index, db)


func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
	if _is_transitioning_to_main_menu:
		return

	_is_transitioning_to_main_menu = true
	set_inventory_open(false)
	GameManager.disable_movement = true
	GameManager.is_minigame_active = false
	GameManager.minigame_pause_target = null

	await _play_screen_fader()

	get_tree().paused = false
	GameManager.player = null
	get_tree().call_deferred("change_scene_to_file", MAIN_MENU_PATH)


func _on_exit_pressed() -> void:
	exit_requested.emit()
	if _is_quitting:
		return

	_is_quitting = true
	set_inventory_open(false)
	await _play_screen_fader()
	get_tree().quit()


func _apply_inventory_button_theme(button: Button) -> void:
	var empty_style := _style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0)
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", _style(Color(0, 0, 0, 0.08), Color(0, 0, 0, 0), 0))
	button.add_theme_stylebox_override("pressed", _style(Color(0, 0, 0, 0.14), Color(0, 0, 0, 0), 0))
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_color_override("font_color", INK_COLOR)
	button.add_theme_color_override("font_hover_color", INK_COLOR)
	button.add_theme_color_override("font_pressed_color", INK_COLOR)
	button.add_theme_color_override("font_focus_color", INK_COLOR)


func _apply_hover_darken_button_theme(button: BaseButton) -> void:
	var normal := _style(Color(0.98, 0.98, 0.96, 1.0), Color(0.58, 0.58, 0.58, 1.0), 1)
	var hover := _style(Color(0.88, 0.88, 0.84, 1.0), Color(0.42, 0.42, 0.42, 1.0), 1)
	var pressed := _style(Color(0.78, 0.78, 0.74, 1.0), Color(0.28, 0.28, 0.28, 1.0), 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", INK_COLOR)
	button.add_theme_color_override("font_hover_color", INK_COLOR)
	button.add_theme_color_override("font_pressed_color", INK_COLOR)
	button.add_theme_color_override("font_focus_color", INK_COLOR)


func _play_screen_fader() -> void:
	if screen_fader_rect == null:
		return

	screen_fader_rect.visible = true
	screen_fader_rect.color = Color(0, 0, 0, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(screen_fader_rect, "color", Color(0, 0, 0, 1), 0.7)
	await tween.finished


func _style(bg_color: Color, border_color: Color, border_width: int = 1, corner_radius: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	return style
