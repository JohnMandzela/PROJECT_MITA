class_name ObjectEvent
extends StaticBody2D

@export_category('Allowed Sides')
@export var left := true
@export var right := true
@export var up := true
@export var down := true

@onready var label: Label = $Label

const LEFT_COLLISION_LAYER := 2
const RIGHT_COLLISION_LAYER := 4
const UP_COLLISION_LAYER := 8
const DOWN_COLLISION_LAYER := 16


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if left:
		collision_layer |= LEFT_COLLISION_LAYER
	if right:
		collision_layer |= RIGHT_COLLISION_LAYER
	if up:
		collision_layer |= UP_COLLISION_LAYER
	if down:
		collision_layer |= DOWN_COLLISION_LAYER

	if label:
		label.visible = false


func interact() -> void:
	print('Interact')


func on_focused() -> void:
	if label:
		label.visible = true


func on_unfocused() -> void:
	if label:
		label.visible = false
