@tool
class_name SceneTransitionEventAction
extends EventAction

@export var exit_direction: Enums.Direction
@export var target_scene: String
@export var target_spawn_point: String
@export var required_direction := Enums.Direction.UP


func can_interact(context: EventAction.InteractionContext) -> bool:
    var player := context.player
    return player != null and player.last_direction == required_direction


func on_interact(context: EventAction.InteractionContext) -> void:
    var event := context.event
    var player := context.player

    # TODO: сделать глобальный аудиоменеджер
    var audio: AudioStreamPlayer = event.get_node_or_null("Audio")
    if audio and audio.stream:
        SoundManager.play_sound(audio.stream)

    var animation: AnimatedSprite2D = event.get_node_or_null("AnimatedSprite2D")
    if animation:
        animation.play("opening")
        await event.get_tree().create_timer(0.7).timeout

        if not player.interaction_controller.is_in_zone_event(event):
            animation.play("closing")

    # TODO: перенести в отдельную функцию в GameManager
    GameManager.saved_direction = exit_direction
    GameManager.saved_flashlight_state = player.is_flashlight_on
    GameManager.start_scene_transition(target_scene, target_spawn_point)
