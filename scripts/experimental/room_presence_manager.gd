extends Node
## Собирает дочерние RoomSliceConfig и зоны RoomPresenceZone (группа room_presence_zone).
## Активна ровно одна комната: зона с игроком и максимальным overlap_priority; иначе fallback_room_id.

@export var fallback_room_id: StringName = &"corridors"

var _slices: Dictionary = {} # StringName -> RoomSliceConfig


func _ready() -> void:
	add_to_group("room_presence_manager")
	for child in get_children():
		if child is RoomSliceConfig:
			var cfg := child as RoomSliceConfig
			if cfg.slice_id:
				_slices[cfg.slice_id] = cfg
	refresh_active_room.call_deferred()


func refresh_active_room() -> void:
	# 1. Защита: если узла нет в дереве, выходим без ошибок
	if not is_inside_tree():
		return
		
	var player := GameManager.player
	if player == null or not is_instance_valid(player):
		return
		
	var best_id: StringName = fallback_room_id
	var best_pri := -999999
	
	# 2. Безопасный доступ к дереву
	var tree := get_tree()
	if tree == null:
		return
		
	for zone in tree.get_nodes_in_group("room_presence_zone"):
		if not zone is RoomPresenceZone:
			continue
		var rz := zone as RoomPresenceZone
		if not rz.monitoring:
			continue
		if rz.overlaps_body(player):
			if rz.overlap_priority > best_pri:
				best_pri = rz.overlap_priority
				best_id = rz.room_id
				
	_apply_room(best_id)


func _apply_room(active_id: StringName) -> void:
	for slice_id in _slices.keys():
		var cfg: RoomSliceConfig = _slices[slice_id]
		cfg.apply_active(slice_id == active_id)
