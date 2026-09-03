extends Node2D

@export var dialogue: DialogueResource
@onready var mike: Npc = $MikeNpc
@onready var mom: Npc = $MomNpc
@onready var animation_darken: AnimationPlayer = $CanvasLayer/AnimationDarken
@onready var animation_lighten: AnimationPlayer = $CanvasLayer/AnimationLighten


func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "start", [self])


func mom_move() -> void:
	if mom.route != null:
		mom.follow_route(false)

func mike_move() -> void:
	if mike.route != null:
		mike.follow_route(false)


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


func dialogue_end():
	var mike_room_scene = load("res://scenes/dorm/mike_room.tscn")
	get_tree().change_scene_to_packed(mike_room_scene)
