extends Area2D


enum LookDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}


const TEDDY_BEAR_PICKUP_FLAG := "test_room_vr_teddy_bear_picked_up"
const TEDDY_BEAR_ITEM_ID := "teddy_bear"


@export var required_direction: LookDirection = LookDirection.DOWN
@export var dialogue: DialogueResource

@onready var label: Label = $Label

var player: CharacterBody2D = null
var dialogue_open := false


func _ready() -> void:
	label.visible = false


func _process(_delta: float) -> void:
	if player == null or dialogue_open or GameManager.is_done(TEDDY_BEAR_PICKUP_FLAG):
		label.visible = false
		return

	label.visible = _is_correct_direction()
	if label.visible and Input.is_action_just_pressed("interact"):
		_start_interaction()


func take_teddy_bear() -> void:
	if GameManager.is_done(TEDDY_BEAR_PICKUP_FLAG):
		return
	Items.item_was_took(TEDDY_BEAR_ITEM_ID)
	GameManager.set_done(TEDDY_BEAR_PICKUP_FLAG)
	label.visible = false


func _start_interaction() -> void:
	if dialogue == null:
		push_warning("Teddy bear dialogue is not assigned.")
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
		LookDirection.UP:
			return player.last_direction == "up"
		LookDirection.DOWN:
			return player.last_direction == "down"
		LookDirection.LEFT:
			return player.last_direction == "left"
		LookDirection.RIGHT:
			return player.last_direction == "right"
	return false


func _find_overlay() -> CanvasLayer:
	var current: Node = self
	while current != null:
		var overlay := current.get_node_or_null("Game_Interface_Overlay") as CanvasLayer
		if overlay:
			return overlay
		current = current.get_parent()
	return null
