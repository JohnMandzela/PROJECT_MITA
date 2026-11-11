extends Node2D

## Скорость, с которой мама подходит к Майку
const MOM_MOVE_SPEED := 120.0

@export var dialogue: DialogueResource

## Куда перейти после катсцены. Задаётся в инспекторе, а не строкой в коде.
@export var target_scene: PackedScene
@export var target_spawn_point: String

@onready var mike: CharacterBody2D = $MikeNpc
@onready var mom: CharacterBody2D = $MomNpc

var target_y := 0.0
var mom_moving := false


func _enter_tree() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)


func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "start", [self])


func mom_move(distance: float):
	target_y = mom.position.y + distance
	mom_moving = true


func _process(delta):
	if mom_moving:
		mom.position.y += MOM_MOVE_SPEED * delta

		if mom.position.y >= target_y:
			mom.position.y = target_y
			mom_moving = false


# Катсцена закончилась — переходим в следующую сцену
func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource != dialogue:
		return

	GameManager.start_scene_transition(target_scene, target_spawn_point)
