extends Area2D

@export var target_scene: PackedScene
@export var target_spawn_point: String


func _on_body_entered(body):
	if body != GameManager.player:
		return

	GameManager.pending_spawn_point = target_spawn_point
	call_deferred("_change_scene")


func _change_scene():
	get_tree().change_scene_to_packed(target_scene)
