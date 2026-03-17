class_name CharacterPortrait
extends TextureRect
# Портрет персонажа для диалога

enum PortraitState { ACTIVE, INACTIVE, HIDDEN }

const ACTIVE_COLOR := Color.WHITE
const ACTIVE_SCALE := Vector2(1, 1)

const INACTIVE_COLOR := Color(0.33, 0.33, 0.33, 1)
const INACTIVE_SCALE := Vector2(0.9, 0.9)

# Состояние портрета
var state := PortraitState.HIDDEN:
	get: return state
	set(value):		
		if value == state: return
		
		match value:
			PortraitState.ACTIVE:
				self.modulate = ACTIVE_COLOR
				self.scale = ACTIVE_SCALE
				self.visible = true
			PortraitState.INACTIVE:
				self.modulate = INACTIVE_COLOR
				self.scale = INACTIVE_SCALE
				self.visible = true
			PortraitState.HIDDEN:
				self.visible = false
				
		state = value


func set_hidden() -> void:
	state = PortraitState.HIDDEN

func set_active() -> void:
	state = PortraitState.ACTIVE
	
func set_inactive() -> void:
	state = PortraitState.INACTIVE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
