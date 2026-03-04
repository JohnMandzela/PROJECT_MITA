extends Area2D

@export var dialogue: DialogueResource = load("res://dialogues/test.dialogue")

# Called when the node enters the scene tree for the first time.
func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player:
		DialogueManager.show_dialogue_balloon(dialogue)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
