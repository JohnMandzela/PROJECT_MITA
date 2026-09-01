class_name ZoneEvent
extends Area2D

@export var action: EventAction
@export var activate_on_enter := false

@onready var label: Label = $Label

var _is_running := false
var _player = null


func _ready() -> void:
	if label:
		label.visible = false
		

func _on_body_entered(body: Node2D) -> void:
	if activate_on_enter and can_interact():
		on_interact()
	elif body == GameManager.player:
		_player = body
		_player.interaction_controller.register_zone_event(self)


func _on_body_exited(body: Node2D) -> void:
	if not activate_on_enter and body == GameManager.player:
		_player.interaction_controller.unregister_zone_event(self)
		_player = null


func _create_context() -> EventAction.InteractionContext:
	return EventAction.InteractionContext.new(self, _player)


func can_interact() -> bool:
	var context := _create_context()
	return action != null and action.can_interact(context) and not _is_running


func on_interact() -> void:
	if action:
		var context := _create_context()

		_is_running = true
		await action.on_interact(context)
		_is_running = false


func on_focused() -> void:
	if label:
		label.visible = true


func on_unfocused() -> void:
	if label:
		label.visible = false
