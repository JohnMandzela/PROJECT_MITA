extends Control


#---------------------------------------------------------------------------------------------------
#------------------------------------СТАРТОВОЕ-ОКНО-------------------------------------------------
#---------------------------------------------------------------------------------------------------

@onready var title_label = $TitleLabel   # измени на своё имя узла с названием игры
@onready var menu_start: VBoxContainer = $Buttons_VBox
@onready var menu_options: MarginContainer = $Options_Menu
@export var menu_theme : AudioStream

func _process(_delta: float) -> void:
	pass

func _on_new_game_button_pressed() -> void:
	GameManager.stop_music()
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
@onready var fullscren_checkbox_path: CheckBox = $Options_Menu/Options_Menu_VBox/Fullscreen_CheckBox
@onready var music_value_path: HSlider = $Options_Menu/Options_Menu_VBox/Music/Music_slider/music_slider
@onready var sounds_value_path: HSlider = $Options_Menu/Options_Menu_VBox/Sounds/Sounds_slider/sounds_slider


# Сохраняем данные настроек
func save_settings():
	var config = ConfigFile.new()

	config.set_value("video", "fullscreen", fullscren_checkbox_path.button_pressed)
	config.set_value("audio", "music_volume", music_value_path.value)
	config.set_value("audio", "sounds_volume", sounds_value_path.value)

	config.save(GameManager.SETTINGS_PATH)


#---------------------------------------------------------------------------------------------------
#-------------------------------------ФУНКЦИЯ-READY-------------------------------------------------
#---------------------------------------------------------------------------------------------------


func _ready():

#---------------------ДЛЯ-СТАРТА------------------------------------------------
	title_label.visible = true
	menu_start.visible = true
	menu_options.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if menu_theme:
		GameManager.play_music(menu_theme)


#---------------------ДЛЯ-НАСТРОЕК----------------------------------------------

	# Ставим галочку на Fullscreen
	var mode = DisplayServer.window_get_mode()
	var is_full = (mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_FULLSCREEN)

	fullscren_checkbox_path.button_pressed = is_full

	var config = ConfigFile.new()
	var err = config.load(GameManager.SETTINGS_PATH)

	if err == OK:
		var music : float = config.get_value("audio", "music_volume", 0.0)
		var sound : float = config.get_value("audio", "sounds_volume", 0.0)
		music_value_path.value = music
		sounds_value_path.value = sound

	# Загружаем сохранённые значения громкости музыки
	if ProjectSettings.has_setting("game/music_volume"):
		music_value_path.value = ProjectSettings.get_setting("game/music_volume")
	# Загружаем сохранённые значения громкости звуков
	if ProjectSettings.has_setting("game/sounds_volume"):
		sounds_value_path.value = ProjectSettings.get_setting("game/sounds_volume")

	# Применяем всё c задержкой одного кадра
	await get_tree().process_frame
	_apply_settings()


# Сигнал слайдера эффектов
func _on_sounds_value_changed(value):
	var db
	if value == 0:
		db = -80
	else:
		db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), db)
	save_settings()

# Сигнал слайдера музыки
func _on_music_value_changed(value):
	var db
	if value == 0:
		db = -80
	else:
		db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	save_settings()

# Сигнал checkbox
func _on_fullscreen_toggled(pressed):
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed 
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	save_settings()

# Применение всех настроек при запуске сцены
func _apply_settings():
	_on_fullscreen_toggled(fullscren_checkbox_path.button_pressed)
	_on_music_value_changed(music_value_path.value)
	_on_sounds_value_changed(sounds_value_path.value)

# Кнопка "Назад"
func _on_back_pressed():
	title_label.visible = true
	menu_start.visible = true
	menu_options.visible = false
