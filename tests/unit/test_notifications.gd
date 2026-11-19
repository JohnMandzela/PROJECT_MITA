extends GutTest

# Проверки тостов о получении/потере предметов

func before_each() -> void:
	GameManager.is_skipping_cutscene = false
	Inventory.reset()
	ItemNotifications.clear()
	await get_tree().process_frame


func after_each() -> void:
	GameManager.is_skipping_cutscene = false
	ItemNotifications.clear()
	Inventory.reset()
	await get_tree().process_frame


func test_give_item_shows_received_toast() -> void:
	Inventory.give_item(ItemIds.COLA)
	await wait_process_frames(2)

	assert_eq(ItemNotifications.active_count, 1)

	var toast := ItemNotifications.get_toast(0)
	assert_not_null(toast)
	assert_eq(toast.caption_label.text, "Получено")
	assert_eq(toast.name_label.text, "Бутылка колы")
	assert_not_null(toast.icon_rect.texture)


func test_give_multiple_items_shows_count() -> void:
	Inventory.give_item(ItemIds.COLA, 2)
	await wait_process_frames(2)

	assert_eq(ItemNotifications.get_toast(0).name_label.text, "Бутылка колы ×2")


func test_remove_item_shows_lost_toast() -> void:
	Inventory.give_item(ItemIds.COLA)
	ItemNotifications.clear()
	await wait_process_frames(1)

	Inventory.remove_item(ItemIds.COLA)
	await wait_process_frames(2)

	assert_eq(ItemNotifications.active_count, 1)

	var toast := ItemNotifications.get_toast(0)
	assert_eq(toast.caption_label.text, "Потеряно")
	assert_eq(toast.name_label.text, "Бутылка колы")


func test_remove_all_shows_total_count() -> void:
	Inventory.give_item(ItemIds.COLA, 3)
	ItemNotifications.clear()
	await wait_process_frames(1)

	Inventory.remove_all(ItemIds.COLA)
	await wait_process_frames(2)

	var toast := ItemNotifications.get_toast(0)
	assert_not_null(toast)
	assert_eq(toast.caption_label.text, "Потеряно")
	assert_eq(toast.name_label.text, "Бутылка колы ×3")


func test_removing_missing_item_shows_nothing() -> void:
	Inventory.remove_item(ItemIds.COLA)
	await wait_process_frames(2)

	assert_eq(ItemNotifications.active_count, 0)


func test_loading_inventory_shows_nothing() -> void:
	Inventory.from_dict({
		"real_world_inventory": [{ "item_id": ItemIds.COLA, "count": 2 }],
		"virtual_world_inventory": [],
	})
	await wait_process_frames(2)

	assert_eq(ItemNotifications.active_count, 0)


func test_toasts_are_queued_above_visible_limit() -> void:
	for i in 4:
		Inventory.give_item(ItemIds.COLA)

	await wait_process_frames(2)

	assert_eq(ItemNotifications.active_count, 3)
	assert_eq(ItemNotifications.queued_count, 1)


func test_no_toast_while_skipping_cutscene() -> void:
	GameManager.is_skipping_cutscene = true

	Inventory.give_item(ItemIds.COLA)
	await wait_process_frames(2)

	assert_eq(ItemNotifications.active_count, 0)
	assert_eq(ItemNotifications.queued_count, 0)
