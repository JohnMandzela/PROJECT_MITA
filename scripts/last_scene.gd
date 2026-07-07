extends Area2D

# -------------------------------------------------
# ЗАДАЕМ ПЕРЕМЕННЫЕ

# Вводим в инспекторе:
@export var required_direction := Enums.Direction.UP # направление взгляда
@export_enum("up", "down", "left", "right") # список для взгляда на выход
var exit_direction: String # направление взгляда (на выходе)
@export var target_scene: String # предыдущую сцену
@export var target_spawn_point: String # точку спавна в сцене

# Берем данные из узлов
@onready var audio: AudioStreamPlayer = get_node_or_null("Audio") # звук перехода
@onready var animation: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") # анимацию двери
@onready var label := get_node_or_null("Label") # надпись перехода

var player: CharacterBody2D = null
var can_interact := false
# -------------------------------------------------

# -------------------------------------------------
# ПРОВЕРЯЕМ нахождения ИГРОКА в ЗОНЕ


# Сразу после загрузки сцены
func _ready() -> void:
	label.visible = false


# Игрок вошёл в зону
func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		player = body


# Игрок вышел из зоны
func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		label.visible = false
# -------------------------------------------------

# -------------------------------------------------
# --------------> ПЕРЕХОД ИГРОКА <-----------------
# -------------------------------------------------


func _process(_delta: float) -> void:
	if player == null: # Если игрока нет в зоне,
		return # то пропускаем

	if _is_correct_direction(): # Если игрок смотрит в правильном направлении
		label.visible = true # надпись появляется
		if Input.is_action_just_pressed("interact"): # Если игрок нажимает E или Enter
			if animation == null:
				if audio == null:
					interact()
				else:
					_play_interact_sound()
					interact()
			else:
				if audio == null:
					animation.play("opening")
					await get_tree().create_timer(0.7).timeout
					if player == null:
						animation.play("closing")
					else:
						interact()
				else:
					_play_interact_sound()
					animation.play("opening")
					await get_tree().create_timer(0.7).timeout
					if player == null:
						animation.play("closing")
					else:
						interact()
	else:
		label.visible = false
# -------------------------------------------------


# -------------------------------------------------
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


func interact():
	GameManager.saved_direction = exit_direction
	GameManager.saved_flashlight_state = player.is_flashlight_on
	GameManager.start_scene_transition(target_scene, target_spawn_point)


func _play_interact_sound() -> void:
	if not audio.playing:
		audio.play()
# -------------------------------------------------
