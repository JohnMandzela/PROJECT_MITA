class_name ZoneEvent
extends Interactable

## Зона взаимодействия. Регистрируется в InteractionController игрока,
## когда тот входит в неё, и активируется через interact.

@export var activate_on_enter := false

var _player: Player = null


func _on_body_entered(body: Node2D) -> void:
	if activate_on_enter and can_interact():
		on_interact()
	elif body == GameManager.player:
		_player = body as Player
		if _player:
			_player.interaction_controller.register_zone_event(self)


func _on_body_exited(body: Node2D) -> void:
	if not activate_on_enter and body == GameManager.player:
		if _player:
			_player.interaction_controller.unregister_zone_event(self)
		_player = null


func _get_player() -> Player:
	return _player
