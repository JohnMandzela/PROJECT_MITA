extends Node2D

@export var dialogue: DialogueResource
@export var player_scene: PackedScene
@export var default_spawn_point: String
@onready var mike_sleep: CharacterBody2D = $Mike_Sleep
@onready var color_rect: ColorRect = $ColorRect
@onready var unsleep_sound: AudioStreamPlayer = $Mike_Sleep/unsleep_sound

func _ready():
	_start_game()
	if not GameManager.is_done("1_morning_quest"):
		mike_visible_false()
		_new_game()

func _new_game():
	color_rect.visible = true
	mike_sleep.visible = true
	start_screen_fader()
	DialogueManager.show_dialogue_balloon(dialogue, "start", [self])
	GameManager.set_done("1_morning_quest")

func _start_game():
	color_rect.visible = false
	mike_sleep.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spawn_player()

func spawn_player():
	# Если игрока нет — создаём НУЖНУЮ модель
	if GameManager.player == null:
		GameManager.player = player_scene.instantiate()
		add_child(GameManager.player)
	else:
		# Если игрок есть, но его сцена ДРУГАЯ — пересоздаём
		if GameManager.player.scene_file_path != player_scene.resource_path:
			GameManager.player.queue_free()
			GameManager.player = player_scene.instantiate()
			add_child(GameManager.player)
		else:
			add_child(GameManager.player)

	# Определяем spawn
	var spawn_name := GameManager.pending_spawn_point
	if spawn_name == "":
		spawn_name = default_spawn_point

	var spawn = get_node_or_null(spawn_name)
	if spawn:
		GameManager.player.global_position = spawn.global_position

	GameManager.pending_spawn_point = ""

func mike_visible_false():
	GameManager.player.visible = false
	mike_sleep.visible = true

func mike_visible_true():
	GameManager.player.visible = true
	mike_sleep.visible = false


func start_screen_fader() -> void:
	var screen_fader: AnimationPlayer = $ColorRect/AnimationPlayer
	screen_fader.play("start_screen_fader")
	await get_tree().create_timer(1.0).timeout

func on_screen_fader() -> void:
	var screen_fader: AnimationPlayer = $ColorRect/AnimationPlayer
	screen_fader.play("on_screen_fader")
	await get_tree().create_timer(0.5).timeout

func off_screen_fader() -> void:
	var screen_fader: AnimationPlayer = $ColorRect/AnimationPlayer
	screen_fader.play("off_screen_fader")
	await get_tree().create_timer(0.5).timeout


func _wait_time(wait_time: float):
	await get_tree().create_timer(wait_time).timeout

func sleep_animation():
	%Mike_Sleep_Tileset.play("sleep")

func unsleep_animation():
	%Mike_Sleep_Tileset.play("unsleep")
	if not unsleep_sound.playing:
		unsleep_sound.play()

func phone_hand_animation():
	%Mike_Sleep_Tileset.play("phone_on_hand")

func shock():
	%Mike_Sleep_Tileset.play("shock")


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
