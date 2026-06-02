class_name RoomSliceConfig
extends Node

## Описание одной «комнаты»: что рисовать и какие CollisionPolygon2D отключать.
## Пути задаются относительно этого узла.

@export var slice_id: StringName = &""
@export var drawable_path: NodePath = NodePath("")
@export var collision_polygon_paths: Array[NodePath] = []

var _drawable: CanvasItem
var _polys: Array[CollisionPolygon2D] = []
var _transition_tween: Tween

func _ready() -> void:
	if drawable_path != NodePath(""):
		_drawable = get_node_or_null(drawable_path) as CanvasItem
		
	for np in collision_polygon_paths:
		if np == NodePath(""):
			continue
		var node := get_node_or_null(np)
		if node is CollisionPolygon2D:
			_polys.append(node as CollisionPolygon2D)

## Переключает активность комнаты.
## duration = 0.0 → мгновенно, > 0.0 → плавное затухание/проявление
func apply_active(active: bool, duration: float = 0.4) -> void:
	if duration <= 0.0:
		_apply_instant(active)
		return

	# Прерываем предыдущую анимацию, если переход вызван повторно
	if _transition_tween:
		_transition_tween.kill()

	_transition_tween = create_tween()
	_transition_tween.set_ease(Tween.EASE_IN_OUT)
	_transition_tween.set_trans(Tween.TRANS_CUBIC)

	if _drawable:
		_drawable.visible = true # Гарантируем, что узел отрисовывается во время анимации
		_transition_tween.tween_property(_drawable, "modulate:a", 1.0 if active else 0.0, duration)

		if active:
			# Коллизии включаем только в конце появления
			_transition_tween.tween_callback(_set_collisions.bind(true))
		else:
			# Коллизии отключаем сразу при начале исчезновения
			_set_collisions(false)
			# После затухания полностью скрываем узел (экономит draw calls)
			_transition_tween.tween_callback(func(): _drawable.visible = false)
	else:
		# Если нет графического узла, просто переключаем физику
		_set_collisions(active)

func _apply_instant(active: bool) -> void:
	if _drawable:
		_drawable.visible = active
		_drawable.modulate.a = 1.0 if active else 0.0
	_set_collisions(active)

func _set_collisions(enabled: bool) -> void:
	for poly in _polys:
		if poly:
			poly.disabled = not enabled
