extends Area2D

@export var rooms: Array[Node2D] = []
@export var fade_duration := 0.2

var _tween: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body != GameManager.player:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	for room in rooms:
		if room:
			room.visible = true
	_tween = create_tween().set_parallel(true)
	for room in rooms:
		if room:
			_tween.tween_property(room, "modulate:a", 1.0, fade_duration)


func _on_body_exited(body: Node2D) -> void:
	if body != GameManager.player:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	for room in rooms:
		if room:
			_tween.tween_property(room, "modulate:a", 0.0, fade_duration)
	_tween.finished.connect(_hide_rooms)


func _hide_rooms() -> void:
	for room in rooms:
		if room:
			room.visible = false
			room.modulate.a = 0.0
