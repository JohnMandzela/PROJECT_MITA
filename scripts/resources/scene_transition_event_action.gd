@tool
class_name SceneTransitionEventAction
extends EventAction

## Время анимации открытия/закрытия двери, секунды
const DOOR_ANIM_TIME := 0.7

const AUDIO_NODE: NodePath = ^"Audio"
const SPRITE_NODE: NodePath = ^"AnimatedSprite2D"
const ANIM_OPEN := &"opening"
const ANIM_CLOSE := &"closing"

@export var exit_direction: Enums.Direction
## Ссылка на сцену в формате GameManager.resolve_scene_path(): "mihyung_offices/corridors_offices".
## Строка, а не PackedScene: локации ссылаются друг на друга, а циклические
## PackedScene Godot не загружает.
@export var target_scene: String
@export var target_spawn_point: String
@export var required_direction := Enums.Direction.UP


func can_interact(context: EventAction.InteractionContext) -> bool:
    var player := context.player
    return player != null and player.last_direction == required_direction


func on_interact(context: EventAction.InteractionContext) -> void:
    var event := context.event
    var player := context.player

    var audio: AudioStreamPlayer = event.get_node_or_null(AUDIO_NODE)
    if audio and audio.stream:
        SoundManager.play_sound(audio.stream)

    var animation: AnimatedSprite2D = event.get_node_or_null(SPRITE_NODE)
    if animation:
        animation.play(ANIM_OPEN)
        await event.get_tree().create_timer(DOOR_ANIM_TIME).timeout

        if not player.interaction_controller.is_in_zone_event(event):
            animation.play(ANIM_CLOSE)

    GameManager.saved_direction = exit_direction
    GameManager.start_scene_transition_by_reference(target_scene, target_spawn_point)
