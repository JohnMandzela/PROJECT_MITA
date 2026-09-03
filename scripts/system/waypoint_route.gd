class_name WaypointRoute
extends Node2D

# Контейнер точек маршрута для навигационных агентов (Npc).
#
# В редакторе добавьте внутрь этого узла обычные Node2D-маркеры
# (например Waypoint1, Waypoint2, ...) и расставьте их внутри запечённой
# навигационной сетки (NavigationRegion2D). Порядок обхода = порядок узлов в дереве.
#
# Пример структуры:
#   MomNpc
#   ├─ NavigationAgent2D
#   └─ Waypoints (WaypointRoute)
#      ├─ Waypoint1   position = (90, -40)
#      ├─ Waypoint2   position = (60, 20)
#      └─ Waypoint3   position = (40, 90)
#
# Подключение: у узла Npc свойство `route = NodePath("Waypoints")`.
# Дальше в коде: npc.follow_route(true)  — бесконечный цикл по точкам,
# или           npc.follow_route(false) — пройти маршрут один раз.


# Возвращает позиции всех дочерних маркеров в глобальных координатах.
func get_route_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for child in get_children():
		if child is Node2D:
			points.append(child.global_position)
	return points


# Возвращает true, если в контейнере есть хотя бы один маркер.
func has_route() -> bool:
	for child in get_children():
		if child is Node2D:
			return true
	return false
