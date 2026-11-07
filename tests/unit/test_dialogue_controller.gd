extends GutTest

# Проверки DialogueController: поток диалога без реального DialogueResource

const BALLOON_PATH := "res://scenes/ui/balloon.tscn"

var balloon: Node
var controller: DialogueController


func before_each() -> void:
	balloon = load(BALLOON_PATH).instantiate()
	add_child_autofree(balloon)
	await wait_process_frames(1)
	controller = balloon.get("controller")


func after_all() -> void:
	GameManager.disable_movement = false


func test_balloon_creates_controller_and_context() -> void:
	assert_not_null(controller)
	assert_same(controller.context, balloon.get("context"))
	assert_false(controller.is_waiting_for_input)
	assert_null(controller.dialogue_line)


func test_plain_line_waits_for_input() -> void:
	controller.dialogue_line = _make_line("Майк")

	assert_true(controller.is_waiting_for_input)
	assert_true(_balloon_control().visible, "после показа строки панель балуна должна быть видна")


func test_responses_block_waiting_for_input() -> void:
	var line := _make_line("Майк")
	line.responses = [DialogueResponse.new()]
	controller.dialogue_line = line

	assert_false(controller.is_waiting_for_input)


func test_narrator_line_does_not_wait_for_responses() -> void:
	controller.dialogue_line = _make_line("")

	assert_true(controller.is_waiting_for_input)
	assert_eq(controller.dialogue_line.character, "")


func _make_line(character: String) -> DialogueLine:
	var line := DialogueLine.new()
	line.character = character
	line.text = ""
	line.next_id = ""
	return line


func _balloon_control() -> Control:
	return balloon.get("balloon")
