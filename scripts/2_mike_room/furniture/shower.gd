extends Area2D

# Выпадающая строка для выбора направления взгляда (в инспекторе справа)
@export var required_direction := Enums.Direction.UP
# Связываем с уведомлением + звук + задаем переменную player
@onready var toilet_sound := $Toilet_Sound
@onready var shower_wah_sound := $Shower_Wash_Sound
@onready var label := $Label
var player: CharacterBody2D = null

@export var dialogue: DialogueResource
var is_dialogue_running := false

@onready var color_rect: ColorRect = $ColorRect
@onready var screen_fader: AnimationPlayer = $ColorRect/AnimationPlayer


#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	color_rect.visible = false
	label.visible = false
	if not Engine.is_embedded_in_editor:
		var window: Window = get_viewport()
		var screen_index: int = DisplayServer.get_primary_screen()
		window.position = Vector2(DisplayServer.screen_get_position(screen_index)) + (DisplayServer.screen_get_size(screen_index) - window.size) * 0.5
		window.mode = Window.MODE_WINDOWED

	var dialogue_manager = Engine.get_singleton("DialogueManager")
	dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)


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
		if Input.is_action_just_pressed("interact") and is_dialogue_running == false:
			if dialogue != null and not GameManager.is_done("4_shower_use"):
				is_dialogue_running = true
				GameManager.set_done("4_shower_use")
				var dialogue_manager = Engine.get_singleton("DialogueManager")
				dialogue_manager.show_dialogue_balloon(dialogue, "start", [self])
			else:
				_play_toilet_sound()
	else:
		label.visible = false

#region Signals
func _on_dialogue_ended(_resource: DialogueResource):
	await get_tree().create_timer(0.1).timeout
	is_dialogue_running = false
#endregion

#Функция воспроизведения звука туалета
func _play_toilet_sound() -> void:
	if not toilet_sound.playing:
		toilet_sound.play()


#Функция воспроизведения звука душа
func _play_shower_wash_sound() -> void:
	if not shower_wah_sound.playing:
		shower_wah_sound.play()


func on_screen_fader() -> void:
	color_rect.visible = true
	screen_fader.play("on_screen_fader")


func off_screen_fader() -> void:
	screen_fader.play("off_screen_fader")
	await get_tree().create_timer(0.5).timeout
	color_rect.visible = false


func _wait_time(wait_time: float):
	await get_tree().create_timer(wait_time).timeout
