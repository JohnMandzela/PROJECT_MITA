extends GutTest

# Проверки балуна: простой режим (без портретов и панели)

const BALLOON_PATH := "res://scenes/ui/balloon.tscn"

var balloon: Node


func before_each() -> void:
	balloon = load(BALLOON_PATH).instantiate()
	add_child_autofree(balloon)
	await wait_process_frames(1)


func after_all() -> void:
	GameManager.disable_movement = false


func test_default_mode_shows_panel() -> void:
	assert_true(_panel().visible)
	assert_false(_simple_area().visible)
	assert_eq(_label().get_parent().name, "DialogueArea")


func test_simple_mode_hides_panel() -> void:
	balloon.call("switch_balloon", "simple")
	await wait_process_frames(1)

	assert_false(_panel().visible)
	assert_true(_simple_area().visible)
	assert_false(_label().visible)


func test_simple_mode_is_idempotent() -> void:
	balloon.call("switch_to_simple_mode")
	balloon.call("switch_to_simple_mode")
	await wait_process_frames(1)

	assert_false(_panel().visible)
	assert_true(_simple_area().visible)


func test_unknown_mode_keeps_default_layout() -> void:
	balloon.call("switch_balloon", "wide")

	assert_engine_error("Неизвестный режим балуна")
	assert_true(_panel().visible)
	assert_false(_simple_area().visible)


func test_narrator_line_deactivates_active_portrait() -> void:
	var controller: DialogueController = balloon.get("controller")
	var left_portrait: CharacterPortrait = balloon.get("left_portrait")
	left_portrait.transition_duration = 0.05

	controller.dialogue_line = _make_line("Майк")
	await wait_seconds(0.1)

	assert_eq(left_portrait.character, &"Майк")
	assert_eq(left_portrait.texture_rect.modulate, CharacterPortrait.ACTIVE_COLOR)
	assert_eq(left_portrait.scale, CharacterPortrait.ACTIVE_SCALE)

	controller.dialogue_line = _make_line("")
	# Переход плавный: сразу после смены реплики портрет ещё не погас
	assert_ne(left_portrait.texture_rect.modulate, CharacterPortrait.INACTIVE_COLOR)

	await wait_seconds(0.1)

	assert_eq(left_portrait.texture_rect.modulate, CharacterPortrait.INACTIVE_COLOR)
	assert_eq(left_portrait.scale, CharacterPortrait.INACTIVE_SCALE)


func _make_line(character: String) -> DialogueLine:
	var line := DialogueLine.new()
	line.character = character
	line.text = ""
	line.next_id = ""
	return line


func _panel() -> Control:
	return balloon.get("dialogue_panel")


func _simple_area() -> Control:
	return balloon.get("simple_area")


func _label() -> Control:
	return balloon.get("dialogue_label")
