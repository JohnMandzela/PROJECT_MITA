extends Control

@onready var audio : AudioStreamPlayer = get_node_or_null("Menu_Theme")

func _ready() -> void:
	_play_interact_sound()

func _process(_delta: float) -> void:
	pass

func _on_new_game_button_pressed() -> void:
	var mom_home_scene = load("res://scenes/mom_home.tscn")
	get_tree().change_scene_to_packed(mom_home_scene)

func _on_options_button_pressed() -> void:
	var options_scene = load("res://scenes/system/options.tscn")
	get_tree().change_scene_to_packed(options_scene)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _play_interact_sound() -> void:
	if not audio.playing:
		audio.play()
