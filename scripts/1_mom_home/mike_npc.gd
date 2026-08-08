extends CharacterBody2D

@onready var sprite = $Mike_Tileset
@onready var timer = $Timer

enum Rotation_mode {
	Default,
	Random
}

@export var rotation_mode : Rotation_mode = Rotation_mode.Default

enum Direction {
	DOWN,
	RIGHT,
	UP,
	LEFT
}

var current_direction = Direction.DOWN


func _ready():
#	timer.start()
#	change_direction()
	pass

#func change_direction():
#	if rotation_mode == Rotation_mode.Random:
#		current_direction = randi() % 4
#	if rotation_mode == Rotation_mode.Default:
#		current_direction += 1
#		if current_direction > 3:
#			current_direction = 0
	
#	match current_direction:
#		Direction.DOWN:
#			sprite.play("idle_down")
#			
#		Direction.RIGHT:
#			sprite.play("idle_right")
#			
#		Direction.UP:
#			sprite.play("idle_up")
#			
#		Direction.LEFT:
#			sprite.play("idle_left")



#func _on_timer_timeout():
#	change_direction()
