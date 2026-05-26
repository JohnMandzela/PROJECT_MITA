extends Control


const DEFAULT_FILL_COLOR := Color(1.0, 0.3764706, 0.40392157, 0.2)
const DEFAULT_BORDER_COLOR := Color(0.8509804, 0.27058825, 0.28627452, 0.85)
const DASH_LENGTH := 8.0
const GAP_LENGTH := 5.0
const LINE_WIDTH := 2.0


var zone_rects: Array[Rect2] = []
var fill_color := DEFAULT_FILL_COLOR
var border_color := DEFAULT_BORDER_COLOR


func set_style(next_fill_color: Color, next_border_color: Color) -> void:
	# Сохраняем цвета заливки и рамки для текущего типа зоны.
	fill_color = next_fill_color
	border_color = next_border_color
	# После изменения стиля сразу перерисовываем overlay.
	queue_redraw()


func set_zone_rects(rects: Array[Rect2]) -> void:
	# Получаем новый набор прямоугольников зон и копируем его в локальное состояние.
	zone_rects = rects.duplicate()
	# Скрываем overlay, если активных зон больше нет.
	visible = not zone_rects.is_empty()
	# Запрашиваем перерисовку после обновления геометрии.
	queue_redraw()


func _draw() -> void:
	# Рисуем каждую зону полупрозрачной заливкой и пунктирной рамкой.
	for rect in zone_rects:
		draw_rect(rect, fill_color, true)
		_draw_dashed_rect(rect)


func _draw_dashed_rect(rect: Rect2) -> void:
	# Вычисляем углы прямоугольника и отправляем каждую сторону в пунктирный рендер.
	var top_left := rect.position
	var top_right := Vector2(rect.end.x, rect.position.y)
	var bottom_right := rect.end
	var bottom_left := Vector2(rect.position.x, rect.end.y)

	_draw_dashed_line(top_left, top_right)
	_draw_dashed_line(top_right, bottom_right)
	_draw_dashed_line(bottom_right, bottom_left)
	_draw_dashed_line(bottom_left, top_left)


func _draw_dashed_line(start: Vector2, end: Vector2) -> void:
	# Сначала измеряем длину стороны, чтобы корректно разбить ее на штрихи.
	var distance := start.distance_to(end)
	if distance <= 0.0:
		return

	# Шагаем по стороне порциями длины dash-gap и рисуем только видимые сегменты.
	var direction := (end - start).normalized()
	var offset := 0.0
	while offset < distance:
		var dash_end := minf(offset + DASH_LENGTH, distance)
		var segment_start := start + direction * offset
		var segment_end := start + direction * dash_end
		draw_line(segment_start, segment_end, border_color, LINE_WIDTH)
		offset += DASH_LENGTH + GAP_LENGTH
