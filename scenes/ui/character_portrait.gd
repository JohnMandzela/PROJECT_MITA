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

@onready var texture_rect: TextureRect = $TextureRect
@onready var anim_player: AnimationPlayer = $TextureRect/AnimationPlayer

@export var flipped := false

var _character := &""
var _emotion := &""

func set_active() -> void:	
	self.texture_rect.modulate = ACTIVE_COLOR
	self.scale = ACTIVE_SCALE
	
func set_inactive() -> void:
	self.texture_rect.modulate = INACTIVE_COLOR
	self.scale = INACTIVE_SCALE


func set_character(character: String, emotion := &"") -> void:
	var char_changed = character != self._character
	
	if char_changed:
		hide_character()
	elif emotion == self._emotion:
		return

	self._character = character
	self._emotion = emotion
	
	var prefix = DialogueGlobals.PORTRAIT_PREFIXES[character]
	var portrait_name = (prefix + "_" + emotion) if emotion else prefix

	var anchor := Control.LayoutPreset.PRESET_BOTTOM_RIGHT if flipped else Control.LayoutPreset.PRESET_BOTTOM_LEFT
	self.texture_rect.set_anchors_preset(anchor)
	self.texture_rect.flip_h = flipped

	if char_changed:
		anim_player.play("enter_right" if flipped else "enter_left")

	self.texture_rect.texture = ResourceLoader.load("res://images/characters/%s.png" % [portrait_name], "Texture2D", ResourceLoader.CACHE_MODE_REUSE)

	if char_changed:
		await anim_player.animation_finished


func hide_character() -> void:
	if not self._character: 
		return

	anim_player.play("leave_right" if flipped else "leave_left")
	await anim_player.animation_finished

	self._character = ""
	self._emotion = ""
	self.texture_rect.texture = null
