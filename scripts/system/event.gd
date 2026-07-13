class_name Event
extends Area2D

@export var required_direction := Enums.Direction.UP

@onready var label: Label = $Label

var player: CharacterBody2D = null


func _ready() -> void:
	if label:
		label.visible = false


func _process(_delta: float) -> void:
	if player == null:
		_on_unfocused()
		return

	if _is_correct_direction() and _can_interact():
		_on_focused()
		if Input.is_action_just_pressed("interact"):
			_on_interact()
	else:
		_on_unfocused()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		player = body


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		_on_unfocused()


func _can_interact() -> bool:
	return true


func _is_correct_direction() -> bool:
	return player != null and player.last_direction == required_direction


func _on_focused() -> void:
	if label:
		label.visible = true


func _on_unfocused() -> void:
	if label:
		label.visible = false


func _on_interact() -> void:
	pass
