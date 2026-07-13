extends Event

@export var dialogue_1: DialogueResource
@export var dialogue_2: DialogueResource

var is_dialogue_running := false


func _ready() -> void:
	super._ready()
	if not Engine.is_embedded_in_editor:
		var window: Window = get_viewport()
		var screen_index: int = DisplayServer.get_primary_screen()
		window.position = Vector2(DisplayServer.screen_get_position(screen_index)) + (DisplayServer.screen_get_size(screen_index) - window.size) * 0.5
		window.mode = Window.MODE_WINDOWED

	var dm = Engine.get_singleton("DialogueManager")
	if dm and not dm.dialogue_ended.is_connected(_on_dialogue_ended):
		dm.dialogue_ended.connect(_on_dialogue_ended)


func _can_interact() -> bool:
	return not is_dialogue_running


func _on_interact() -> void:
	is_dialogue_running = true
	var dm = Engine.get_singleton("DialogueManager")
	if not dm:
		return
	if not GameManager.is_done("2_mike_room_bed"):
		dm.show_dialogue_balloon(dialogue_1)
		GameManager.set_done("2_mike_room_bed")
	else:
		dm.show_dialogue_balloon(dialogue_2)


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	await get_tree().create_timer(0.1).timeout
	is_dialogue_running = false
