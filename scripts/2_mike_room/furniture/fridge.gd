extends DialogueEventBase


func take_item(item_name: String) -> void:
	if not GameManager.item_check(item_name):
		GameManager.item_was_took(item_name)
		if GameManager.item_check(item_name):
			print("Получено " + item_name)


func drop_item(item_name: String) -> void:
	if GameManager.item_check(item_name):
		GameManager.item_was_dropped(item_name)
		if not GameManager.item_check(item_name):
			print("Выброшено " + item_name)


func cola_in_fridge(flag_name: String) -> void:
	if not GameManager.is_done(flag_name):
		GameManager.game_flags[flag_name] = true
		GameManager.set_done(flag_name)
