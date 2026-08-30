@tool
class_name DialogueEventAction
extends EventAction

# Ресурс диалога, который будет отображаться при взаимодействии с объектом
@export var dialogue: DialogueResource

# Точка входа в диалог
@export var dialogue_start := "start"


func on_interact(_context: EventAction.InteractionContext) -> void:
	DialogueManager.show_dialogue_balloon(dialogue, dialogue_start, [self])
	await DialogueManager.dialogue_ended
