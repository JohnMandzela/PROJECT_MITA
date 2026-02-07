extends CanvasLayer

signal fade_finished

@onready var anim: AnimationPlayer = $AnimationPlayer

func fade_out():
	anim.play("fade_out")

func fade_in():
	anim.play("fade_in")

func _ready():
	anim.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(name: String) -> void:
	if name == "fade_out":
		fade_finished.emit()
