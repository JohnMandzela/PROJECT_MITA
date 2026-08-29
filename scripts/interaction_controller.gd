extends Node

@onready var interaction_vectors: Dictionary[Enums.Direction, RayCast2D] = {
	Enums.Direction.UP: $RaycastUp,
	Enums.Direction.DOWN: $RaycastDown,
	Enums.Direction.LEFT: $RaycastLeft,
	Enums.Direction.RIGHT: $RaycastRight
}


# Список всех ZoneEvent, где находится игрок
var _current_zone_events: Array[ZoneEvent] = []

# Ивент в фокусе, который активируется при нажатии interact
var _focused_event: Variant = null:
	set(value):
		if _focused_event == value:
			return
		if _focused_event:
			_focused_event.on_unfocused()
		if value:
			value.on_focused()

		_focused_event = value


# Обноляет ивент в фокусе
func update_focused_event(direction: Enums.Direction):
	var raycast := interaction_vectors[direction]
	if raycast.is_colliding():
		var collider := raycast.get_collider()
		if collider is ObjectEvent:
			_focused_event = collider
			return

	for event in _current_zone_events:
		if event.can_interact():
			_focused_event = event
			return

	_focused_event = null


func register_zone_event(event: ZoneEvent):
	if event not in _current_zone_events:
		_current_zone_events.append(event)


func unregister_zone_event(event: ZoneEvent):
	_current_zone_events.erase(event)


func on_interact_pressed():
	if _focused_event:
		_focused_event.interact()
