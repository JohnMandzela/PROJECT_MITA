extends SceneTree


const BALLOON_SCENE_PATH := "res://scenes/ui/balloon.tscn"
const MIKE_DIALOGUE_PATH := "res://dialogues/1_mom_home/sleep_flashback.dialogue"
const EMILY_DIALOGUE_PATH := "res://dialogues/elevator_office.dialogue"
const SCREEN_FADER_SCENE_PATH := "res://scenes/system/screen_fader.tscn"
const PAUSE_MENU_SCENE_PATH := "res://scenes/system/pause_menu.tscn"


func _initialize() -> void:
	root.size = Vector2i(1152, 648)

	var game_manager := root.get_node_or_null("GameManager")
	if game_manager == null:
		_fail("GameManager autoload is missing")
		return

	await process_frame
	await process_frame

	var balloon_scene: PackedScene = load(BALLOON_SCENE_PATH)
	if balloon_scene == null:
		_fail("balloon.tscn failed to load")
		return

	var mike_dialogue: DialogueResource = load(MIKE_DIALOGUE_PATH)
	if mike_dialogue == null:
		_fail("sleep_flashback.dialogue failed to load")
		return

	var emily_dialogue: DialogueResource = load(EMILY_DIALOGUE_PATH)
	if emily_dialogue == null:
		_fail("elevator_office.dialogue failed to load")
		return

	var screen_fader_scene: PackedScene = load(SCREEN_FADER_SCENE_PATH)
	if screen_fader_scene == null:
		_fail("screen_fader.tscn failed to load")
		return

	var pause_menu_scene: PackedScene = load(PAUSE_MENU_SCENE_PATH)
	if pause_menu_scene == null:
		_fail("pause_menu.tscn failed to load")
		return

	var balloon = balloon_scene.instantiate()
	root.add_child(balloon)
	if balloon.skip_action != &"skip_dialogue":
		_fail("Balloon skip action should use skip_dialogue instead of ui_cancel")
		return

	var skip_button := balloon.get_node_or_null("Balloon/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/Control/SkipButton") as Button
	if skip_button == null:
		_fail("Dialogue balloon is missing the SkipButton")
		return
	if skip_button.text != "Пропустить":
		_fail("Dialogue SkipButton should be labeled Пропустить")
		return
	if not balloon.has_method("_on_skip_button_button_down") or not balloon.has_method("_on_skip_button_button_up") or not balloon.has_method("_on_skip_button_gui_input"):
		_fail("Dialogue SkipButton hold handlers are missing")
		return

	var pause_menu = pause_menu_scene.instantiate()
	root.add_child(pause_menu)
	if pause_menu.layer <= balloon.layer:
		_fail("Pause menu layer must render above dialogue balloon")
		return

	var screen_fader = screen_fader_scene.instantiate()
	root.add_child(screen_fader)
	await process_frame
	await process_frame

	if not _has_tag(mike_dialogue, "happy"):
		_fail("sleep_flashback.dialogue is missing the happy portrait tag")
		return

	if not _has_tag(mike_dialogue, "side"):
		_fail("sleep_flashback.dialogue is missing the side portrait tag")
		return

	if not _has_hide_portrait_mutation(mike_dialogue):
		_fail("sleep_flashback.dialogue is missing the hide_portrait mutation")
		return

	if not _has_tag(emily_dialogue, "shame"):
		_fail("elevator_office.dialogue is missing the shame portrait tag")
		return

	var left_portrait: CharacterPortrait = balloon.get_node("Balloon/LeftPortrait")
	var right_portrait: CharacterPortrait = balloon.get_node("Balloon/RightPortrait")

	await left_portrait.set_character("Майк", "happy")
	left_portrait.set_active()

	var texture_rect: TextureRect = left_portrait.get_node("TextureRect")
	if texture_rect.texture == null:
		_fail("Portrait texture did not load for Майк happy")
		return

	await balloon.hide_portrait("Майк")
	if texture_rect.texture != null or left_portrait.visible:
		_fail("hide_portrait() did not clear the active portrait")
		return

	var emily_portrait := left_portrait if left_portrait._character.is_empty() else right_portrait
	await emily_portrait.set_character("Эмили")
	emily_portrait.set_active()
	var emily_texture_rect: TextureRect = emily_portrait.get_node("TextureRect")
	var resolved_emily_name: String = emily_portrait.call("_resolve_portrait_name", "Emily", "")
	if resolved_emily_name != "Emily" or emily_texture_rect.texture == null:
		_fail("Portrait texture did not load for Emily")
		return

	await emily_portrait.set_character("Эмили", "shame")
	var resolved_emily_shame_name: String = emily_portrait.call("_resolve_portrait_name", "Emily", "shame")
	if resolved_emily_shame_name.to_lower() != "emily_shame" or emily_texture_rect.texture == null:
		_fail("Portrait texture did not load for Emily_Shame")
		return

	await emily_portrait.hide_character()
	var side_line: DialogueLine = await mike_dialogue.get_next_dialogue_line("start")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	balloon.dialogue_resource = mike_dialogue
	balloon.dialogue_line = side_line
	await process_frame
	await process_frame
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		_fail("Dialogue balloon should make the mouse visible while active")
		return
	if right_portrait._character != "Майк":
		_fail("Portrait side tag did not place Майк on the right")
		return

	var skip_start_line_text: String = str(balloon.dialogue_line.text)
	balloon.call("_set_skip_button_held", true)
	var skip_advanced := false
	for i in range(180):
		await process_frame
		if is_instance_valid(balloon.dialogue_line) and str(balloon.dialogue_line.text) != skip_start_line_text:
			skip_advanced = true
			break
	if not skip_advanced:
		var dialogue_label: DialogueLabel = balloon.get_node("Balloon/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel")
		_fail(
			"Holding the dialogue SkipButton did not advance to the next line. held=%s waiting=%s typing=%s disabled=%s visible=%s/%s" % [
				str(balloon.get("_is_skip_button_held")),
				str(balloon.is_waiting_for_input),
				str(dialogue_label.is_typing),
				str(skip_button.disabled),
				str(dialogue_label.visible_characters),
				str(dialogue_label.get_total_character_count()),
			]
		)
		return
	balloon.call("_set_skip_button_held", false)

	screen_fader.fade_out(0)
	await screen_fader.fade_out_finished
	await screen_fader.fade_in_finished

	print("dialogue portrait validation passed")
	quit(0)


func _has_tag(dialogue: DialogueResource, expected_tag: String) -> bool:
	var lines: Dictionary = dialogue.get("lines")
	for line_data in lines.values():
		if not (line_data is Dictionary):
			continue
		var tags_variant: Variant = line_data.get(&"tags", PackedStringArray())
		var tags: PackedStringArray = tags_variant if tags_variant is PackedStringArray else PackedStringArray(tags_variant)
		for tag in tags:
			if str(tag) == expected_tag or str(tag).begins_with("%s=" % expected_tag):
				return true

	return false


func _has_hide_portrait_mutation(dialogue: DialogueResource) -> bool:
	var lines: Dictionary = dialogue.get("lines")
	for line_data in lines.values():
		if not (line_data is Dictionary):
			continue
		var mutation: Dictionary = line_data.get(&"mutation", {})
		if mutation.is_empty():
			continue
		var expression: Array = mutation.get(&"expression", [])
		for token in expression:
			if token is Dictionary and str(token.get(&"function", "")) == "hide_portrait":
				return true

	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
