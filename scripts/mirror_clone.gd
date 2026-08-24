extends Node2D

@export var surface_y: float = 54.0
@export var mirror_offset: float = 0.0
@export var sprite_offset: Vector2 = Vector2(-24, -86)
@export var zone_path: NodePath
@export var opacity: float = 0.5:
	set(value):
		opacity = value
		if is_instance_valid(_sprite):
			_sprite.modulate.a = value

const _ANIM_MAP: Dictionary = {
	&"idle_down": &"idle_up",
	&"idle_up": &"idle_down",
	&"idle_left": &"idle_left",
	&"idle_right": &"idle_right",
	&"walk_down": &"walk_up",
	&"walk_up": &"walk_down",
	&"walk_left": &"walk_left",
	&"walk_right": &"walk_right",
}

var _sprite: AnimatedSprite2D
var _in_zone := false


func _ready() -> void:
	_sprite = $AnimatedSprite2D
	_sprite.position = sprite_offset
	_sprite.modulate.a = 0.0
	visible = false
	if zone_path:
		var zone: Area2D = get_node_or_null(zone_path) as Area2D
		if zone:
			zone.body_entered.connect(_on_zone_body_entered)
			zone.body_exited.connect(_on_zone_body_exited)
	var player := GameManager.player
	if is_instance_valid(player):
		reparent(player)


func _process(_delta: float) -> void:
	var player := GameManager.player
	if not is_instance_valid(player):
		return

	var player_sprite: AnimatedSprite2D = player.get_node_or_null("%Player_Tileset")
	if not player_sprite:
		return

	visible = _in_zone
	if not _in_zone:
		return

	position.x = player.global_position.x
	position.y = surface_y - player.global_position.y + mirror_offset

	_sprite.flip_v = false
	_sprite.modulate.a = opacity

	var anim: StringName = _ANIM_MAP.get(player_sprite.animation, player_sprite.animation)
	_sprite.flip_h = anim == &"walk_up" or anim == &"walk_down" or anim == &"idle_up" or anim == &"idle_down"
	_sprite.play(anim)


func _on_zone_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		_in_zone = true


func _on_zone_body_exited(body: Node2D) -> void:
	if body == GameManager.player:
		_in_zone = false
