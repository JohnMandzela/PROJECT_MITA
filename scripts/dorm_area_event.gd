extends Area2D

@export var required_direction := Enums.Direction.UP
@export var dialogue: DialogueResource
@export var dialogue_start: StringName = &"start"

@onready var label: Label = $Label

var player: CharacterBody2D = null
var is_dialogue_running := false
var inspect_door1 := 0
var inspect_door2 := 0
var inspect_door3 := 0
var inspect_door4 := 0
var inspect_door5 := 0

func _ready() -> void:
	label.visible = false
	var dialogue_manager = Engine.get_singleton("DialogueManager")
	if not dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)


func _process(_delta: float) -> void:
	if player == null or is_dialogue_running:
		label.visible = false
		return

	label.visible = _is_correct_direction()
	if label.visible and Input.is_action_just_pressed("interact"):
		is_dialogue_running = true
		var dialogue_manager = Engine.get_singleton("DialogueManager")
		dialogue_manager.show_dialogue_balloon(dialogue, dialogue_start, [self])


func _on_body_entered(body: CharacterBody2D) -> void:
	player = body


func _on_body_exited(body: CharacterBody2D) -> void:
	if body == player:
		player = null
		label.visible = false


func _is_correct_direction() -> bool:
	match required_direction:
		Enums.Direction.UP:
			return player.last_direction == "up"
		Enums.Direction.DOWN:
			return player.last_direction == "down"
		Enums.Direction.LEFT:
			return player.last_direction == "left"
		Enums.Direction.RIGHT:
			return player.last_direction == "right"
	return false


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	await get_tree().create_timer(0.1).timeout
	is_dialogue_running = false
