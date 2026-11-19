class_name ItemNotification
extends PanelContainer

## Карточка «получен/потерян предмет». Создаётся ItemNotifications,
## сама проигрывает появление и уход, потом удаляется.

signal finished

const FADE_IN := 0.15
const HOLD := 2.2
const FADE_OUT := 0.2
const START_SCALE := 0.95

@onready var icon_rect: TextureRect = %Icon
@onready var caption_label: Label = %Caption
@onready var name_label: Label = %ItemName

var item_id := ""
var change := 0


## Заполняет карточку по id предмета и изменению количества (+1 / -1 и т.п.).
func setup(id: String, item_change: int) -> void:
	item_id = id
	change = item_change

	caption_label.text = "Получено" if change > 0 else "Потеряно"

	var item: Item = Inventory.item_registry.get(item_id)
	var display_name := item.display_name if item != null else item_id.replace("_", " ").capitalize()
	if abs(change) > 1:
		display_name += " ×%d" % abs(change)
	name_label.text = display_name

	icon_rect.texture = item.icon if item != null else null
	icon_rect.visible = icon_rect.texture != null


## Проигрывает анимацию и освобождает узел. Вызывать после добавления в дерево.
func play() -> void:
	# Размер нужен для масштабирования относительно центра карточки.
	await get_tree().process_frame
	if is_queued_for_deletion():
		return

	pivot_offset = size / 2.0
	modulate.a = 0.0
	scale = Vector2(START_SCALE, START_SCALE)

	var appear := create_tween().set_parallel()
	appear.tween_property(self, "modulate:a", 1.0, FADE_IN)
	appear.tween_property(self, "scale", Vector2.ONE, FADE_IN) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await appear.finished
	if is_queued_for_deletion():
		return

	await get_tree().create_timer(HOLD, false).timeout
	if is_queued_for_deletion():
		return

	var disappear := create_tween()
	disappear.tween_property(self, "modulate:a", 0.0, FADE_OUT)
	await disappear.finished
	if is_queued_for_deletion():
		return

	finished.emit()
	queue_free()
