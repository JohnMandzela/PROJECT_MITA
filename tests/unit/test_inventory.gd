extends GutTest

# Проверки инвентаря, включая формат сохранения (Inventory.to_dict/from_dict)


func before_each() -> void:
	GameManager.is_virtual_world = false
	Inventory.reset()


func after_all() -> void:
	GameManager.is_virtual_world = false
	Inventory.reset()


func test_give_item_increases_count() -> void:
	Inventory.give_item("cola", 2)

	assert_eq(Inventory.get_item_count("cola"), 2)
	assert_true(Inventory.has_item("cola"))


func test_item_stack_has_item_resource() -> void:
	Inventory.give_item("cola")

	assert_not_null(Inventory.real_world_inventory[0].item)
	assert_eq(Inventory.real_world_inventory[0].item_id, "cola")


func test_to_dict_serializes_both_worlds() -> void:
	Inventory.give_item("cola", 2)
	GameManager.is_virtual_world = true
	Inventory.give_item("teddy_bear", 3)
	GameManager.is_virtual_world = false

	var data := Inventory.to_dict()

	assert_eq(data["real_world_inventory"], [{ "item_id": "cola", "count": 2 }])
	assert_eq(data["virtual_world_inventory"], [{ "item_id": "teddy_bear", "count": 3 }])


func test_dict_roundtrip_through_file() -> void:
	Inventory.give_item("cola", 2)
	Inventory.give_item("coffee_cup", 1)
	GameManager.is_virtual_world = true
	Inventory.give_item("teddy_bear", 1)
	GameManager.is_virtual_world = false

	var path := "user://test_inventory_roundtrip.bin"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var({ "inventory": Inventory.to_dict() })
	file.close()

	Inventory.reset()
	assert_eq(Inventory.get_item_count("cola"), 0)

	file = FileAccess.open(path, FileAccess.READ)
	var loaded: Dictionary = file.get_var()
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	Inventory.from_dict(loaded["inventory"])

	assert_eq(Inventory.get_item_count("cola"), 2)
	assert_eq(Inventory.get_item_count("coffee_cup"), 1)
	GameManager.is_virtual_world = true
	assert_eq(Inventory.get_item_count("teddy_bear"), 1)
	GameManager.is_virtual_world = false


func test_from_dict_skips_invalid_entries() -> void:
	Inventory.give_item("cola", 5)

	Inventory.from_dict({
		"real_world_inventory": [
			{ "item_id": "cola", "count": 1 },
			{ "item_id": "nope", "count": 5 },
			{ "item_id": "cola", "count": 0 },
			{ "item_id": "", "count": 3 },
			"garbage",
		],
	})

	# Ожидаемое предупреждение о неизвестном предмете не должно считаться ошибкой теста
	assert_engine_error("неизвестный предмет")
	assert_eq(Inventory.get_item_count("cola"), 1)
	assert_eq(Inventory.real_world_inventory.size(), 1)


func test_from_dict_accepts_missing_keys() -> void:
	Inventory.give_item("cola", 4)

	Inventory.from_dict({ })

	assert_true(Inventory.real_world_inventory.is_empty())
	assert_true(Inventory.virtual_world_inventory.is_empty())


func test_reset_clears_both_worlds() -> void:
	Inventory.give_item("cola", 2)
	GameManager.is_virtual_world = true
	Inventory.give_item("teddy_bear", 1)
	GameManager.is_virtual_world = false

	Inventory.reset()

	assert_true(Inventory.real_world_inventory.is_empty())
	assert_true(Inventory.virtual_world_inventory.is_empty())
