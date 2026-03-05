extends Control


#---------------------------------------------------------------------------------------------------
#------------------------------------ГЛИТЧ-ЭФФЕКТЫ--------------------------------------------------
#---------------------------------------------------------------------------------------------------


@onready var vbox = $Buttons_VBox
@onready var title_label = $TitleLabel   # измени на своё имя узла с названием игры

# Настройки глитча
var glitch_duration := 0.15               # длительность глитча (сек)
var glitch_steps := 4                     # количество микро-смещений
var glitch_intensity_rotation := 5.0      # макс. угол поворота (градусы)
var glitch_scale_intensity := 0.05        # изменение масштаба (±5%)
var glitch_color_intensity := 0.8         # интенсивность цветовых искажений
var glitch_interval := 3.0                # интервал между случайными глитчами (сек)

var glitch_elements := []                  # все элементы, подлежащие глитчу
var original_rotations = {}
var original_scales = {}
var original_colors = {}
var tween: Tween
var timer: Timer


func _on_glitch_timer():
	glitch_all()

func glitch_all():
	for element in glitch_elements:
		glitch_element(element)

func glitch_element(element: Control):
	if not element in original_rotations:
		return
	
	var glitch_tween = create_tween().set_parallel(false)
	
	var original_rot = original_rotations[element]
	var original_scale = original_scales[element]
	var original_color = original_colors[element]
	
	var step_time = glitch_duration / glitch_steps
	
	for i in range(glitch_steps):
		# Поворот
		var new_rot = original_rot + randf_range(-glitch_intensity_rotation, glitch_intensity_rotation)
		
		# Масштаб (равномерный)
		var scale_factor = 1.0 + randf_range(-glitch_scale_intensity, glitch_scale_intensity)
		var new_scale = original_scale * scale_factor
		
		# Цветовые искажения
		var r = original_color.r * randf_range(1.0 - glitch_color_intensity, 1.0 + glitch_color_intensity)
		var g = original_color.g * randf_range(1.0 - glitch_color_intensity, 1.0 + glitch_color_intensity)
		var b = original_color.b * randf_range(1.0 - glitch_color_intensity, 1.0 + glitch_color_intensity)
		var new_color = Color(r, g, b, original_color.a)
		
		glitch_tween.tween_property(element, "rotation_degrees", new_rot, step_time)
		glitch_tween.parallel().tween_property(element, "scale", new_scale, step_time)
		glitch_tween.parallel().tween_property(element, "modulate", new_color, step_time)
	
	# Возврат в исходное состояние
	glitch_tween.tween_property(element, "rotation_degrees", original_rot, step_time)
	glitch_tween.parallel().tween_property(element, "scale", original_scale, step_time)
	glitch_tween.parallel().tween_property(element, "modulate", original_color, step_time)

# Обработка наведения мыши
func _on_button_mouse_entered(element: Control):
	glitch_element(element)

func _on_button_mouse_exited(element: Control):
	pass  # можно добавить эффект при уходе, если нужно


#---------------------------------------------------------------------------------------------------
#------------------------------------СТАРТОВОЕ-ОКНО-------------------------------------------------
#---------------------------------------------------------------------------------------------------


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
	menu_start.visible = true
	menu_options.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if menu_theme:
		GameManager.play_music(menu_theme)

#------------------ДЛЯ-ГЛИТЧ-АНИМАЦИИ-------------------------------------------

	# Собираем все кнопки из VBoxContainer
	for child in vbox.get_children():
		if child is Button:
			glitch_elements.append(child)
	
	# Добавляем заголовок, если он существует
	if title_label:
		glitch_elements.append(title_label)
	
	# Устанавливаем точку поворота в центр и сохраняем исходные значения
	for element in glitch_elements:
		# Ждём один кадр, чтобы размеры элемента стали известны
		await get_tree().process_frame
		if element is Control:
			element.pivot_offset = element.size / 2
		
		original_rotations[element] = element.rotation_degrees
		original_scales[element] = element.scale
		original_colors[element] = element.modulate
	
	# Таймер для фонового глитча (можно отключить, убрав следующие строки)
	timer = Timer.new()
	timer.wait_time = glitch_interval
	timer.timeout.connect(_on_glitch_timer)
	add_child(timer)
	timer.start()
	
	# Подключаем сигналы наведения для кнопок
	for element in glitch_elements:
		if element is Button:
			if not element.mouse_entered.is_connected(_on_button_mouse_entered.bind(element)):
				element.mouse_entered.connect(_on_button_mouse_entered.bind(element))
			if not element.mouse_exited.is_connected(_on_button_mouse_exited.bind(element)):
				element.mouse_exited.connect(_on_button_mouse_exited.bind(element))


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
	menu_start.visible = true
	menu_options.visible = false
