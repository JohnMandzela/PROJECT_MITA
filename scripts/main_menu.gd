extends Control

@onready var vbox = $VBoxContainer
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

func _ready():
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



# --- Обработчики кнопок (твои старые функции) ---
func _on_new_game_button_pressed() -> void:
	var mom_home_scene: PackedScene = load("res://scenes/mom_home.tscn")
	get_tree().change_scene_to_packed(mom_home_scene)

func _on_load_button_tree_entered() -> void:
	var load_button := $VBoxContainer/Load
	load_button.visible = SaveSystem.save_exists()

func _on_load_button_pressed() -> void:
	SaveSystem.load_game()

func _on_options_button_pressed() -> void:
	var options_scene = load("res://scenes/system/options.tscn")
	get_tree().change_scene_to_packed(options_scene)

func _on_exit_pressed() -> void:
	get_tree().quit()
