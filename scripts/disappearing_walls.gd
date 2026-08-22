extends Area2D

@export var target: Node2D
@export_range(0.0, 1.0) var initial_alpha := 1.0
@export_range(0.0, 1.0) var target_alpha := 0.2
@export var fade_duration := 0.4

var _tween: Tween


func _ready() -> void:
	if target:
		target.modulate.a = initial_alpha
	else:
		push_warning("disappearing_walls: target is null on %s" % get_path())
	print("disappearing_walls ready: %s | monitoring=%s | target=%s" % [name, monitoring, target])
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	print("disappearing_walls body_entered: %s (is_player=%s)" % [body.name, body == GameManager.player])
	if body != GameManager.player:
		return
	_fade_to(target_alpha)


func _on_body_exited(body: Node2D) -> void:
	if body != GameManager.player:
		return
	print("disappearing_walls body_exited: %s" % name)
	_fade_to(initial_alpha)


func _fade_to(alpha: float) -> void:
	if target == null:
		return
	print("disappearing_walls _fade_to(%s) on %s | current modulate.a=%s" % [alpha, name, target.modulate.a])
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(target, "modulate:a", alpha, fade_duration)
