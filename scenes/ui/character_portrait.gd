class_name CharacterPortrait
extends TextureRect
# Портрет персонажа для диалога

const ACTIVE_COLOR := Color.WHITE
const ACTIVE_SCALE := Vector2(1, 1)

const INACTIVE_COLOR := Color(0.33, 0.33, 0.33, 1)
const INACTIVE_SCALE := Vector2(0.9, 0.9)

var _character = null
var _emotion: StringName = ""


func set_active() -> void:
	self.modulate = ACTIVE_COLOR
	self.scale = ACTIVE_SCALE
	
func set_inactive() -> void:
	self.modulate = INACTIVE_COLOR
	self.scale = INACTIVE_SCALE


func set_character(character: String, emotion: StringName = "") -> void:
	if character == self._character and emotion == self._emotion:
		return
		
	self._character = character
	self._emotion = emotion
	
	var prefix = DialogueGlobals.PORTRAIT_PREFIXES[character]
	var portrait_name = (prefix + "_" + emotion) if emotion else prefix
	self.texture = ResourceLoader.load("res://images/characters/%s.png" % [portrait_name], "Texture2D", ResourceLoader.CACHE_MODE_REUSE)


func hide_character() -> void:
	self._character = null
	self._emotion = ""
	self.texture = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
