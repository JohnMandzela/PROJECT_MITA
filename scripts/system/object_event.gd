class_name ObjectEvent
extends StaticBody2D



# Физический слой для интерактивных объектов
const INTERACTIVE_COLLISION_LAYER := 2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_layer |= INTERACTIVE_COLLISION_LAYER


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func on_interact() -> void:
	pass

func on_focused() -> void:
	if label:
		label.visible = true


func on_unfocused() -> void:
	if label:
		label.visible = false
