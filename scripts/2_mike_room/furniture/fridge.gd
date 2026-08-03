extends DialogueEvent


func take_item(item_name: String) -> void:
	if not Inventory.item_check(item_name):
		Inventory.item_was_took(item_name)
		if Inventory.item_check(item_name):
			print("Получено " + item_name)


func drop_item(item_name: String) -> void:
	if Inventory.item_check(item_name):
		Inventory.item_was_dropped(item_name)
		if not Inventory.item_check(item_name):
			print("Выброшено " + item_name)


func cola_in_fridge(flag_name: String) -> void:
	if not Quests.is_done(flag_name):
		Quests.set_done(flag_name)
