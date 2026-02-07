extends Control


func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_new_game_button_pressed() -> void:
	var mom_home_scene = load("res://scenes/mom_home.tscn")
	get_tree().change_scene_to_packed(mom_home_scene)

func _on_exit_pressed() -> void:
	get_tree().quit()
