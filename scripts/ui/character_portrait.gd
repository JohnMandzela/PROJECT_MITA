class_name CharacterPortrait
extends TextureRect
## Portrait control used by the dialogue balloon. Handles three states
## (ACTIVE / INACTIVE / HIDDEN) with smooth tween transitions, slide-in /
## slide-out animations, and per-portrait emotion tracking.

enum PortraitState { ACTIVE, INACTIVE, HIDDEN }

const PORTRAIT_DIRECTORY := "res://images/characters/"
const PORTRAIT_EXTENSION := ".png"

const ACTIVE_COLOR := Color.WHITE
const ACTIVE_SCALE := Vector2(1, 1)

const INACTIVE_COLOR := Color(0.33, 0.33, 0.33, 1)
const INACTIVE_SCALE := Vector2(0.9, 0.9)

## Sentinel value for the `[#default]` dialogue tag — means "no emotion
## suffix, fall back to the base portrait texture".
const DEFAULT_EMOTION := "default"

## Duration of the modulate/scale tween between ACTIVE and INACTIVE.
@export var state_fade_duration: float = 0.18

## Side of the screen this portrait slides in from. "left" or "right".
@export var slide_side: String = "left"
## How far the portrait travels when sliding in / out, in pixels.
@export var slide_distance: float = 420.0
## Duration of the slide-in / slide-out animation.
@export var slide_duration: float = 0.28

# Currently shown character and emotion. An empty emotion means the
# base portrait texture (no `<prefix>_<emotion>` suffix).
var _character := ""
var _emotion := ""

# Anchor position captured at _ready — used as the resting position
# after a slide-in animation.
var default_position: Vector2 = Vector2.ZERO

# Current visual state. `_apply_state()` is the snap version (no tween);
# `set_active()` and `set_inactive()` are the smooth tween versions.
var _state: int = PortraitState.HIDDEN

# Guard against re-entering the slide / hide animations.
var _is_animating: bool = false

# Active modulate/scale tween — kept so a state change can kill and
# replace the previous one.
var _state_tween: Tween = null


func _ready() -> void:
	default_position = position


# ----------------------------------------------------------------------
# State transitions
# ----------------------------------------------------------------------

## Snap the portrait to a state without animation.
func _apply_state(value: int) -> void:
	if _state_tween and _state_tween.is_valid():
		_state_tween.kill()
	_state_tween = null
	match value:
		PortraitState.ACTIVE:
			modulate = ACTIVE_COLOR
			scale = ACTIVE_SCALE
			visible = texture != null
		PortraitState.INACTIVE:
			modulate = INACTIVE_COLOR
			scale = INACTIVE_SCALE
			visible = texture != null
		PortraitState.HIDDEN:
			visible = false
	_state = value


