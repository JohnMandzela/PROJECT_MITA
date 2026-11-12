extends GutTest

# Проверки условий пропуска катсцены (без реального прохода по диалогу)

const BALLOON_PATH := "res://scenes/ui/balloon.tscn"
const SKIP_LINE_ID := "10"

var balloon: DialogueBalloon
var controller: DialogueController


func before_each() -> void:
	balloon = load(BALLOON_PATH).instantiate()
	add_child_autofree(balloon)
	await wait_process_frames(1)
	controller = balloon.controller


func after_all() -> void:
	GameManager.disable_movement = false


func test_cannot_skip_without_dialogue() -> void:
	assert_false(controller.can_skip_cutscene())


func test_cannot_skip_without_skip_title() -> void:
	controller.dialogue_resource = _make_resource({})
	controller.dialogue_line = _make_line()

	assert_false(controller.can_skip_cutscene())


func test_can_skip_when_skip_title_exists() -> void:
	controller.dialogue_resource = _make_resource({ "skip": SKIP_LINE_ID })
	controller.dialogue_line = _make_line()

	assert_true(controller.can_skip_cutscene())


func test_cannot_skip_on_responses_line() -> void:
	controller.dialogue_resource = _make_resource({ "skip": SKIP_LINE_ID })
	var line := _make_line()
	line.responses = [DialogueResponse.new()]
	controller.dialogue_line = line

	assert_false(controller.can_skip_cutscene())


func test_cannot_skip_in_simple_mode() -> void:
	controller.dialogue_resource = _make_resource({ "skip": SKIP_LINE_ID })
	controller.dialogue_line = _make_line()
	balloon.switch_to_simple_mode()

	assert_false(controller.can_skip_cutscene())


func test_skip_prompt_is_hidden_by_default() -> void:
	assert_false(balloon.skip_prompt.visible)


func test_base_id_strips_uid_and_trail() -> void:
	assert_eq(controller.call("_base_id", "abc@12"), "12")
	assert_eq(controller.call("_base_id", "12|34"), "12")
	assert_eq(controller.call("_base_id", "abc@12|34"), "12")
	assert_eq(controller.call("_base_id", "12"), "12")


func test_end_ids_are_detected() -> void:
	assert_true(controller.call("_is_end_id", DMConstants.ID_END))
	assert_true(controller.call("_is_end_id", DMConstants.ID_END_CONVERSATION))
	assert_true(controller.call("_is_end_id", DMConstants.ID_NULL))
	assert_false(controller.call("_is_end_id", "42"))


func _make_resource(titles: Dictionary) -> DialogueResource:
	var resource := DialogueResource.new()
	resource.titles = titles
	resource.first_title = SKIP_LINE_ID
	resource.lines = {
		SKIP_LINE_ID: { "id": SKIP_LINE_ID, "next_id": DMConstants.ID_END, "type": "" },
	}
	return resource


func _make_line() -> DialogueLine:
	var line := DialogueLine.new()
	line.id = "1"
	line.text = ""
	line.next_id = SKIP_LINE_ID
	return line
