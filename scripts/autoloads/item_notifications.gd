extends CanvasLayer

## Стек тостов о получении/потере предметов.
##
## Слушает Inventory.inventory_changed и показывает карточки чуть выше центра
## экрана. Автолоад, поэтому тосты переживают переходы между сценами.
## При пропуске катсцены не показываются, чтобы после скипа не всплывала
## очередь из всех выданных предметов.

const TOAST_SCENE := preload("res://scenes/ui/item_notification.tscn")
const MAX_VISIBLE := 3
## Насколько поднять центр стека над серединой экрана (в пикселях дизайна).
const CENTER_LIFT := 130.0

var _stack: VBoxContainer
var _queue: Array[Dictionary] = []
var _active: Array[ItemNotification] = []

var active_count: int:
	get:
		return _active.size()

var queued_count: int:
	get:
		return _queue.size()


func _ready() -> void:
	# Выше HUD (20), но ниже балуна (100) и меню паузы (101):
	# середина экрана не пересекается с панелью балуна, а тост не всплывает над паузой.
	layer = 95
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_ui()
	Inventory.inventory_changed.connect(_on_inventory_changed)


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Сокращаем область снизу — середина оставшейся части уходит вверх.
	center.offset_bottom = -CENTER_LIFT
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	_stack = VBoxContainer.new()
	_stack.name = "Stack"
	_stack.add_theme_constant_override("separation", 8)
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_stack)


func _on_inventory_changed(item_id: String, change: int) -> void:
	if change == 0 or GameManager.is_skipping_cutscene:
		return

	_queue.append({ "item_id": item_id, "change": change })
	_show_next_toasts()


func _show_next_toasts() -> void:
	while _active.size() < MAX_VISIBLE and not _queue.is_empty():
		var entry: Dictionary = _queue.pop_front()
		_spawn_toast(entry["item_id"], entry["change"])


func _spawn_toast(item_id: String, change: int) -> void:
	var toast: ItemNotification = TOAST_SCENE.instantiate()
	_stack.add_child(toast)
	toast.setup(item_id, change)
	_active.append(toast)
	toast.finished.connect(_on_toast_finished.bind(toast))
	toast.play()


func _on_toast_finished(toast: ItemNotification) -> void:
	_active.erase(toast)
	_show_next_toasts()


## Возвращает активный тост по индексу (для тестов).
func get_toast(index: int) -> ItemNotification:
	return _active[index] if index >= 0 and index < _active.size() else null


## Убирает очередь и все активные тосты.
func clear() -> void:
	_queue.clear()
	for toast in _active:
		if is_instance_valid(toast):
			toast.queue_free()
	_active.clear()
