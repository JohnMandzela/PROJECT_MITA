class_name InputActions

# Имена действий из InputMap (project.godot → [input]).
# Литералы вида "run"/"interact" в коде не пишем — только эти константы.

const INTERACT := &"interact"
const SAVE := &"save"
const LOAD := &"load"
const FLASHLIGHT := &"flashlight"
const RUN := &"run"
const STEALTH := &"stealth"
const CANCEL := &"ui_cancel"
const NEXT := &"ui_accept"
const SKIP := &"skip_dialogue"

const ALL: Array[StringName] = [
	INTERACT,
	SAVE,
	LOAD,
	FLASHLIGHT,
	RUN,
	STEALTH,
	CANCEL,
	NEXT,
	SKIP,
]
