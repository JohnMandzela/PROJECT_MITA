class_name Set
extends RefCounted

# Множество

var _items := { }


# Создаёт множество и инициализирует элементами массива
static func of(items: Array) -> Set:
	var new_set := Set.new()
	for item in items:
		new_set.add(item)

	return new_set


# Добавить элемент в множество
func add(item) -> void:
	self._items[item] = true


# Удалить элемент из множества
func remove(item) -> bool:
	return self._items.erase(item)


# Возвращает true, если элемент содержится в множестве
func contains(item) -> bool:
	return item in self._items


# Объединение множеств
func union(other: Set) -> Set:
	var new_set := Set.new()

	for item in self._items.keys():
		new_set.add(item)

	for item in other._items.keys():
		new_set.add(item)

	return new_set


# Пересечение множеств
func intersection(other: Set) -> Set:
	var new_set := Set.new()

	for item in self._items.keys():
		if other.contains(item):
			new_set.add(item)

	return new_set


# Разность множеств
func difference(other: Set) -> Set:
	var new_set := Set.new()

	for item in self._items.keys():
		if not other.contains(item):
			new_set.add(item)

	return new_set
