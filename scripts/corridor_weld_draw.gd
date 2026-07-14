extends Control

var arc_center := Vector2.ZERO
var arc_radius := 0.0
var center_angle := PI / 2.0
var marker_angle := PI / 2.0
var show_marker := false

var weld_data: Array = []

var arc_color := Color(0.28, 0.28, 0.34)
var arc_width := 3.0
var center_diamond_color := Color(0.3, 0.85, 0.3, 0.55)
var marker_color := Color(1.0, 1.0, 1.0)
var weld_line_width := 3.0


func set_arc_params(center: Vector2, radius: float) -> void:
	arc_center = center
	arc_radius = radius
	queue_redraw()


func set_marker(angle: float, visible: bool) -> void:
	marker_angle = angle
	show_marker = visible
	queue_redraw()


func add_weld_point(angle: float, deviation: float) -> void:
	var pos := _angle_to_pos(angle)
	var normal := Vector2(cos(angle), -sin(angle))
	pos += normal * deviation
	weld_data.append([pos, deviation])
	queue_redraw()


func clear_weld() -> void:
	weld_data.clear()
	queue_redraw()


func _angle_to_pos(angle: float) -> Vector2:
	return arc_center + Vector2(cos(angle), -sin(angle)) * arc_radius


func _draw() -> void:
	_draw_arc()
	_draw_center_diamond()
	_draw_weld_line()
	if show_marker:
		_draw_marker()


func _draw_arc() -> void:
	if arc_radius <= 0.0:
		return
	var points: PackedVector2Array = PackedVector2Array()
	var steps := 64
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var angle := PI * (1.0 - t)
		points.append(_angle_to_pos(angle))
	draw_polyline(points, arc_color, arc_width, true)


func _draw_center_diamond() -> void:
	if arc_radius <= 0.0:
		return
	var pos := _angle_to_pos(center_angle)
	_draw_diamond(pos, 8.0, center_diamond_color)


func _draw_marker() -> void:
	if arc_radius <= 0.0:
		return
	var pos := _angle_to_pos(marker_angle)
	_draw_diamond(pos, 12.0, marker_color)


func _draw_diamond(pos: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array([
		pos + Vector2(0, -size),
		pos + Vector2(size * 0.6, 0),
		pos + Vector2(0, size),
		pos + Vector2(-size * 0.6, 0)
	])
	draw_colored_polygon(points, color)


func _draw_weld_line() -> void:
	if weld_data.size() < 2:
		return
	for i in range(1, weld_data.size()):
		var prev_pos: Vector2 = weld_data[i - 1][0]
		var curr_pos: Vector2 = weld_data[i][0]
		var deviation: float = absf(weld_data[i][1])
		var color := Color(0.95, 0.75, 0.25)
		if deviation > 5.0:
			color = Color(0.95, 0.5, 0.25)
		if deviation > 15.0:
			color = Color(0.95, 0.35, 0.35)
		draw_line(prev_pos, curr_pos, color, weld_line_width, true)
