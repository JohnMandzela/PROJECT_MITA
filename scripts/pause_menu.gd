extends Control


# Переменные к путям данных настроек
@onready var fullscren_checkbox_path: CheckBox = $Panel/VBoxOptions/Fullscreen_CheckBox
@onready var music_value_path: HSlider = $Panel/VBoxOptions/Music/Music_slider/music_slider
@onready var sounds_value_path: HSlider = $Panel/VBoxOptions/Sounds/sounds_slider/sounds_slider
@onready var mouse_sensitivity_value_path: HSlider = $Panel/VBoxOptions/Mouse_Sensivity/Mouse_slider/mouse_sensitivity_slider

@onready var pause_menu_ui: VBoxContainer = $Panel/VBoxContainer
@onready var menu_options: VBoxContainer = $Panel/VBoxOptions
var menu_open = 0

@onready var anim_on_off: AnimationPlayer = $Screen_Fader_Animation/OnOff_Screen_Fader/AnimationPlayer
@onready var anim_exit: AnimationPlayer = $Screen_Fader_Animation/Exit_Screen_Fader/AnimationPlayer
@onready var anim_phone: AnimationPlayer = $Panel/AnimationPlayer
@onready var anim_blur: AnimationPlayer = $Screen_Fader_Animation/Blur_Rect/AnimationPlayer

@onready var fullscreen_check: CheckBox = $Panel/VBoxOptions/Fullscreen_CheckBox
@onready var pause_label:= $Panel/Pause_Label


# Сохраняем данные настроек
func save_settings():
	var config = ConfigFile.new()

	config.set_value("video", "fullscreen", fullscren_checkbox_path.button_pressed)
	config.set_value("audio", "music_volume", music_value_path.value)
	config.set_value("audio", "sounds_volume", sounds_value_path.value)
	config.set_value("mouse", "mouse_sensitivity_value", mouse_sensitivity_value_path.value)

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
	process_mode = Node.PROCESS_MODE_ALWAYS

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
	
func _on_continue_pressed() -> void:
	if menu_open == 1:
		menu_open = menu_open - 1
	close_pause_menu()

func _on_options_pressed() -> void:
	pause_menu_ui.visible = false
	pause_label.visible = false
	menu_options.visible = true

func _on_fullscreen_toggled(pressed):
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed 
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	save_settings()

func _on_back_to_pause_menu_pressed() -> void:
	pause_menu_ui.visible = true
	pause_label.visible = true
	menu_options.visible = false

func close_pause_menu() -> void:
	anim_blur.play("blur_off")
	anim_phone.play("off_phone")
	anim_on_off.play("close_pause_menu")
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = false
	menu_options.visible = false
	visible = false

func _on_exit_to_main_menu_pressed() -> void:
	anim_exit.play("exit_to_main_menu")
	await get_tree().create_timer(0.7).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_inventory_pressed() -> void:
	pass # Replace with function body.
