extends PlayerSpawnScene

const OVERLAY_CENTER_RECT := Rect2(18.0, 22.0, 862.0, 478.0)


func _ready() -> void:
	super._ready()

	if GameManager.player:
		GameManager.player.z_index = 5

	call_deferred("_center_scene_camera_on_overlay_window")


func _center_scene_camera_on_overlay_window() -> void:
	# Пытаемся найти камеру: сначала на игроке, потом в самой сцене
	var camera := _find_scene_camera()
	
	if camera == null:
		return

	var viewport_center := Vector2(get_viewport().get_visible_rect().size) * 0.5
	var overlay_window_center := OVERLAY_CENTER_RECT.get_center()
	camera.position = Vector2.ZERO
	camera.offset = viewport_center - overlay_window_center
	camera.enabled = true


func _find_scene_camera() -> Camera2D:
	# Сначала ищем камеру у игрока
	if GameManager.player:
		var player_camera := GameManager.player.get_node_or_null("Camera2D") as Camera2D
		if player_camera != null:
			return player_camera

	# Затем ищем камеру среди прямых потомков сцены
	for child in get_children():
		if child is Camera2D:
			return child as Camera2D

	# Или рекурсивно по всем потомкам
	var camera := _find_camera_recursive(self)
	if camera != null:
		return camera

	return null


func _find_camera_recursive(node: Node) -> Camera2D:
	for child in node.get_children():
		if child is Camera2D:
			return child as Camera2D
		var found := _find_camera_recursive(child)
		if found != null:
			return found
	return null
