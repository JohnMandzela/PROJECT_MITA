class_name RoomSliceConfig
extends Node
## Описание одной «комнаты»: что рисовать и какие CollisionPolygon2D отключать, когда комната неактивна.
## Пути задаются относительно этого узла (дочернего к RoomPresenceManager).

@export var slice_id: StringName = &""
@export var drawable_path: NodePath = NodePath("")
@export var collision_polygon_paths: Array[NodePath] = []

var _drawable: CanvasItem
var _polys: Array[CollisionPolygon2D] = []


func _ready() -> void:
	if drawable_path != NodePath(""):
		_drawable = get_node_or_null(drawable_path) as CanvasItem
	for np in collision_polygon_paths:
		if np == NodePath(""):
			continue
		var n := get_node_or_null(np)
		if n is CollisionPolygon2D:
			_polys.append(n as CollisionPolygon2D)


func apply_active(active: bool) -> void:
	if _drawable:
		_drawable.visible = active
	for poly in _polys:
		if poly:
			poly.disabled = not active
