class_name ScreenFader
extends CanvasLayer

signal fade_out_finished
signal fade_in_finished

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

# Длительность затухания. Если null, затухание длится до ручного вызова fade_in()
var _fade_seconds = null

# Затухание
func fade_out(seconds = null):
	_fade_seconds = seconds
	anim.play("fade_out")

# Плавное появление
func fade_in():
	_fade_seconds = null
	anim.play("fade_in")

func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	timer.timeout.connect(fade_in)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "fade_out":
		fade_out_finished.emit()

		match _fade_seconds:
			null: return
			0: fade_in()
			_: timer.start(_fade_seconds)
	else:
		fade_in_finished.emit()