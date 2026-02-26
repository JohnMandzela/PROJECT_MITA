extends Control

# Сохраняем данные настроек
func save_settings():
	var config = ConfigFile.new()

	config.set_value("video", "fullscreen", 
		$Options_Menu/Options_Menu_VBox/Fullscreen_CheckBox.button_pressed)

	config.set_value("audio", "music_volume", 
		$Options_Menu/Options_Menu_VBox/Music/music_slider.value)

	config.set_value("audio", "sounds_volume", 
		$Options_Menu/Options_Menu_VBox/Sounds/sounds_slider.value)

	config.save(GameManager.SETTINGS_PATH)


func _ready():
	# Ставим галочку на Fullscreen
	var mode = DisplayServer.window_get_mode()
	var is_full = (mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_FULLSCREEN)

	$Options_Menu/Options_Menu_VBox/Fullscreen_CheckBox.button_pressed = is_full

	# Загружаем сохранённые значения громкости
	if ProjectSettings.has_setting("game/music_volume"):
		$Options_Menu/Options_Menu_VBox/Music/music_slider.value = ProjectSettings.get_setting("game/music_volume")
	if ProjectSettings.has_setting("game/sounds_volume"):
		$Options_Menu/Options_Menu_VBox/Sounds/sounds_slider.value = ProjectSettings.get_setting("game/sounds_volume")

	# Применяем всё c задержкой одного кадра
	await get_tree().process_frame
	_apply_settings()


# Сигнал слайдера эффектов
func _on_sounds_value_changed(value):
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), linear_to_db(value / 100.0))
	#ProjectSettings.set_setting("game/sounds_volume", value)
	pass

# Сигнал слайдера музыки
func _on_music_value_changed(value):
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value / 100.0))
	#ProjectSettings.set_setting("game/music_volume", value)
	pass

func _on_mouse_sensitivity_value_changed(value):
	pass

# Сигнал checkbox
func _on_fullscreen_toggled(pressed):
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed 
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	save_settings()

# Применение всех настроек при запуске сцены
func _apply_settings():
	_on_fullscreen_toggled($Options_Menu/Options_Menu_VBox/Fullscreen_CheckBox.button_pressed)
	_on_music_value_changed($Options_Menu/Options_Menu_VBox/Music/music_slider.value)
	_on_sounds_value_changed($Options_Menu/Options_Menu_VBox/Sounds/sounds_slider.value)
	_on_mouse_sensitivity_value_changed($Options_Menu/Options_Menu_VBox/Mouse_Sensivity/mouse_sensitivity_slider.value)

# Кнопка "Назад"
func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
