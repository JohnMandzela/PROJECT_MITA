extends PlayerSpawnScene

## Сколько ждать анимаций фейдера, секунды
const START_FADER_TIME := 1.0
const FADER_STEP_TIME := 0.5

const ANIM_START_FADER := &"start_screen_fader"
const ANIM_FADER_ON := &"on_screen_fader"
const ANIM_FADER_OFF := &"off_screen_fader"

const ANIM_SLEEP := &"sleep"
const ANIM_WAKE_UP := &"wake_up"
const ANIM_PHONE_ON_HAND := &"phone_on_hand"
const ANIM_SHOCK := &"shock"
const ANIM_IRRITATED := &"irritated"

const DIALOGUE_START := "start"

@export var dialogue: DialogueResource
@onready var mike_sleep: CharacterBody2D = $Mike_Sleep
@onready var color_rect: ColorRect = $ColorRect
@onready var wake_up_sound: AudioStreamPlayer = $Mike_Sleep/wake_up_sound
@onready var screen_fader: AnimationPlayer = $ColorRect/AnimationPlayer


func _ready():
	_start_game()
	super._ready()

	if not Quests.is_started(QuestIds.MORNING_ROUTINE):
		mike_visible_false()
		_new_game()


func _new_game():
	color_rect.visible = true
	mike_sleep.visible = true
	start_screen_fader()
	DialogueManager.show_dialogue_balloon(dialogue, DIALOGUE_START, [self])
	Quests.start_quest(QuestIds.MORNING_ROUTINE)


func _start_game():
	color_rect.visible = false
	mike_sleep.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func mike_visible_false():
	GameManager.player.visible = false
	mike_sleep.visible = true


func mike_visible_true():
	GameManager.player.visible = true
	mike_sleep.visible = false


func start_screen_fader() -> void:
	screen_fader.play(ANIM_START_FADER)
	await get_tree().create_timer(START_FADER_TIME).timeout


func on_screen_fader() -> void:
	screen_fader.play(ANIM_FADER_ON)
	await get_tree().create_timer(FADER_STEP_TIME).timeout


func off_screen_fader() -> void:
	screen_fader.play(ANIM_FADER_OFF)
	await get_tree().create_timer(FADER_STEP_TIME).timeout


func _wait_time(wait_time: float):
	await get_tree().create_timer(wait_time).timeout


func sleep_animation():
	%Mike_Sleep_Tileset.play(ANIM_SLEEP)


func wake_up_animation():
	%Mike_Sleep_Tileset.play(ANIM_WAKE_UP)
	SoundManager.play_sound(wake_up_sound.stream)


func phone_hand_animation():
	%Mike_Sleep_Tileset.play(ANIM_PHONE_ON_HAND)


func shock():
	%Mike_Sleep_Tileset.play(ANIM_SHOCK)


func irritated():
	%Mike_Sleep_Tileset.play(ANIM_IRRITATED)
