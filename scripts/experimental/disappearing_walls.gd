extends Area2D

@export var target: Node2D
@export_range(0.0, 1.0) var initial_alpha := 1.0
@export_range(0.0, 1.0) var target_alpha := 0.2
@export var fade_duration := 0.4

var _tween: Tween


func _ready() -> void:
	if target:
		target.modulate.a = initial_alpha
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body != GameManager.player:
		return
	_fade_to(target_alpha)


func _on_body_exited(body: Node2D) -> void:
	if body != GameManager.player:
		return
	_fade_to(initial_alpha)


func _fade_to(alpha: float) -> void:
	if target == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(target, "modulate:a", alpha, fade_duration)
