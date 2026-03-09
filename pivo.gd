extends Control


func _on_back_to_messenger_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/messenger.tscn")
