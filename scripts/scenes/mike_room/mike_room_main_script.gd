extends PlayerSpawnScene

## Сколько длится плавное появление в начале катсцены, секунды
const START_FADER_TIME := 1.0

const DIALOGUE_START := "start"

@export var dialogue: DialogueResource
@onready var mike_sleep: CharacterBody2D = $Mike_Sleep
@onready var wake_up_sound: AudioStreamPlayer = $Mike_Sleep/wake_up_sound


func _ready():
	_start_game()
	super._ready()

	if not Quests.is_started(QuestIds.MORNING_ROUTINE):
		mike_visible_false()
		_new_game()


func _new_game():
	mike_sleep.visible = true
	GameManager.screen_fader.fade_in(START_FADER_TIME)
	DialogueManager.show_dialogue_balloon(dialogue, DIALOGUE_START, [self])
	Quests.start_quest(QuestIds.MORNING_ROUTINE)


func _start_game():
	mike_sleep.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func mike_visible_false():
	GameManager.player.visible = false
	mike_sleep.visible = true


func mike_visible_true():
	GameManager.player.visible = true
	mike_sleep.visible = false


# Проигрывает анимацию Майка на кровати. with_sound — добавить звук пробуждения.
func play_animation(animation: StringName, with_sound := false) -> void:
	if GameManager.is_skipping_cutscene:
		return

	%Mike_Sleep_Tileset.play(animation)
	if with_sound:
		SoundManager.play_sound(wake_up_sound.stream)
