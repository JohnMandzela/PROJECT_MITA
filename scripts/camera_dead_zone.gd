extends Camera2D

## Half-size of the dead zone square in world pixels.
## Camera stays still while the player is inside the square.
@export var dead_zone_half := 64.0

var _anchor := Vector2.ZERO
var _base_position := Vector2.ZERO


func _ready() -> void:
	_base_position = position
	_anchor = global_position


func _process(_delta: float) -> void:
	var player_pos: Vector2 = get_parent().global_position
	var diff := player_pos - _anchor

	if abs(diff.x) > dead_zone_half:
		_anchor.x = player_pos.x - sign(diff.x) * dead_zone_half
	if abs(diff.y) > dead_zone_half:
		_anchor.y = player_pos.y - sign(diff.y) * dead_zone_half

	position = _anchor - get_parent().global_position + _base_position
