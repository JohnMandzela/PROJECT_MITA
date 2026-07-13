extends EventBase

@export var exit_direction: String
@export var target_scene: String
@export var target_spawn_point: String

@onready var audio: AudioStreamPlayer = get_node_or_null("Audio")
@onready var animation: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _process(_delta: float) -> void:
	if player == null:
		return

	if _is_correct_direction():
		label.visible = true
		if Input.is_action_just_pressed("interact"):
			if audio:
				_play_interact_sound()
			
			if animation:
				animation.play("opening")
				await get_tree().create_timer(0.7).timeout
				if player == null:
					animation.play("closing")
				else:
					interact()
			else:
				interact()
	else:
		label.visible = false


func interact() -> void:
	GameManager.saved_direction = exit_direction
	GameManager.saved_flashlight_state = player.is_flashlight_on
	GameManager.start_scene_transition(target_scene, target_spawn_point)


func _play_interact_sound() -> void:
	if audio and not audio.playing:
		audio.play()
