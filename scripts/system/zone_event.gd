class_name ZoneEvent
extends Area2D

@onready var label: Label = $Label

var _player = null


func _ready() -> void:
	if label:
		label.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_player = body
		_player.interaction_controller.register_zone_event(self)


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_player.interaction_controller.unregister_zone_event(self)
		_player = null


func on_focused() -> void:
	if label:
		label.visible = true


func on_unfocused() -> void:
	if label:
		label.visible = false


func can_interact() -> bool:
	return true


func interact() -> void:
	pass
