extends Sprite2D

var _collision_top_y: float = 0.0


func _ready() -> void:
	for body in get_children():
		if body is StaticBody2D:
			for col in body.get_children():
				if col is CollisionShape2D and col.shape is RectangleShape2D:
					_collision_top_y = col.global_position.y - col.shape.size.y / 2.0
					return
				elif col is CollisionPolygon2D and col.polygon.size() > 0:
					var min_y: float = col.polygon[0].y
					for p in col.polygon:
						min_y = min(min_y, p.y)
					_collision_top_y = col.global_position.y + min_y
					return
			break


func _process(_delta: float) -> void:
	var player = GameManager.player
	if player == null:
		return
	z_index = 2 if player.global_position.y > _collision_top_y else 1
