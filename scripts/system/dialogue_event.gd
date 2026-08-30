class_name DialogueEvent
extends ZoneEvent

# TODO delete

# Ресурс диалога, который будет отображаться при взаимодействии с объектом
@export var dialogue: DialogueResource

# Точка входа в диалог
@export var dialogue_start := "start"

var is_dialogue_running := false


func _ready() -> void:
	super._ready()
	if not dialogue:
		return

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	# TODO: уточнить, что это такое
	if not Engine.is_embedded_in_editor:
		var window: Window = get_viewport()
		var screen_index: int = DisplayServer.get_primary_screen()
		window.position = Vector2(DisplayServer.screen_get_position(screen_index)) + (DisplayServer.screen_get_size(screen_index) - window.size) * 0.5
		window.mode = Window.MODE_WINDOWED


func _can_interact() -> bool:
	return dialogue != null and not is_dialogue_running


func _on_interact() -> void:
	is_dialogue_running = true
	DialogueManager.show_dialogue_balloon(dialogue, dialogue_start, [self])


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	await get_tree().create_timer(0.1).timeout
	is_dialogue_running = false
