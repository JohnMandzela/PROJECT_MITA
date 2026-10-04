extends Node2D

@export var dialogue: DialogueResource
@onready var mike: CharacterBody2D = $MikeNpc
@onready var mom: CharacterBody2D = $MomNpc
@onready var animation_darken: AnimationPlayer = $CanvasLayer/AnimationDarken
@onready var animation_lighten: AnimationPlayer = $CanvasLayer/AnimationLighten

var speed := 120.0
var target_y := 0.0
var mom_moving := false


func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "start", [self])


func mom_move(distance: float):
	target_y = mom.position.y + distance
	mom_moving = true


func darken_screen() -> void:
	animation_darken.play("darken")
	await get_tree().create_timer(0.5).timeout


func darken_screen_backwards() -> void:
	animation_darken.play_backwards("darken")
	await get_tree().create_timer(0.5).timeout


func lighten_screen() -> void:
	animation_lighten.play("lighten")
	await get_tree().create_timer(1.0).timeout


func lighten_screen_backwards() -> void:
	animation_lighten.play_backwards("lighten")
	await get_tree().create_timer(1.0).timeout


## Переключает визуальный режим текущего пузыря диалога прямо во время диалога.
## Использование в диалоге: do switch_balloon("simple")
func switch_balloon(balloon_name: String) -> void:
	if balloon_name != "simple":
		return

	var active_balloon := _find_active_balloon()
	if not active_balloon:
		push_warning("switch_balloon: не найден активный balloon в сцене")
		return

	if active_balloon.has_method("switch_to_simple_mode"):
		active_balloon.switch_to_simple_mode()


## Ищет активный balloon среди дочерних узлов текущей сцены.
func _find_active_balloon() -> Node:
	var current_scene := get_tree().current_scene
	if current_scene:
		for child in current_scene.get_children():
			if child is CanvasLayer and child.has_method("switch_to_simple_mode"):
				return child

	for child in get_tree().root.get_children():
		if child is CanvasLayer and child.has_method("switch_to_simple_mode"):
			return child

	return null


func _process(delta):
	if mom_moving:
		mom.position.y += speed * delta

		if mom.position.y >= target_y:
			mom.position.y = target_y
			mom_moving = false


func dialogue_end():
	var mike_room_scene = load("res://scenes/dorm/mike_room.tscn")
	get_tree().change_scene_to_packed(mike_room_scene)
