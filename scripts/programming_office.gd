extends PlayerSpawnScene


const PUZZLE_COMPLETION_FLAG := "programming_office_samples_puzzle_completed"


@export var puzzle_scene: PackedScene

@onready var camera: Camera2D = $Camera2D
@onready var pause_menu: Node = $PauseMenu
@onready var puzzle_container: Control = $PuzzleLayer/PuzzleContainer

var active_puzzle: Control = null


func _ready() -> void:
	# Сначала создаем игрока в точке спавна, а затем подготавливаем статичную камеру и слой мини-игры.
	super._ready()
	camera.enabled = true
	puzzle_container.visible = false
	puzzle_container.mouse_filter = Control.MOUSE_FILTER_STOP


func open_samples_puzzle() -> void:
	# Повторно не открываем пазл, если он уже активен, завершен или если сцена мини-игры не назначена.
	if is_samples_puzzle_open():
		return
	if GameManager.is_done(PUZZLE_COMPLETION_FLAG):
		return
	if puzzle_scene == null:
		push_warning("Puzzle scene is not assigned for Programming Office.")
		return

	# Создаем мини-игру только один раз, а дальше просто скрываем и показываем ее поверх сцены.
	if active_puzzle == null or not is_instance_valid(active_puzzle):
		var puzzle_instance: Node = puzzle_scene.instantiate()
		active_puzzle = puzzle_instance as Control
		if active_puzzle == null:
			puzzle_instance.queue_free()
			push_warning("Assigned puzzle scene must inherit Control.")
			return

		puzzle_container.add_child(active_puzzle)
		active_puzzle.set_anchors_preset(Control.PRESET_FULL_RECT)
		active_puzzle.offset_left = 0.0
		active_puzzle.offset_top = 0.0
		active_puzzle.offset_right = 0.0
		active_puzzle.offset_bottom = 0.0

		if active_puzzle.has_signal("exit_requested"):
			active_puzzle.connect("exit_requested", Callable(self, "_on_puzzle_exit_requested"))
		if active_puzzle.has_signal("puzzle_completed"):
			active_puzzle.connect("puzzle_completed", Callable(self, "_on_puzzle_completed"))

	active_puzzle.visible = true
	puzzle_container.visible = true

	# Во время мини-игры блокируем движение игрока и оставляем видимым курсор для работы с полем.
	GameManager.disable_movement = true
	GameManager.is_minigame_active = true
	GameManager.minigame_pause_target = active_puzzle
	if GameManager.player:
		GameManager.player.velocity = Vector2.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close_samples_puzzle() -> void:
	# Сворачиваем мини-игру без удаления ее узла и возвращаем обычное управление локацией.
	if active_puzzle and is_instance_valid(active_puzzle):
		active_puzzle.visible = false
	puzzle_container.visible = false
	GameManager.disable_movement = false
	GameManager.is_minigame_active = false
	GameManager.minigame_pause_target = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func is_samples_puzzle_open() -> bool:
	# Возвращаем текущее состояние мини-игры, чтобы ивент-зона не запускала ее повторно.
	return (
		active_puzzle != null
		and is_instance_valid(active_puzzle)
		and active_puzzle.visible
		and puzzle_container.visible
	)


func _exit_tree() -> void:
	# При выходе из сцены сбрасываем блокировку движения, чтобы она не утекала в другие локации.
	GameManager.disable_movement = false
	GameManager.is_minigame_active = false
	GameManager.minigame_pause_target = null


func _on_puzzle_exit_requested() -> void:
	# По запросу мини-игры просто сворачиваем ее и возвращаем игрока в локацию.
	close_samples_puzzle()


func _on_puzzle_completed() -> void:
	# Успешное завершение пазла фиксируем во флагах GameManager, чтобы его нельзя было запускать повторно.
	GameManager.set_done(PUZZLE_COMPLETION_FLAG)
