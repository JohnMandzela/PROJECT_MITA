extends CharacterBody2D

var speed = 120.0
var run_speed = 240.0
var steals_speed = 70.0
var current_speed = speed
var last_direction := Enums.Direction.DOWN
var direction_vector := Vector2.ZERO

@onready var flashlight = $PhoneFlashlight

var is_flashlight_on := false:
	set(value):
		flashlight.enabled = value
		is_flashlight_on = value

func _ready():
	# Добавляем последнее направление взгляда
	if GameManager.saved_direction != null:
		last_direction = GameManager.saved_direction
		GameManager.saved_direction = null
		
	if GameManager.saved_flashlight_state != null:
		is_flashlight_on = GameManager.saved_flashlight_state
		GameManager.saved_flashlight_state = is_flashlight_on
		
	update_flashlight()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save"):
		SaveSystem.save_game(SaveSystem.Mode.QUICK)
	elif event.is_action_pressed("load"):
		SaveSystem.load_game(SaveSystem.Mode.QUICK)

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("run"):
		current_speed = run_speed
	elif Input.is_action_pressed("steals"):
		current_speed = steals_speed
	else:
		current_speed = speed

	# Движение
	if not GameManager.disable_movement:
		direction_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = direction_vector * current_speed
	else:
		velocity = Vector2.ZERO

	# Направление взгляда (определяем по вводу)
	if direction_vector.y > 0:
		last_direction = Enums.Direction.DOWN
	elif direction_vector.y < 0:
		last_direction = Enums.Direction.UP
	elif direction_vector.x > 0:
		last_direction = Enums.Direction.RIGHT
	elif direction_vector.x < 0:
		last_direction = Enums.Direction.LEFT

	# Проигрываем анимацию
	var anim_prefix := "walk_" if velocity.length() > 0 else "idle_"
	var direction_key: StringName = Enums.Direction.find_key(last_direction).to_lower()
	%Player_Tileset.play(anim_prefix + direction_key)

	update_flashlight()

	# Передвижение
	move_and_slide()

func update_flashlight() -> void:	
	# Поворачиваем фонарик в сторону взгляда
	match last_direction:
		Enums.Direction.RIGHT:
			flashlight.rotation = 0.0
		Enums.Direction.LEFT:
			flashlight.rotation = PI        # 180°
		Enums.Direction.UP:
			flashlight.rotation = -PI/2      # -90°
		Enums.Direction.DOWN:
			flashlight.rotation = PI/2       # 90°

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("flashlight"):
		is_flashlight_on = not is_flashlight_on
