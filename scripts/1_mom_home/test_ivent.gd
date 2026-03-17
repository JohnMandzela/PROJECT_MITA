extends Node2D


@export var dialogue: DialogueResource
@onready var Mike: CharacterBody2D = $Mike_NPC
@onready var Mom: CharacterBody2D = $Mom_NPC

var speed := 120.0
var target_y := 0.0
var mom_moving := false



func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "start", [self])

func mom_move(distance: float):
	target_y = Mom.position.y + distance
	mom_moving = true

func _process(delta):
	if mom_moving:
		Mom.position.y += speed * delta
		
		if Mom.position.y >= target_y:
			Mom.position.y = target_y
			mom_moving = false

func dialogue_end():
	var mike_room_scene = load("res://scenes/mike_room.tscn")
	get_tree().change_scene_to_packed(mike_room_scene)
