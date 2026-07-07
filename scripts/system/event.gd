extends Area2D

# Выпадающая строка для выбора направления взгляда (в инспекторе справа)
@export var required_direction := Enums.Direction.UP
# Связываем с уведомлением + задаем переменную player
@onready var label := $Label
var player: CharacterBody2D = null


#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	label.visible = false


# Игрок вошел в ивент-зону
func _on_body_entered(body: CharacterBody2D) -> void:
	player = body


# Игрок вышел из ивент-зоны
func _on_body_exited(body: CharacterBody2D) -> void:
	if body == player:
		player = null
		label.visible = false
#---------------------------------------------------------------------------------------------------


# Проверка направления взгляда
func _is_correct_direction() -> bool:
	match required_direction:
		Enums.Direction.UP:
			return player.last_direction == "up"
		Enums.Direction.DOWN:
			return player.last_direction == "down"
		Enums.Direction.LEFT:
			return player.last_direction == "left"
		Enums.Direction.RIGHT:
			return player.last_direction == "right"
	return false


#---------------------------------------------------------------------------------------------------
# Когда игрок находится внутри ивент-зоны
func _process(_delta: float) -> void:
	if player == null:
		return

	if _is_correct_direction():
		label.visible = true
		# Если игрок нажимает кнопку E или Enter
		if Input.is_action_just_pressed("interact"):
			print('Взаимодействие с объектом')
	else:
		label.visible = false
