extends Node

const ITEMS_PATH := "res://items/"
const PICKUP_SOUND: AudioStream = preload("res://audio/sounds/item_pickup.wav")

const DATA_PATH := "user://items_data.cfg"
const FALLBACK_ICON_PATH := "res://images/items/cola.png"

signal inventory_changed(item_id: String, change: int)

var _items: Dictionary[String, Item] = {}

# Стек предметов в инвентаре
class ItemStack:
	var item_id: String
	var item: Item
	var count: int

	func _init(id: String, n: int = 1) -> void:
		self.item_id = id
		self.item = Inventory._items[id]
		self.count = n

var real_world_inventory: Array[ItemStack] = []
var virtual_world_inventory: Array[ItemStack] = []

var current_inventory: Array[ItemStack]:
	get:
		return virtual_world_inventory if GameManager.is_virtual_world else real_world_inventory


func _ready() -> void:
	_init_items()
	reset()


func _init_items() -> void:
	var dir := DirAccess.open(ITEMS_PATH)
	if not dir:
		push_error("Не удалось открыть папку по пути: " + ITEMS_PATH)
		return

	dir.list_dir_begin()

	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var item_id := file_name.get_basename()
			var item: Item = ResourceLoader.load(ITEMS_PATH + file_name, "Item")
			item.init_icon(item_id)

			_items[item_id] = item
		
		file_name = dir.get_next()

	dir.list_dir_end()


# Возвращает количество предметов с указанным ID в инвентаре
func get_item_count(item_id: String) -> int:
	for stack in current_inventory:
		if stack.item_id == item_id:
			return stack.count

	return 0


# Возвращает true, если в инвентаре есть хотя бы один предмет с указанным ID
func has_item(item_id: String) -> bool:
	return get_item_count(item_id) > 0


# Даёт игроку предмет с указанным ID в количестве count (по умолчанию 1)
func give_item(item_id: String, count := 1) -> void:
	if count <= 0:
		push_warning("Функция give_item вызвана с count <= 0")
		return

	for stack in current_inventory:
		if stack.item_id == item_id:
			stack.count += count
			inventory_changed.emit(stack.item_id, count)
			return

	var stack := ItemStack.new(item_id, count)
	current_inventory.append(stack)
	inventory_changed.emit(stack.item_id, count)

	SoundManager.play_sound(PICKUP_SOUND)

# Убирает из инвентаря предмет с указанным ID в количестве count (по умолчанию 1)
# NB: функция НЕ ПРОВЕРЯЕТ, есть ли предмет в инвентаре!
func remove_item(item_id: String, count := 1) -> void:
	if count <= 0:
		push_warning("Функция remove_item вызвана с count <= 0")
		return

	for stack in current_inventory:
		if stack.item_id == item_id:
			var change: int = min(count, stack.count)
			stack.count -= change
			if stack.count <= 0:
				current_inventory.erase(stack)
			inventory_changed.emit(stack.item_id, -change)
			return


# Убирает из инвентаря все предметы с указанным ID
func remove_all(item_id: String) -> void:
	for stack in current_inventory:
		if stack.item_id == item_id:
			current_inventory.erase(stack)
			inventory_changed.emit(stack.item_id, stack.count)
			return


# Возвращает true, если инвентарь пуст
func is_empty() -> bool:
	return current_inventory.size() == 0


# Сбрасывает инвентарь к дефолтному состоянию
func reset() -> void:
	current_inventory.clear()


# TODO: отрефакторить UI, где используется эта функция
func get_item_info(item_name: String) -> Dictionary:
	var fallback := {
		"display_name": _humanize_item_name(item_name),
		"description": "Описание предмета пока не добавлено.",
		"use_text": "",
		"action": "Действие пока не назначено.",
		"use_effects": { },
		"icon_path": FALLBACK_ICON_PATH,
	}

	return _items[item_name].to_dictionary() if _items.has(item_name) else fallback


func _humanize_item_name(item_name: String) -> String:
	var parts: PackedStringArray = item_name.split("_")
	var result: PackedStringArray = []
	for part in parts:
		if part.is_empty():
			continue
		result.append(part.capitalize())
	return " ".join(result)
