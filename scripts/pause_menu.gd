extends Control

@onready var anim_on_off: AnimationPlayer = $Screen_Fader_Animation/OnOff_Screen_Fader/AnimationPlayer
@onready var anim_exit: AnimationPlayer = $Screen_Fader_Animation/Exit_Screen_Fader/AnimationPlayer
@onready var anim_phone: AnimationPlayer = $Panel/AnimationPlayer
@onready var anim_blur: AnimationPlayer = $Screen_Fader_Animation/Blur_Rect/AnimationPlayer
var menu_open = 0

func _ready():
	visible = false
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

func close_pause_menu() -> void:
	anim_blur.play("blur_off")
	anim_phone.play("off_phone")
	anim_on_off.play("close_pause_menu")
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = false
	visible = false

func _on_exit_to_main_menu_pressed() -> void:
	anim_exit.play("exit_to_main_menu")
	await get_tree().create_timer(0.7).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
