extends SceneTree


const BALLOON_SCENE_PATH := "res://scenes/ui/balloon.tscn"
const RESPONSE_DIALOGUE_PATH := "res://dialogues/test.dialogue"


func _initialize() -> void:
	root.size = Vector2i(1152, 648)

	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame

	var main_menu := current_scene
	if main_menu == null or not main_menu.has_method("_on_new_game_button_pressed"):
		_fail("main_menu.tscn did not load with the new game handler")
		return

	main_menu.call("_on_new_game_button_pressed")
	await process_frame
	await process_frame

	if current_scene == null or current_scene.scene_file_path != "res://scenes/mom_home.tscn":
		_fail("New game did not switch to mom_home.tscn")
		return

	var balloon := root.find_child("ExampleBalloon", true, false)
	if balloon == null:
		_fail("Dialogue balloon was not created after starting a new game")
		return

	await process_frame
	await process_frame

	var dialogue_line: DialogueLine = balloon.dialogue_line
	if not is_instance_valid(dialogue_line):
		_fail("Dialogue balloon did not receive the first dialogue line")
		return

	if dialogue_line.character != "Майк":
		_fail("Unexpected first dialogue character: %s" % dialogue_line.character)
		return

	var first_line_text := str(dialogue_line.text)
	balloon.call("_set_skip_button_held", true)
	await process_frame
	if is_instance_valid(balloon):
		balloon.call("_set_skip_button_held", false)

	var short_press_changed := false
	for i in range(60):
		await process_frame
		if not is_instance_valid(balloon) or not is_instance_valid(balloon.dialogue_line):
			_fail("Short Skip press ended the dialogue instead of skipping one line")
			return
		if str(balloon.dialogue_line.text) != first_line_text:
			short_press_changed = true
			break

	if not short_press_changed:
		_fail("Short Skip press did not advance by one dialogue line")
		return

	var second_line_text := str(balloon.dialogue_line.text)
	for i in range(30):
		await process_frame
		if not is_instance_valid(balloon) or not is_instance_valid(balloon.dialogue_line):
			_fail("Short Skip press continued until the dialogue ended")
			return
		if str(balloon.dialogue_line.text) != second_line_text:
			_fail("Short Skip press advanced more than one dialogue line")
			return

	var seen_lines := {}
	seen_lines[second_line_text] = true
	balloon.call("_set_skip_button_held", true)
	var ended_while_holding := false
	for i in range(240):
		await process_frame
		if not is_instance_valid(balloon) or not is_instance_valid(balloon.dialogue_line):
			ended_while_holding = true
			break

		seen_lines[str(balloon.dialogue_line.text)] = true
		if seen_lines.size() >= 4:
			break

	if is_instance_valid(balloon):
		balloon.call("_set_skip_button_held", false)
	if seen_lines.size() < 4 and not ended_while_holding:
		_fail(
			"Holding the Skip button did not continuously advance dialogue lines. seen=%s waiting=%s typing=%s held=%s advancing=%s" % [
				seen_lines.size(),
				balloon.is_waiting_for_input if is_instance_valid(balloon) else null,
				balloon.dialogue_label.is_typing if is_instance_valid(balloon) else null,
				balloon.get("_is_skip_button_held") if is_instance_valid(balloon) else null,
				balloon.get("_is_advancing") if is_instance_valid(balloon) else null,
			]
		)
		return

	if not await _validate_response_line_skip():
		return

	print("new game dialogue launch validation passed")
	quit(0)


func _validate_response_line_skip() -> bool:
	var balloon_scene: PackedScene = load(BALLOON_SCENE_PATH)
	if balloon_scene == null:
		_fail("balloon.tscn failed to load")
		return false

	var dialogue: DialogueResource = load(RESPONSE_DIALOGUE_PATH)
	if dialogue == null:
		_fail("test.dialogue failed to load")
		return false

	var response_balloon = balloon_scene.instantiate()
	root.add_child(response_balloon)
	await process_frame
	response_balloon.dialogue_label.seconds_per_step = 1.0

	var response_line: DialogueLine = await dialogue.get_next_dialogue_line("restart", [response_balloon])
	if not is_instance_valid(response_line) or response_line.responses.is_empty():
		_fail("test.dialogue restart did not produce a response line")
		return false

	response_balloon.dialogue_resource = dialogue
	response_balloon.dialogue_line = response_line
	await process_frame

	response_balloon.call("_set_skip_button_held", true)
	await process_frame
	response_balloon.call("_set_skip_button_held", false)

	for i in range(30):
		await process_frame
		if response_balloon.responses_menu.visible:
			break

	if not response_balloon.responses_menu.visible:
		_fail("Skip did not reveal responses after a response line")
		return false
	if response_balloon.dialogue_line != response_line:
		_fail("Skip advanced past the response choice line")
		return false
	if not response_balloon.skip_button.disabled:
		_fail("Skip button should be disabled while response choices are visible")
		return false

	response_balloon.queue_free()
	await process_frame
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
