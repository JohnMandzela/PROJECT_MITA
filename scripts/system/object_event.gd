class_name ObjectEvent
extends Interactable

## Объект, с которым можно взаимодействовать через рейкаст игрока.
## Стороны, с которых разрешено взаимодействие, задаются слоями коллизий.

@export_category('Allowed Sides')
@export var left := true
@export var right := true
@export var up := true
@export var down := true

const LEFT_COLLISION_LAYER := 2
const RIGHT_COLLISION_LAYER := 4
const UP_COLLISION_LAYER := 8
const DOWN_COLLISION_LAYER := 16


func _ready() -> void:
	super._ready()

	if left:
		collision_layer |= LEFT_COLLISION_LAYER
	if right:
		collision_layer |= RIGHT_COLLISION_LAYER
	if up:
		collision_layer |= UP_COLLISION_LAYER
	if down:
		collision_layer |= DOWN_COLLISION_LAYER
