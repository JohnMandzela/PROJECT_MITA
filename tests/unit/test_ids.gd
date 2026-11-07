extends GutTest

# Проверки реестров id: константы должны совпадать с реальными ресурсами


func test_item_ids_exist_in_inventory() -> void:
	for item_id in ItemIds.ALL:
		assert_true(
			Inventory.item_registry.has(item_id),
			"ItemIds.%s: нет res://content/items/%s.tres" % [item_id.to_upper(), item_id]
		)


func test_quest_ids_exist_in_quests() -> void:
	for quest_id in QuestIds.ALL:
		assert_true(
			Quests.quest_exists(quest_id),
			"QuestIds.%s: нет res://content/quests/%s.tres" % [quest_id.to_upper(), quest_id]
		)


func test_input_actions_exist_in_input_map() -> void:
	for action in InputActions.ALL:
		assert_true(
			InputMap.has_action(action),
			"InputActions: в InputMap нет действия '%s'" % action
		)


func test_item_ids_are_unique() -> void:
	assert_eq(ItemIds.ALL.size(), _unique_count(ItemIds.ALL))


func test_quest_ids_are_unique() -> void:
	assert_eq(QuestIds.ALL.size(), _unique_count(QuestIds.ALL))


func test_input_actions_are_unique() -> void:
	assert_eq(InputActions.ALL.size(), _unique_count(InputActions.ALL))


func test_every_item_constant_is_listed() -> void:
	_assert_all_constants_listed("res://scripts/constants/item_ids.gd", ItemIds.ALL)


func test_every_quest_constant_is_listed() -> void:
	_assert_all_constants_listed("res://scripts/constants/quest_ids.gd", QuestIds.ALL)


func test_every_input_action_constant_is_listed() -> void:
	var script: GDScript = load("res://scripts/constants/input_actions.gd")
	var constants: Dictionary = script.get_script_constant_map()

	for constant_name in constants.keys():
		if constant_name == "ALL":
			continue
		assert_true(
			InputActions.ALL.has(constants[constant_name]),
			"%s не добавлен в InputActions.ALL" % constant_name
		)


func _assert_all_constants_listed(script_path: String, registry: PackedStringArray) -> void:
	var script: GDScript = load(script_path)
	var constants: Dictionary = script.get_script_constant_map()

	for constant_name in constants.keys():
		if constant_name == "ALL":
			continue
		assert_true(
			registry.has(constants[constant_name]),
			"%s не добавлен в ALL (%s)" % [constant_name, script_path]
		)


func _unique_count(values) -> int:
	var seen := {}
	for value in values:
		seen[value] = true
	return seen.size()
