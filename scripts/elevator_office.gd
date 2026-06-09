extends Node2D

# -------------------------------------------------


# -------------------------------------------------
# ЗАДАЕМ ПЕРЕМЕННЫЕ

# Вводим в инспекторе:
@export_enum("up", "down", "left", "right")                          # список для взгляда на выход
var exit_direction: String                                           # направление взгляда (на выходе)
@export var target_scene: String                                     # предыдущую сцену
@export var target_spawn_point: String                               # точку спавна в сцене
@export var dialogue: DialogueResource
@onready var Mike: CharacterBody2D = $Mike_NPC
@onready var Emily: CharacterBody2D = $Emily_NPC
var player: CharacterBody2D = null
# -------------------------------------------------

var speed := 120.0
var target_y := 0.0
var emily_moving := false



func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "start", [self])

func emily_move(distance: float):
	target_y = Emily.position.y + distance
	emily_moving = true

func next_scene():
	GameManager.saved_direction = exit_direction
	GameManager.start_scene_transition(target_scene, target_spawn_point)

func _process(delta):
	if emily_moving:
		Emily.position.y += speed * delta
		
		if Emily.position.y >= target_y:
			Emily.position.y = target_y
			emily_moving = false
