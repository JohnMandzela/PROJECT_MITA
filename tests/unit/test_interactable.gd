extends GutTest

# Проверки интерактивных объектов: ZoneEvent/ObjectEvent на общем базовом Interactable


func test_zone_without_action_cannot_interact() -> void:
	var zone := _make_zone()

	assert_false(zone.call("can_interact"))


func test_zone_with_action_can_interact() -> void:
	var zone := _make_zone(_make_dialogue_action())

	assert_true(zone.call("can_interact"))


func test_interact_is_blocked_while_running() -> void:
	var zone := _make_zone(_make_dialogue_action())
	zone.set("_is_running", true)

	assert_false(zone.call("can_interact"))


func test_label_is_hidden_on_ready_and_shown_on_focus() -> void:
	var area := Area2D.new()
	area.set_script(load("res://scripts/system/zone_event.gd"))
	var label := Label.new()
	label.name = "Label"
	area.add_child(label)
	add_child_autofree(area)
	await wait_process_frames(1)

	assert_false(label.visible)

	area.call("on_focused")
	assert_true(label.visible)

	area.call("on_unfocused")
	assert_false(label.visible)


func test_object_event_sets_collision_layers() -> void:
	var body := StaticBody2D.new()
	body.set_script(load("res://scripts/system/object_event.gd"))
	body.collision_layer = 0
	add_child_autofree(body)
	await wait_process_frames(1)

	assert_eq(body.collision_layer, 30, "ожидаются слои 2|4|8|16")


func test_object_event_respects_allowed_sides() -> void:
	var body := StaticBody2D.new()
	body.set_script(load("res://scripts/system/object_event.gd"))
	body.collision_layer = 0
	body.set("left", false)
	body.set("right", false)
	add_child_autofree(body)
	await wait_process_frames(1)

	assert_eq(body.collision_layer, 24, "ожидаются только слои UP|DOWN")


func _make_zone(action: EventAction = null) -> Node:
	var zone := Area2D.new()
	zone.set_script(load("res://scripts/system/zone_event.gd"))
	if action:
		zone.set("action", action)
	add_child_autofree(zone)
	return zone


func _make_dialogue_action() -> EventAction:
	var action := DialogueEventAction.new()
	action.dialogue = load("res://dialogues/1_mom_home/sleep_flashback.dialogue")
	return action
