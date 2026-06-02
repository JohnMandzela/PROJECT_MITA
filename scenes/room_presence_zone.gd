class_name RoomPresenceZone
extends Area2D
## Area2D: пока игрок пересекается с зоной, room_id считается активной комнатой (см. RoomPresenceManager).

@export var room_id: StringName = &""
## Если зоны перекрываются, выигрывает больший приоритет (например, комната внутри большого коридора).
@export var overlap_priority: int = 0


func _ready() -> void:
	add_to_group("room_presence_zone")
	if not body_entered.is_connected(_on_body_entered_exited):
		body_entered.connect(_on_body_entered_exited)
	if not body_exited.is_connected(_on_body_entered_exited):
		body_exited.connect(_on_body_entered_exited)


func _on_body_entered_exited(body: Node2D) -> void:
	if body != GameManager.player:
		return
	var mgr := get_tree().get_first_node_in_group("room_presence_manager")
	if mgr and mgr.has_method("refresh_active_room"):
		mgr.call_deferred("refresh_active_room")
