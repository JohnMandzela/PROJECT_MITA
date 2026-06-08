extends Node

signal inventory_changed

const DATA_PATH := "user://items_data.cfg"
const FALLBACK_ICON_PATH := "res://images/items/cola.png"
const DEFAULT_ITEMS_INVENTORY := {
	"bottle_cola": 0,
	"coffee_cup": 0,
}

var items_inventory := DEFAULT_ITEMS_INVENTORY.duplicate(true)

var item_catalog := {
	"buttle_cola": {
		"display_name": "Бутылка колы",
		"description": "Освежающий напиток. Восстанавливает силы.",
		"icon_path": "res://images/items/cola.png",
	},
	"coffee_cup": {
		"display_name": "Стакан кофе",
		"description": "Бумажный стакан горячего кофе.",
		"use_text": "Выпить кофе",
		"action": "Использовать: повысить Бодрость на 5.",
		"use_effects": {
			"vigor": 5,
		},
		"icon_path": "res://images/items/Coffe_cup_paper.png",
	},
}

var inventory_order: Array[String] = []


func _ready() -> void:
	load_items_data()


func item_check(item_name: String) -> int:
	return int(items_inventory.get(item_name, 0))


func is_known_item(item_name: String) -> bool:
	var id := str(item_name)
	return DEFAULT_ITEMS_INVENTORY.has(id) or item_catalog.has(id)


func has_any_items() -> bool:
	for item_count in items_inventory.values():
		if int(item_count) > 0:
			return true
	return false


func item_was_took(item_name: String) -> void:
	if not _ensure_known_item_slot(item_name):
		return

	items_inventory[item_name] = item_check(item_name) + 1
	_ensure_item_in_order(item_name)
	save_items_data()
	_emit_inventory_changed()


func item_was_dropped(item_name: String) -> void:
	if not _ensure_known_item_slot(item_name):
		return

	items_inventory[item_name] = max(0, item_check(item_name) - 1)
	save_items_data()
	_emit_inventory_changed()


func get_item_info(item_name: String) -> Dictionary:
	var fallback := {
		"display_name": _humanize_item_name(item_name),
		"description": "Описание предмета пока не добавлено.",
		"use_text": "",
		"action": "Действие пока не назначено.",
		"use_effects": {},
		"icon_path": FALLBACK_ICON_PATH,
	}
	return item_catalog.get(item_name, fallback)


func get_ordered_item_ids() -> Array[String]:
	_normalize_inventory_order()
	return inventory_order.duplicate()


func reorder_item(item_id: String, target_index: int) -> void:
	_normalize_inventory_order()
	var current_index := inventory_order.find(item_id)
	if current_index == -1:
		return

	var clamped_index := clampi(target_index, 0, max(0, inventory_order.size() - 1))
	if current_index == clamped_index:
		return

	inventory_order.remove_at(current_index)
	inventory_order.insert(clamped_index, item_id)
	save_items_data()
	_emit_inventory_changed()


func set_inventory_order(order: Array[String]) -> void:
	_normalize_inventory_order()
	var normalized: Array[String] = []
	for item_id in order:
		var id := str(item_id)
		if items_inventory.has(id) and not normalized.has(id):
			normalized.append(id)

	for item_id in inventory_order:
		if not normalized.has(item_id):
			normalized.append(item_id)

	inventory_order = normalized
	save_items_data()
	_emit_inventory_changed()


func apply_inventory_state(inventory: Dictionary, order: Array = []) -> void:
	items_inventory = _sanitize_inventory(inventory)
	inventory_order.clear()
	for item_id in order:
		inventory_order.append(str(item_id))

	_normalize_inventory_order()
	save_items_data()
	_emit_inventory_changed()


func load_items_data() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(DATA_PATH)
	if err != OK:
		_normalize_inventory_order()
		return

	var loaded_inventory = cfg.get_value("items", "inventory", null)
	if loaded_inventory is Dictionary:
		items_inventory = _sanitize_inventory(loaded_inventory)

	var loaded_order = cfg.get_value("items", "order", [])
	if loaded_order is Array:
		inventory_order.clear()
		for item_id in loaded_order:
			inventory_order.append(str(item_id))

	_normalize_inventory_order()


func save_items_data() -> void:
	_normalize_inventory_order()
	var cfg := ConfigFile.new()
	cfg.set_value("items", "inventory", items_inventory)
	cfg.set_value("items", "order", inventory_order)
	cfg.save(DATA_PATH)


func _normalize_inventory_order() -> void:
	if inventory_order.is_empty():
		for item_id in items_inventory.keys():
			inventory_order.append(str(item_id))

	var existing := {}
	for item_id in items_inventory.keys():
		existing[str(item_id)] = true

	var normalized: Array[String] = []
	for item_id in inventory_order:
		if existing.has(item_id):
			normalized.append(item_id)

	for item_id in items_inventory.keys():
		var id := str(item_id)
		if not normalized.has(id):
			normalized.append(id)

	inventory_order = normalized


func _ensure_item_in_order(item_name: String) -> void:
	var id := str(item_name)
	if not inventory_order.has(id):
		inventory_order.append(id)


func _sanitize_inventory(inventory: Dictionary) -> Dictionary:
	var sanitized := DEFAULT_ITEMS_INVENTORY.duplicate(true)
	for item_id in inventory.keys():
		var id := str(item_id)
		if not is_known_item(id):
			continue
		sanitized[id] = max(0, int(inventory[item_id]))
	return sanitized


func _ensure_known_item_slot(item_name: String) -> bool:
	var id := str(item_name)
	if not is_known_item(id):
		return false
	if not items_inventory.has(id):
		items_inventory[id] = 0
	return true


func _emit_inventory_changed() -> void:
	inventory_changed.emit()


func _humanize_item_name(item_name: String) -> String:
	var parts: PackedStringArray = item_name.split("_")
	var result: PackedStringArray = []
	for part in parts:
		if part.is_empty():
			continue
		result.append(part.capitalize())
	return " ".join(result)