## Smoothly tween to the ACTIVE state. No-op if already ACTIVE.
func set_active() -> void:
	if _state == PortraitState.HIDDEN or texture == null:
		_apply_state(PortraitState.ACTIVE)
		return
	if _state == PortraitState.ACTIVE:
		return
	_kill_state_tween()
	_state_tween = create_tween()
	_state_tween.set_parallel(true)
	_state_tween.tween_property(self, "modulate", ACTIVE_COLOR, state_fade_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_state_tween.tween_property(self, "scale", ACTIVE_SCALE, state_fade_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	visible = true
	_state = PortraitState.ACTIVE


## Smoothly tween to the INACTIVE state. No-op if already INACTIVE.
func set_inactive() -> void:
	if _state == PortraitState.HIDDEN or texture == null:
		_apply_state(PortraitState.INACTIVE)
		return
	if _state == PortraitState.INACTIVE:
		return
	_kill_state_tween()
	_state_tween = create_tween()
	_state_tween.set_parallel(true)
	_state_tween.tween_property(self, "modulate", INACTIVE_COLOR, state_fade_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_state_tween.tween_property(self, "scale", INACTIVE_SCALE, state_fade_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	visible = true
	_state = PortraitState.INACTIVE


## Snap to HIDDEN — instantly hides the texture.
func set_hidden() -> void:
	_apply_state(PortraitState.HIDDEN)


func _kill_state_tween() -> void:
	if _state_tween and _state_tween.is_valid():
		_state_tween.kill()
	_state_tween = null


# ----------------------------------------------------------------------
# Character / emotion
# ----------------------------------------------------------------------

## True if this portrait is currently displaying the given character.
func is_showing(character: String) -> bool:
	return _character == character and not _character.is_empty()


## Set the character shown on this portrait.
##
## `emotion` is optional and supports persistence: passing an empty
## string means "do not change the current emotion", so a portrait
## keeps the last emotion until a new one is declared. Use
## `[#default]` (or an empty string after that) to clear it.
func set_character(character: String, emotion: String = "") -> void:
	var prefix := str(DialogueGlobals.PORTRAIT_PREFIXES.get(character, ""))
	if prefix.is_empty():
		# No portrait configured for this character — reset and hide.
		_character = ""
		_emotion = ""
		texture = null
		set_hidden()
		return

	_character = character
	if not emotion.is_empty():
		_emotion = _normalize_emotion_arg(emotion)

	var portrait := _load_texture_for_emotion(_emotion)
	texture = portrait
	if portrait == null:
		push_warning("Portrait texture was not found for '%s' with emotion '%s'" % [character, _emotion])
		set_hidden()
	else:
		visible = true


## Change the emotion of an already-loaded portrait in place.
## Returns true if the texture was actually reloaded, false if the
## portrait was either already showing this emotion or had to fall
## back to `set_character`.
func set_emotion(character: String, emotion: String) -> bool:
	var target_emotion := _normalize_emotion_arg(emotion)

	if _character != character or texture == null:
		set_character(character, target_emotion)
		return false

	if target_emotion == _emotion:
		return false

	var new_portrait := _load_texture_for_emotion(target_emotion)
	if new_portrait == null:
		push_warning("Portrait texture was not found for '%s' with emotion '%s'" % [character, target_emotion])
		return false

	texture = new_portrait
	_emotion = target_emotion
	visible = true
	return true


## Hide the portrait and clear its character / emotion.
## Plays the slide-out animation if the portrait is currently visible.
func hide_character() -> void:
	if texture == null and _character == "":
		set_hidden()
		return

	if visible and not _is_animating:
		_is_animating = true
		await slide_out()
		_is_animating = false

	_character = ""
	_emotion = ""
	texture = null
	set_hidden()


# ----------------------------------------------------------------------
# Internals
# ----------------------------------------------------------------------

## Empty / "default" emotion → ""; otherwise lowercased.
func _normalize_emotion_arg(emotion: String) -> String:
	if emotion.is_empty() or emotion.to_lower() == DEFAULT_EMOTION:
		return ""
	return emotion.to_lower()


## Resolve and load the texture for a given emotion of `_character`.
## Returns null if the prefix is missing or no texture could be found.
## Falls back to the base (no-suffix) texture when the specific
## emotion texture is missing.
func _load_texture_for_emotion(emotion: String) -> Texture2D:
	var prefix := str(DialogueGlobals.PORTRAIT_PREFIXES.get(_character, ""))
	if prefix.is_empty():
		return null
	var portrait_name := _resolve_portrait_name(prefix, emotion)
	var portrait := load("%s%s%s" % [PORTRAIT_DIRECTORY, portrait_name, PORTRAIT_EXTENSION]) as Texture2D
	if portrait == null and not emotion.is_empty():
		# Specific emotion texture missing — fall back to the base texture.
		portrait = load("%s%s%s" % [PORTRAIT_DIRECTORY, prefix, PORTRAIT_EXTENSION]) as Texture2D
	return portrait


## Build the file name for a portrait texture.
## Empty emotion → base name. Non-empty → "<prefix>_<CapitalizedEmotion>".
func _resolve_portrait_name(prefix: String, emotion: String = "") -> String:
	if emotion.is_empty():
		return prefix
	return "%s_%s" % [prefix, emotion.capitalize()]


# ----------------------------------------------------------------------
# Slide animations
# ----------------------------------------------------------------------

## Slide the portrait in from the configured side.
func slide_in() -> void:
	if texture == null or _is_animating:
		return
	_is_animating = true

	var start_offset := Vector2((-slide_distance) if slide_side == "left" else slide_distance, 0)
	position = default_position + start_offset
	visible = true

	var tw := create_tween()
	tw.tween_property(self, "position", default_position, slide_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_is_animating = false


## Slide the portrait out to the configured side, then hide it.
func slide_out() -> void:
	if not visible or _is_animating:
		return
	_is_animating = true

	var target_offset := Vector2((-slide_distance) if slide_side == "left" else slide_distance, 0)
	var target := default_position + target_offset

	var tw := create_tween()
	tw.tween_property(self, "position", target, slide_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished

	visible = false
	position = default_position
	_is_animating = false
