extends PlayerSpawnScene

const OVERLAY_CENTER_RECT := Rect2(68.0, 78.0, 862.0, 478.0)


func _ready() -> void:
	super._ready()

	call_deferred("_center_player_camera_on_overlay_window")


func _center_player_camera_on_overlay_window() -> void:
	if GameManager.player == null:
		return

	var camera := GameManager.player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return

	var viewport_center := Vector2(get_viewport().get_visible_rect().size) * 0.5
	var overlay_window_center := OVERLAY_CENTER_RECT.get_center()
	camera.position = Vector2.ZERO
	camera.offset = viewport_center - overlay_window_center
	camera.enabled = true
