extends Node2D

## Сколько ждать после запуска анимации затемнения/засветления, секунды
const DARKEN_TIME := 0.5
const LIGHTEN_TIME := 1.0

## Скорость, с которой мама подходит к Майку
const MOM_MOVE_SPEED := 120.0

const ANIM_DARKEN := &"darken"
const ANIM_LIGHTEN := &"lighten"

@export var dialogue: DialogueResource

## Куда перейти после катсцены. Задаётся в инспекторе, а не строкой в коде.
@export var target_scene: PackedScene
@export var target_spawn_point: String

@onready var mike: CharacterBody2D = $MikeNpc
@onready var mom: CharacterBody2D = $MomNpc
@onready var animation_darken: AnimationPlayer = $CanvasLayer/AnimationDarken
@onready var animation_lighten: AnimationPlayer = $CanvasLayer/AnimationLighten

var target_y := 0.0
var mom_moving := false


func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "start", [self])


func mom_move(distance: float):
	target_y = mom.position.y + distance
	mom_moving = true


func darken_screen() -> void:
	animation_darken.play(ANIM_DARKEN)
	await get_tree().create_timer(DARKEN_TIME).timeout


func darken_screen_backwards() -> void:
	animation_darken.play_backwards(ANIM_DARKEN)
	await get_tree().create_timer(DARKEN_TIME).timeout


func lighten_screen() -> void:
	animation_lighten.play(ANIM_LIGHTEN)
	await get_tree().create_timer(LIGHTEN_TIME).timeout


func lighten_screen_backwards() -> void:
	animation_lighten.play_backwards(ANIM_LIGHTEN)
	await get_tree().create_timer(LIGHTEN_TIME).timeout


func _process(delta):
	if mom_moving:
		mom.position.y += MOM_MOVE_SPEED * delta

		if mom.position.y >= target_y:
			mom.position.y = target_y
			mom_moving = false


func dialogue_end():
	GameManager.start_scene_transition(target_scene, target_spawn_point)
