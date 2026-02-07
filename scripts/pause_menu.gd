extends Control

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()

func toggle() -> void:
	var new_state := !get_tree().paused
	get_tree().paused = new_state
	visible = new_state
	
func _on_continue_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_exit_to_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
