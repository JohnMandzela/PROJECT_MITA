extends ZoneEvent

@export var dialogue: DialogueResource
@onready var toilet_sound := $Toilet_Sound
@onready var shower_wah_sound := $Shower_Wash_Sound
@onready var color_rect: ColorRect = $ColorRect
@onready var screen_fader: AnimationPlayer = $ColorRect/AnimationPlayer

var is_dialogue_running := false


func _ready() -> void:
	super._ready()
	color_rect.visible = false
	if not Engine.is_embedded_in_editor:
		var window: Window = get_viewport()
		var screen_index: int = DisplayServer.get_primary_screen()
		window.position = Vector2(DisplayServer.screen_get_position(screen_index)) + (DisplayServer.screen_get_size(screen_index) - window.size) * 0.5
		window.mode = Window.MODE_WINDOWED

	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _can_interact() -> bool:
	return not is_dialogue_running


func _on_interact() -> void:
	if dialogue != null and not GameManager.get_flag("shower_used"):
		is_dialogue_running = true
		GameManager.set_flag("shower_used")
		DialogueManager.show_dialogue_balloon(dialogue, "start", [self])
	else:
		_play_toilet_sound()


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	await get_tree().create_timer(0.1).timeout
	is_dialogue_running = false


func _play_toilet_sound() -> void:
	if toilet_sound and not toilet_sound.playing:
		toilet_sound.play()


func _play_shower_wash_sound() -> void:
	if shower_wah_sound and not shower_wah_sound.playing:
		shower_wah_sound.play()


func on_screen_fader() -> void:
	color_rect.visible = true
	screen_fader.play("on_screen_fader")


func off_screen_fader() -> void:
	screen_fader.play("off_screen_fader")
	await get_tree().create_timer(0.5).timeout
	color_rect.visible = false


func _wait_time(wait_time: float) -> void:
	await get_tree().create_timer(wait_time).timeout
