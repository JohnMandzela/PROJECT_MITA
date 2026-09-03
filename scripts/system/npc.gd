class_name Npc
extends CharacterBody2D

@export var tileset: AnimatedSprite2D
@export var rotation_mode := Enums.RotationMode.DEFAULT
@export var max_speed := 120.0
@export var navigation_agent: NavigationAgent2D
@export var route: WaypointRoute
# Используется для автоповорота на месте в режиме RotationMode.RANDOM.
@export var random_turn_timer: Timer

# НПС дошёл до очередной точки маршрута (индекс в массиве точек контейнера route).
signal waypoint_reached(waypoint_index: int)
# Весь маршрут пройден (только для нециклического follow_route).
signal route_finished

var current_direction := Enums.Direction.DOWN

var _moving := false
var _target_position := Vector2.ZERO
var _route_points: Array[Vector2] = []
var _route_index := 0
var _route_looping := false
var _following_route := false


func _ready() -> void:
	if navigation_agent == null:
		navigation_agent = get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	if navigation_agent != null:
		navigation_agent.velocity_computed.connect(_on_velocity_computed)
		navigation_agent.target_position = global_position

	if rotation_mode == Enums.RotationMode.RANDOM:
		_setup_random_turns()


# Повернуться на месте к стороне. Останавливает агента, если он шёл.
func face(direction: Enums.Direction) -> void:
	_following_route = false
	_route_points = []
	_moving = false
	if navigation_agent != null:
		navigation_agent.target_position = global_position
	current_direction = direction
	velocity = Vector2.ZERO
	_play_tileset_animation()


# Настраивает таймер автоповорота для RotationMode.RANDOM.
func _setup_random_turns() -> void:
	var t := random_turn_timer
	if t == null:
		t = get_node_or_null("Timer") as Timer
	if t == null:
		t = Timer.new()
		t.name = "Timer"
		add_child(t)
		t.owner = get_tree().edited_scene_root
	t.wait_time = 1.5
	t.autostart = true
	if not t.timeout.is_connected(_on_timer_timeout):
		t.timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	if rotation_mode == Enums.RotationMode.RANDOM and not is_moving():
		face(Enums.Direction.values().pick_random())


# Заставляет агента идти к точке по навигационной сетке.
func move_to(point: Vector2) -> void:
	_following_route = false
	_route_points = []
	_target_position = point
	if navigation_agent == null:
		global_position = point
		return
	_moving = true
	navigation_agent.target_position = point


# Начать движение по всем точкам из контейнера route (WaypointRoute).
# При loop = true после последней точки маршрут зацикливается на первую.
func follow_route(loop := false) -> void:
	if route == null:
		return
	_route_points = route.get_route_points()
	if _route_points.is_empty():
		return
	_route_looping = loop
	_route_index = 0
	_following_route = true
	_advance_route()


func _advance_route() -> void:
	_moving = true
	if navigation_agent == null:
		global_position = _route_points[_route_index]
		_on_waypoint_reached()
		return
	navigation_agent.target_position = _route_points[_route_index]


# Останавливает агента в текущем положении.
func stop() -> void:
	_following_route = false
	_route_points = []
	_moving = false
	if navigation_agent != null:
		navigation_agent.target_position = global_position


func is_moving() -> bool:
	return _moving


func _physics_process(_delta: float) -> void:
	if not _moving or navigation_agent == null:
		_apply_velocity(Vector2.ZERO)
		return

	# Если пути ещё нет либо он уже пройден, а цель не достигнута —
	# ждём пересчёта пути на следующем кадре.
	if navigation_agent.is_navigation_finished():
		if global_position.distance_to(navigation_agent.target_position) < navigation_agent.path_desired_distance:
			if _following_route:
				_on_waypoint_reached()
			else:
				_finish_move()
		return

	var next_path_position := navigation_agent.get_next_path_position()
	var desired_velocity := (next_path_position - global_position).normalized() * max_speed

	if navigation_agent.avoidance_enabled:
		# Отдаём желаемую скорость в RVO-симуляцию. Безопасная скорость придёт
		# через сигнал velocity_computed, и мы сдвигаемся в нём.
		navigation_agent.velocity = desired_velocity
	else:
		_apply_velocity(desired_velocity)


func _on_waypoint_reached() -> void:
	waypoint_reached.emit(_route_index)
	_route_index += 1
	if _route_index < _route_points.size():
		_advance_route()
		return
	if _route_looping:
		_route_index = 0
		_following_route = true
		_advance_route()
	else:
		_following_route = false
		route_finished.emit()
		_finish_move()


func _finish_move() -> void:
	_moving = false
	if navigation_agent != null:
		navigation_agent.target_position = global_position
	_apply_velocity(Vector2.ZERO)


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	_apply_velocity(safe_velocity)


func _apply_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity
	move_and_slide()
	_update_direction(new_velocity)
	_play_tileset_animation()


func _update_direction(move_vector: Vector2) -> void:
	if move_vector.is_zero_approx():
		return
	if absf(move_vector.x) > absf(move_vector.y):
		current_direction = Enums.Direction.RIGHT if move_vector.x > 0.0 else Enums.Direction.LEFT
	else:
		current_direction = Enums.Direction.DOWN if move_vector.y > 0.0 else Enums.Direction.UP


func _play_tileset_animation() -> void:
	var sprite := _get_tileset()
	if sprite == null:
		return

	var anim_name := ("walk_" if not velocity.is_zero_approx() else "idle_") \
		+ String(Enums.Direction.find_key(current_direction)).to_lower()
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


func _get_tileset() -> AnimatedSprite2D:
	if tileset != null:
		return tileset
	for child in get_children():
		if child is AnimatedSprite2D:
			return child as AnimatedSprite2D
	return null
