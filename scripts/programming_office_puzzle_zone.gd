extends Area2D


const PUZZLE_COMPLETION_FLAG := "programming_office_samples_puzzle_completed"


enum LookDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}


@export var required_direction: LookDirection = LookDirection.LEFT

@onready var label: Label = $Label

var player: CharacterBody2D = null


func _ready() -> void:
	# До появления игрока в зоне подсказка взаимодействия не нужна.
	label.visible = false


func _process(_delta: float) -> void:
	# Показываем подсказку только если игрок стоит в зоне, смотрит в нужную сторону и пазл еще не завершен.
	if player == null:
		label.visible = false
		return
	if GameManager.is_done(PUZZLE_COMPLETION_FLAG):
		label.visible = false
		return
	if _is_puzzle_busy():
		label.visible = false
		return

	if _is_correct_direction():
		label.visible = true
		if Input.is_action_just_pressed("interact"):
			_start_interaction()
	else:
		label.visible = false


func _on_body_entered(body: CharacterBody2D) -> void:
	# Запоминаем игрока, вошедшего в интерактивную область.
	player = body


func _on_body_exited(body: CharacterBody2D) -> void:
	# При выходе игрока из области убираем подсказку и очищаем ссылку на него.
	if body != player:
		return
	player = null
	label.visible = false


func _is_correct_direction() -> bool:
	# Направление взгляда проверяем так же, как в остальных интерактивных объектах проекта.
	if player == null:
		return false
	match required_direction:
		LookDirection.UP:
			return player.last_direction == "up"
		LookDirection.DOWN:
			return player.last_direction == "down"
		LookDirection.LEFT:
			return player.last_direction == "left"
		LookDirection.RIGHT:
			return player.last_direction == "right"
	return false


func _start_interaction() -> void:
	# Если пазл уже завершен, запускать его снова больше не нужно.
	if GameManager.is_done(PUZZLE_COMPLETION_FLAG):
		return

	# Запускаем мини-игру только через корневую сцену локации, чтобы она сама заблокировала движение игрока.
	var interaction_root: Node = _find_interaction_root()
	if interaction_root == null:
		return
	if interaction_root.has_method("open_samples_puzzle"):
		interaction_root.call("open_samples_puzzle")


func _is_puzzle_busy() -> bool:
	# Если мини-игра уже открыта, повторное взаимодействие с зоной не требуется.
	var interaction_root: Node = _find_interaction_root()
	if interaction_root == null:
		return false
	if interaction_root.has_method("is_samples_puzzle_open"):
		return bool(interaction_root.call("is_samples_puzzle_open"))
	return false


func _find_interaction_root() -> Node:
	# Поднимаемся вверх по дереву до сцены, которая умеет открывать пазл.
	var current: Node = self
	while current != null:
		if current.has_method("open_samples_puzzle"):
			return current
		current = current.get_parent()
	return get_tree().current_scene
