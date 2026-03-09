extends Control

func _print():
	print("test")

func _on_tutorial_pressed() -> void:
	_print()
	get_tree().change_scene_to_file("res://scenes/Pivo.tscn")

func _on_back_to_menu_pause_pressed() -> void:
	_print()
	get_tree().change_scene_to_file("res://scenes/system/pause_menu_animation.tscn")
