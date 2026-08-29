extends ZoneEvent

@export var exit_direction: Enums.Direction
@export var target_scene: String
@export var target_spawn_point: String
@export var required_direction := Enums.Direction.UP

@onready var audio: AudioStreamPlayer = get_node_or_null("Audio")
@onready var animation: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func can_interact() -> bool:
	return _player != null and _player.last_direction == required_direction


func interact() -> void:
	if audio and not audio.playing:
		audio.play()

	if animation:
		animation.play("opening")
		await get_tree().create_timer(0.7).timeout
		if _player == null:
			animation.play("closing")

	GameManager.saved_direction = exit_direction
	GameManager.saved_flashlight_state = _player.is_flashlight_on
	GameManager.start_scene_transition(target_scene, target_spawn_point)
