extends Control


@onready var title_label: Label = $TitleLabel
@onready var menu_start: VBoxContainer = $Buttons_VBox
@onready var menu_options: MarginContainer = $Options_Menu
<<<<<<< Updated upstream
@export var menu_theme : AudioStream

var loading_settings := true

func _process(_delta: float) -> void:
	pass

func _on_new_game_button_pressed() -> void:
	GameManager.stop_music()
	GameManager.reload("1_morning_quest")
	GameManager.reload("2_mike_room_bed")
	var mom_home_scene = load("res://scenes/mom_home.tscn")
	get_tree().change_scene_to_packed(mom_home_scene)

func _on_options_button_pressed() -> void:
	menu_start.visible = false
	title_label.visible = false
	menu_options.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _play_interact_sound() -> void:
	if not menu_theme.playing:
		menu_theme.play()


#---------------------------------------------------------------------------------------------------
#---------------------------------------НАСТРОЙКИ---------------------------------------------------
#---------------------------------------------------------------------------------------------------


# Переменные к путям данных настроек
=======
>>>>>>> Stashed changes
@onready var fullscren_checkbox_path: CheckBox = $Options_Menu/Options_Menu_VBox/Fullscreen_CheckBox
@onready var music_value_path: HSlider = $Options_Menu/Options_Menu_VBox/Music/Music_slider/music_slider
@onready var sounds_value_path: HSlider = $Options_Menu/Options_Menu_VBox/Sounds/Sounds_slider/sounds_slider

@export var menu_theme: AudioStream

var loading_settings := true
var save_slots_overlay: Panel
var save_slots_list: VBoxContainer


<<<<<<< Updated upstream

#---------------------------------------------------------------------------------------------------
#-------------------------------------ФУНКЦИЯ-READY-------------------------------------------------
#---------------------------------------------------------------------------------------------------


func _ready():
=======
func _ready() -> void:
	_ensure_continue_button()
	_build_save_slots_overlay()
	_update_save_buttons_visibility()
>>>>>>> Stashed changes

	title_label.visible = true
	menu_start.visible = true
	menu_options.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if menu_theme:
		GameManager.play_music(menu_theme)

	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscren_checkbox_path.button_pressed = is_full

	var config := ConfigFile.new()
	var err := config.load(GameManager.SETTINGS_PATH)
	if err == OK:
		var music: float = config.get_value("audio", "music_volume", 100.0)
		var sound: float = config.get_value("audio", "sounds_volume", 100.0)
		music_value_path.value = music
		sounds_value_path.value = sound

	await get_tree().process_frame
	_apply_settings()
	loading_settings = false


func _ensure_continue_button() -> void:
	var continue_button := menu_start.get_node_or_null("Continue") as Button
	if continue_button == null:
		continue_button = Button.new()
		continue_button.name = "Continue"
		continue_button.text = "Продолжить"
		var new_game_button := menu_start.get_node_or_null("New_Game") as Button
		if new_game_button:
			continue_button.add_theme_font_override("font", new_game_button.get_theme_font("font"))
			continue_button.add_theme_font_size_override("font_size", new_game_button.get_theme_font_size("font_size"))
		menu_start.add_child(continue_button)
		menu_start.move_child(continue_button, 1)

	if not continue_button.pressed.is_connected(_on_continue_button_pressed):
		continue_button.pressed.connect(_on_continue_button_pressed)


