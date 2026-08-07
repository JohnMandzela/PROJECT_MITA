extends Event

const TEDDY_BEAR_PICKUP_FLAG := "test_room_vr_teddy_bear_picked_up"
const TEDDY_BEAR_ITEM_ID := "teddy_bear"

@export var dialogue: DialogueResource

var dialogue_open := false


func _can_interact() -> bool:
	return not dialogue_open and not GameManager.is_done(TEDDY_BEAR_PICKUP_FLAG)


func _on_interact() -> void:
	_start_interaction()


func take_teddy_bear() -> void:
	if GameManager.is_done(TEDDY_BEAR_PICKUP_FLAG):
		return
	Items.item_was_took(TEDDY_BEAR_ITEM_ID)
	GameManager.set_done(TEDDY_BEAR_PICKUP_FLAG)
	_on_unfocused()


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


func _find_overlay() -> CanvasLayer:
	var current: Node = self
	while current != null:
		var overlay := current.get_node_or_null("Game_Interface_Overlay") as CanvasLayer
		if overlay:
			return overlay
		current = current.get_parent()
	return null
