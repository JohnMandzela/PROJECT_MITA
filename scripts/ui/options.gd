extends Control

@onready var fullscren_checkbox_path: CheckBox = $OptionsMenu/OptionsMenuVBox/FullscreenCheckBox
@onready var music_value_path: HSlider = $OptionsMenu/OptionsMenuVBox/Music/MusicSlider/Slider
@onready var sounds_value_path: HSlider = $OptionsMenu/OptionsMenuVBox/Sounds/SoundsSlider/SoundsSlider
@onready var mouse_sensitivity_value_path: HSlider = $OptionsMenu/OptionsMenuVBox/MouseSensitivity/MouseSlider/MouseSensitivitySlider


func _save_settings():
	GameManager.save_settings(
		fullscren_checkbox_path.button_pressed,
		music_value_path.value,
		sounds_value_path.value,
	)


func _ready():
	var is_fullscreen := DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, 
		DisplayServer.WINDOW_MODE_FULLSCREEN
	]

	fullscren_checkbox_path.button_pressed = is_fullscreen

	var config := ConfigFile.new()
	var err := config.load(GameManager.SETTINGS_PATH)
	if err == OK:
		music_value_path.value = config.get_value("audio", "music_volume", 100.0)
		sounds_value_path.value = config.get_value("audio", "sounds_volume", 100.0)
		mouse_sensitivity_value_path.value = config.get_value("mouse", "mouse_sensitivity_value", 0.5)

	await get_tree().process_frame
	_apply_settings()



# TODO: не используется. Удалить или реализовать
func _on_mouse_sensitivity_value_changed(value):
	_save_settings()


func _on_sounds_value_changed(value: float) -> void:
	SoundManager.set_sound_volume(value / 100.0)
	_save_settings()


func _on_music_value_changed(value: float) -> void:
	SoundManager.set_music_volume(value / 100.0)
	_save_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	GameManager.set_fullscreen(enabled)
	_save_settings()


func _apply_settings() -> void:
	GameManager.set_fullscreen(fullscren_checkbox_path.button_pressed)
	SoundManager.set_music_volume(music_value_path.value / 100.0)
	SoundManager.set_sound_volume(sounds_value_path.value / 100.0)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
