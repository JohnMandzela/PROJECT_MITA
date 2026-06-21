extends Area2D

const COFFEE_PICKUP_FLAG := "offices_coffee_picked_up"
const COFFEE_ITEM_ID := "coffee_cup"


@export var required_direction := Enums.Direction.LEFT
@export var dialogue: DialogueResource

@onready var label: Label = $Label

var player: CharacterBody2D = null
var dialogue_open := false


func _ready() -> void:
	label.visible = false


func _process(_delta: float) -> void:
	if player == null or dialogue_open or GameManager.is_done(COFFEE_PICKUP_FLAG):
		label.visible = false
		return

	label.visible = _is_correct_direction()
	if label.visible and Input.is_action_just_pressed("interact"):
		_start_interaction()


func take_coffee() -> void:
	if GameManager.is_done(COFFEE_PICKUP_FLAG):
		return
	Items.item_was_took(COFFEE_ITEM_ID)
	GameManager.set_done(COFFEE_PICKUP_FLAG)
	label.visible = false


func _start_interaction() -> void:
	if dialogue == null:
		push_warning("Coffee dialogue is not assigned.")
		return

	var overlay := _find_overlay()
	if overlay == null or not overlay.has_method("start_dialogue"):
		push_warning("Game interface overlay with dialogue support was not found.")
		return

	dialogue_open = true
	if overlay.has_signal("hud_dialogue_finished") and not overlay.hud_dialogue_finished.is_connected(_on_hud_dialogue_finished):
		overlay.hud_dialogue_finished.connect(_on_hud_dialogue_finished)
	overlay.call("start_dialogue", dialogue, "start", [self])


func _on_hud_dialogue_finished() -> void:
	dialogue_open = false


func _on_body_entered(body: CharacterBody2D) -> void:
	player = body


func _on_body_exited(body: CharacterBody2D) -> void:
	if body != player:
		return
	player = null
	label.visible = false


func _is_correct_direction() -> bool:
	if player == null:
		return false

	match required_direction:
		Enums.Direction.UP:
			return player.last_direction == "up"
		Enums.Direction.DOWN:
			return player.last_direction == "down"
		Enums.Direction.LEFT:
			return player.last_direction == "left"
		Enums.Direction.RIGHT:
			return player.last_direction == "right"
	return false


func _find_overlay() -> CanvasLayer:
	var current: Node = self
	while current != null:
		var overlay := current.get_node_or_null("GameInterfaceOverlay") as CanvasLayer
		if overlay:
			return overlay
		current = current.get_parent()
	return null