func _build_save_slots_overlay() -> void:
	save_slots_overlay = Panel.new()
	save_slots_overlay.name = "SaveSlotsOverlay"
	save_slots_overlay.visible = false
	save_slots_overlay.z_index = 20
	save_slots_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	save_slots_overlay.set_anchors_preset(Control.PRESET_CENTER)
	save_slots_overlay.custom_minimum_size = Vector2(430, 360)
	save_slots_overlay.offset_left = -215.0
	save_slots_overlay.offset_top = -180.0
	save_slots_overlay.offset_right = 215.0
	save_slots_overlay.offset_bottom = 180.0
	add_child(save_slots_overlay)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	save_slots_overlay.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Слоты сохранения"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	save_slots_list = VBoxContainer.new()
	save_slots_list.name = "SaveSlotsList"
	save_slots_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	save_slots_list.add_theme_constant_override("separation", 6)
	vbox.add_child(save_slots_list)

	var back_button := Button.new()
	back_button.text = "Назад"
	back_button.pressed.connect(_on_back_from_save_slots_pressed)
	vbox.add_child(back_button)


func _refresh_save_slots_overlay() -> void:
	for child in save_slots_list.get_children():
		child.queue_free()

	for slot_info in SaveSystem.get_save_slot_infos():
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = _build_slot_button_text(slot_info)
		button.disabled = not bool(slot_info["exists"]) or not bool(slot_info["is_valid"])
		if not button.disabled:
			button.pressed.connect(_on_save_slot_pressed.bind(str(slot_info["path"])))
		save_slots_list.add_child(button)


func _build_slot_button_text(slot_info: Dictionary) -> String:
	var title := str(slot_info.get("title", "Слот"))
	if not bool(slot_info.get("exists", false)):
		return "%s - пусто" % title

	var scene_name := str(slot_info.get("scene_name", "Неизвестная сцена"))
	var modified_time := int(slot_info.get("modified_time", 0))
	var date_text := Time.get_datetime_string_from_unix_time(modified_time, true) if modified_time > 0 else ""
	return "%s - %s  %s" % [title, scene_name, date_text]


func _update_save_buttons_visibility() -> void:
	if menu_start == null:
		return

	var has_saves := SaveSystem.save_exists()
	var continue_button := menu_start.get_node_or_null("Continue") as Button
	var load_button := menu_start.get_node_or_null("Load") as Button
	if continue_button:
		continue_button.visible = has_saves
	if load_button:
		load_button.visible = has_saves


func _on_new_game_button_pressed() -> void:
	GameManager.stop_music()
	GameManager.reset_game_state()
	var mom_home_scene = load("res://scenes/mom_home.tscn")
	get_tree().change_scene_to_packed(mom_home_scene)


func _on_continue_button_pressed() -> void:
	GameManager.stop_music()
	SaveSystem.load_game()


func _on_load_button_tree_entered() -> void:
	_update_save_buttons_visibility()


func _on_load_button_pressed() -> void:
	_refresh_save_slots_overlay()
	title_label.visible = false
	menu_start.visible = false
	menu_options.visible = false
	save_slots_overlay.visible = true


func _on_save_slot_pressed(path: String) -> void:
	GameManager.stop_music()
	SaveSystem.load_game_from_file(path)


func _on_back_from_save_slots_pressed() -> void:
	save_slots_overlay.visible = false
	title_label.visible = true
	menu_start.visible = true
	_update_save_buttons_visibility()


func _on_options_button_pressed() -> void:
	menu_start.visible = false
	title_label.visible = false
	save_slots_overlay.visible = false
	menu_options.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _play_interact_sound() -> void:
	if menu_theme and not GameManager.music_player.playing:
		GameManager.play_music(menu_theme)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscren_checkbox_path.button_pressed)
	config.set_value("audio", "music_volume", music_value_path.value)
	config.set_value("audio", "sounds_volume", sounds_value_path.value)
	config.save(GameManager.SETTINGS_PATH)


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
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if not loading_settings:
		save_settings()


func _apply_settings() -> void:
	_on_fullscreen_toggled(fullscren_checkbox_path.button_pressed)
	_on_music_value_changed(music_value_path.value)
	_on_sounds_value_changed(sounds_value_path.value)


func _on_back_pressed() -> void:
	title_label.visible = true
	menu_start.visible = true
	menu_options.visible = false
	save_slots_overlay.visible = false
