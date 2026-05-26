class_name CharacterPortrait
extends TextureRect
# Портрет персонажа для диалога

enum PortraitState { ACTIVE, INACTIVE, HIDDEN }

const PORTRAIT_DIRECTORY := "res://images/characters/"
const PORTRAIT_EXTENSION := ".png"

const ACTIVE_COLOR := Color.WHITE
const ACTIVE_SCALE := Vector2(1, 1)

const INACTIVE_COLOR := Color(0.33, 0.33, 0.33, 1)
const INACTIVE_SCALE := Vector2(0.9, 0.9)

var _character := ""
var _emotion := ""

# Состояние портрета
var state := PortraitState.HIDDEN:
	get: return state
	set(value):		
		if value == state: return
		
		match value:
			PortraitState.ACTIVE:
				self.modulate = ACTIVE_COLOR
				self.scale = ACTIVE_SCALE
				self.visible = texture != null
			PortraitState.INACTIVE:
				self.modulate = INACTIVE_COLOR
				self.scale = INACTIVE_SCALE
				self.visible = texture != null
			PortraitState.HIDDEN:
				self.visible = false
				
		state = value


func set_hidden() -> void:
	state = PortraitState.HIDDEN

func set_active() -> void:
	state = PortraitState.ACTIVE
	
func set_inactive() -> void:
	state = PortraitState.INACTIVE


func set_character(character: String, emotion: String = "") -> void:
	var prefix := str(DialogueGlobals.PORTRAIT_PREFIXES.get(character, ""))
	if prefix.is_empty():
		hide_character()
		return

	_character = character
	_emotion = emotion
	var portrait_name := _resolve_portrait_name(prefix, emotion)
	var portrait := load("%s%s%s" % [PORTRAIT_DIRECTORY, portrait_name, PORTRAIT_EXTENSION]) as Texture2D
	if portrait == null and not emotion.is_empty():
		portrait = load("%s%s%s" % [PORTRAIT_DIRECTORY, prefix, PORTRAIT_EXTENSION]) as Texture2D

	texture = portrait
	if portrait == null:
		push_warning("Portrait texture was not found for '%s' with emotion '%s'" % [character, emotion])
		set_hidden()


func hide_character() -> void:
	_character = ""
	_emotion = ""
	texture = null
	set_hidden()


func _resolve_portrait_name(prefix: String, emotion: String = "") -> String:
	if emotion.is_empty():
		return prefix
	return "%s_%s" % [prefix, emotion.capitalize()]
