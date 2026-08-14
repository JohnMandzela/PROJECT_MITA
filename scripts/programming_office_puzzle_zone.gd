extends Event

const PUZZLE_COMPLETION_FLAG := "programming_office_samples_puzzle_completed"


func _can_interact() -> bool:
	return not Quests.get_flag(PUZZLE_COMPLETION_FLAG) and not _is_puzzle_busy()


func _on_interact() -> void:
	if Quests.get_flag(PUZZLE_COMPLETION_FLAG):
		return
	var interaction_root := _find_interaction_root()
	if interaction_root == null:
		return
	if interaction_root.has_method("open_samples_puzzle"):
		interaction_root.call("open_samples_puzzle")


func _is_puzzle_busy() -> bool:
	var interaction_root := _find_interaction_root()
	if interaction_root == null:
		return false
	if interaction_root.has_method("is_samples_puzzle_open"):
		return bool(interaction_root.call("is_samples_puzzle_open"))
	return false


func _find_interaction_root() -> Node:
	var current: Node = self
	while current != null:
		if current.has_method("open_samples_puzzle"):
			return current
		current = current.get_parent()
	return get_tree().current_scene
