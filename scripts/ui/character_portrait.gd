@icon("res://images/editor/character_portrait.svg")
class_name CharacterPortrait
extends Node2D

# Портрет персонажа для диалога

const PORTRAIT_DIRECTORY := "res://images/characters/"
const PORTRAIT_EXTENSION := ".png"

const ACTIVE_COLOR := Color.WHITE
const ACTIVE_SCALE := Vector2(1, 1)

const INACTIVE_COLOR := Color(0.33, 0.33, 0.33, 1)
const INACTIVE_SCALE := Vector2(0.9, 0.9)

const ANIM_ENTER_LEFT := &"enter_left"
const ANIM_ENTER_RIGHT := &"enter_right"
const ANIM_LEAVE_LEFT := &"leave_left"
const ANIM_LEAVE_RIGHT := &"leave_right"

@onready var texture_rect: TextureRect = $TextureRect
@onready var anim_player: AnimationPlayer = $TextureRect/AnimationPlayer

@export var flipped := false

## Длительность плавного перехода между активным и неактивным состоянием (секунды)
@export_range(0.0, 1.0, 0.01) var transition_duration := 0.2

var character := &""
var _emotion := &""

var _transition_tween: Tween


func set_active() -> void:
	_transition_to(ACTIVE_COLOR, ACTIVE_SCALE)


func set_inactive() -> void:
	_transition_to(INACTIVE_COLOR, INACTIVE_SCALE)


func _transition_to(target_color: Color, target_scale: Vector2) -> void:
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()

	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.set_trans(Tween.TRANS_QUAD)
	_transition_tween.set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(texture_rect, "modulate", target_color, transition_duration)
	_transition_tween.tween_property(self, "scale", target_scale, transition_duration)


func set_character(char: String, emotion := &"") -> void:
	var char_changed = char != self.character

	if char_changed:
		hide_character()
	elif emotion == self._emotion:
		return

	self.character = char
	self._emotion = emotion

	var prefix = DialogueGlobals.PORTRAIT_PREFIXES[char]
	var portrait_name = (prefix + "_" + emotion) if emotion else prefix

	var anchor := Control.LayoutPreset.PRESET_BOTTOM_RIGHT if flipped else Control.LayoutPreset.PRESET_BOTTOM_LEFT
	self.texture_rect.set_anchors_preset(anchor)
	self.texture_rect.flip_h = flipped

	if char_changed:
		anim_player.play(ANIM_ENTER_RIGHT if flipped else ANIM_ENTER_LEFT)

	self.texture_rect.texture = ResourceLoader.load(
		PORTRAIT_DIRECTORY + portrait_name + PORTRAIT_EXTENSION,
		"Texture2D",
		ResourceLoader.CACHE_MODE_REUSE,
	)

	if char_changed:
		await anim_player.animation_finished


func hide_character() -> void:
	if not self.character:
		return

	anim_player.play(ANIM_LEAVE_RIGHT if flipped else ANIM_LEAVE_LEFT)
	await anim_player.animation_finished

	self.character = ""
	self._emotion = ""
	self.texture_rect.texture = null
