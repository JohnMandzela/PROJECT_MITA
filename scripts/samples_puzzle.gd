extends Control


signal exit_requested
signal puzzle_completed


const GRID_COLUMNS := 7
const GRID_ROWS := 6
const PALETTE_COUNT := 6
const TOTAL_CELLS := GRID_COLUMNS * GRID_ROWS
const PROGRESS_TARGET_SCORE := 30
const MAX_WALL_COUNT := int(floor(float(TOTAL_CELLS) / 5.0))
const BOARD_CELL_SIZE := Vector2(68, 68)
const PALETTE_CELL_SIZE := Vector2(60, 60)
const SPREAD_TARGET_COUNT := 2
const SPREAD_PREVIEW_DURATION := 1.0
const SPREAD_PREVIEW_STEP := 0.16
const BASE_YELLOW_ZONE_SIZE := 3
const FIRST_SOURCE_CHANCE_STEP := 20.0
const BOMB_PALETTE_CHANCE := 0.12
const INITIAL_SOURCE_CHANCE := 0.2

const TILE_NONE := 0
const TILE_GREEN := 1
const TILE_RED := 2
const TILE_YELLOW := 3
const TILE_VIRUS := 4
const TILE_INFECTED := 5
const TILE_BOMB := 6
const TILE_WALL := 7

const CELL_EMPTY := 0
const CELL_PENDING := 1
const CELL_COMMITTED := 2

const PANEL_DARK := Color(0.2627451, 0.2627451, 0.2627451, 1.0)
const PANEL_HOVER := Color(0.30980393, 0.30980393, 0.30980393, 1.0)
const PANEL_BORDER := Color(0.101960786, 0.101960786, 0.101960786, 1.0)
const BACKGROUND_COLOR := Color(0.11372549, 0.11372549, 0.11372549, 1.0)

const ACTIVE_GREEN := Color(0.23529412, 0.6862745, 0.36078432, 1.0)
const ACTIVE_GREEN_DARK := Color(0.15294118, 0.5372549, 0.28627452, 1.0)
const COMMITTED_GREEN := Color(0.043137256, 0.49019608, 0.14509805, 1.0)

const ACTIVE_RED := Color(1.0, 0.3764706, 0.40392157, 1.0)
const ACTIVE_RED_DARK := Color(0.75686276, 0.27450982, 0.28627452, 1.0)
const COMMITTED_RED := Color(0.7490196, 0.28627452, 0.28627452, 1.0)

const ACTIVE_YELLOW := Color(0.98039216, 0.8627451, 0.40392157, 1.0)
const ACTIVE_YELLOW_DARK := Color(0.69411767, 0.59607846, 0.20392157, 1.0)
const COMMITTED_YELLOW := Color(0.6901961, 0.6117647, 0.20392157, 1.0)

const ACTIVE_PURPLE := Color(0.46666667, 0.21960784, 0.9019608, 1.0)
const ACTIVE_PURPLE_DARK := Color(0.36078432, 0.15294118, 0.7176471, 1.0)
const COMMITTED_PURPLE := Color(0.39607844, 0.18039216, 0.7607843, 1.0)
const ACTIVE_BOMB := Color(0.4509804, 0.12156863, 0.12156863, 1.0)
const ACTIVE_BOMB_DARK := Color(0.30980393, 0.08235294, 0.08235294, 1.0)
const COMMITTED_WALL := Color(0.53333336, 0.53333336, 0.53333336, 1.0)
const WALL_HATCH_COLOR := Color(0.86, 0.86, 0.86, 0.72)

const PREVIEW_GREEN := Color(0.23529412, 0.6862745, 0.36078432, 0.55)
const SELECTED_BORDER := Color(0.7411765, 0.9607843, 0.8235294, 1.0)
const TEXT_LIGHT := Color(0.96, 0.96, 0.96, 1.0)
const PROGRESS_LABEL_DISPLAY_TIME := 2.0
const SUCCESS_TEXT := "\u0423\u0441\u043f\u0435\u0445! \u041a\u043e\u0434 \u043f\u0440\u043e\u0448\u0435\u043b \u043e\u0442\u043b\u0430\u0434\u043a\u0443. \u0411\u0430\u0433\u0438 \u0438\u0441\u043f\u0440\u0430\u0432\u043b\u0435\u043d\u044b."
const VIRUS_OVERFLOW_TEXT := "\u0412\u041d\u0418\u041c\u0410\u041d\u0418\u0415! \u0417\u0410\u0420\u0410\u0416\u0415\u041d\u0418\u0415 \u0424\u0410\u0419\u041b\u041e\u0412!"
const MEMORY_OVERFLOW_TEXT := "\u0412\u041d\u0418\u041c\u0410\u041d\u0418\u0415! \u041d\u0435\u0445\u0432\u0430\u0442\u043a\u0430 \u0441\u0432\u043e\u0431\u043e\u0434\u043d\u043e\u0439 \u043f\u0430\u043c\u044f\u0442\u0438. \u041e\u0447\u0438\u0441\u0442\u0438\u0442\u0435 \u043c\u0435\u0441\u0442\u043e, \u0447\u0442\u043e\u0431\u044b \u043f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c."
const RESTART_TEXT := "\u041d\u0430\u0447\u0430\u0442\u044c \u0437\u0430\u043d\u043e\u0432\u043e"
const FINISH_TEXT := "\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u044c"
const PAUSE_TITLE_TEXT := "\u0412\u044b\u0439\u0442\u0438 \u0438\u0437 \u043f\u0440\u043e\u0433\u0440\u0430\u043c\u043c\u044b? \u041d\u0435\u0441\u043e\u0445\u0440\u0430\u043d\u0435\u043d\u043d\u044b\u0439 \u043f\u0440\u043e\u0433\u0440\u0435\u0441\u0441 \u0431\u0443\u0434\u0435\u0442 \u043f\u043e\u0442\u0435\u0440\u044f\u043d"
const PAUSE_EXIT_TEXT := "\u0412\u044b\u0439\u0442\u0438"
const PAUSE_CONTINUE_TEXT := "\u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c"
const UNDO_TEXT := "\u041d\u0430\u0437\u0430\u0434"
const CLEAR_TEXT := "\u041e\u0447\u0438\u0441\u0442\u0438\u0442\u044c"
const NEXT_TEXT := "\u0421\u043b\u0435\u0434\u0443\u044e\u0449\u0438\u0439 \u0445\u043e\u0434"

const ROUND_PALETTES := [
	[TILE_GREEN, TILE_GREEN, TILE_GREEN, TILE_GREEN, TILE_GREEN, TILE_GREEN],
	[TILE_GREEN, TILE_GREEN, TILE_GREEN, TILE_RED, TILE_GREEN, TILE_GREEN],
	[TILE_GREEN, TILE_RED, TILE_GREEN, TILE_GREEN, TILE_GREEN, TILE_GREEN],
	[TILE_RED, TILE_GREEN, TILE_GREEN, TILE_GREEN, TILE_GREEN, TILE_YELLOW],
	[TILE_GREEN, TILE_RED, TILE_GREEN, TILE_GREEN, TILE_YELLOW, TILE_GREEN],
	[TILE_GREEN, TILE_RED, TILE_GREEN, TILE_YELLOW, TILE_GREEN, TILE_RED],
]

const IMPACT_FONT := preload("res://fonts/Impact.otf")
const VIRUS_TEXTURE := preload("res://images/virus.png")
const BOMB_TEXTURE := preload("res://images/bomb.png")


@onready var background: ColorRect = $Background
@onready var board_grid: GridContainer = $CenterContainer/ContentMargin/MainRow/BoardColumn/BoardFrame/BoardMargin/BoardGrid
@onready var red_zone_overlay: Control = $CenterContainer/ContentMargin/MainRow/BoardColumn/BoardFrame/BoardMargin/RedZoneOverlay
@onready var yellow_zone_overlay: Control = $CenterContainer/ContentMargin/MainRow/BoardColumn/BoardFrame/BoardMargin/YellowZoneOverlay
@onready var bomb_zone_overlay: Control = $CenterContainer/ContentMargin/MainRow/BoardColumn/BoardFrame/BoardMargin/BombZoneOverlay
@onready var progress_track: Panel = $CenterContainer/ContentMargin/MainRow/BoardColumn/ProgressTrack
@onready var progress_fill: ColorRect = $CenterContainer/ContentMargin/MainRow/BoardColumn/ProgressTrack/ProgressFill
@onready var progress_preview: ColorRect = $CenterContainer/ContentMargin/MainRow/BoardColumn/ProgressTrack/ProgressPreview
@onready var progress_label: Label = $CenterContainer/ContentMargin/MainRow/BoardColumn/ProgressTrack/ProgressLabel
@onready var palette_grid: GridContainer = $CenterContainer/ContentMargin/MainRow/Sidebar/PaletteGrid
@onready var undo_button: Button = $CenterContainer/ContentMargin/MainRow/Sidebar/ActionButtons/Undo
@onready var clear_button: Button = $CenterContainer/ContentMargin/MainRow/Sidebar/ActionButtons/Clear
@onready var next_button: Button = $CenterContainer/ContentMargin/MainRow/Sidebar/ActionButtons/Next
@onready var modal_blur: ColorRect = $ModalBlur
@onready var success_overlay: Control = $SuccessOverlay
@onready var restart_button: Button = $SuccessOverlay/SuccessPanel/SuccessMargin/SuccessVBox/RestartButton
@onready var success_label: Label = $SuccessOverlay/SuccessPanel/SuccessMargin/SuccessVBox/SuccessLabel
@onready var finish_button: Button = $SuccessOverlay/SuccessPanel/SuccessMargin/SuccessVBox/FinishButton
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_label: Label = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseLabel
@onready var pause_exit_button: Button = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseExitButton
@onready var pause_continue_button: Button = $PauseOverlay/PausePanel/PauseMargin/PauseVBox/PauseContinueButton


var board_state: Array[int] = []
var board_tile_types: Array[int] = []
var board_scores: Array[int] = []
var board_virus_owner_ids: Array[int] = []
var palette_types: Array[int] = []
var palette_available: Array[bool] = []
var board_buttons: Array[Button] = []
var board_labels: Array[Label] = []
var board_icons: Array[TextureRect] = []
var palette_buttons: Array[Button] = []
var palette_icons: Array[TextureRect] = []
var placement_history: Array[Dictionary] = []
var active_yellow_zone_effects: Array[Dictionary] = []
var active_bomb_zone_effects: Array[Dictionary] = []
var pending_infection_indices: Array[int] = []
var pending_infection_owner_ids: Array[int] = []
var active_red_zone_rects: Array[Rect2] = []
var active_yellow_zone_rects: Array[Rect2] = []
var active_bomb_zone_rects: Array[Rect2] = []
var bomb_freed_indices: Array[int] = []
var pending_bomb_indices: Array[int] = []
var pending_source_spawn_index := -1
var selected_palette_index := -1
var committed_score := 0
var round_index := 0
var next_source_id := 1
var turns_since_game_start := 0
var turns_since_last_source := 0
var has_spawned_any_source := false
var transient_progress_value := 0
var progress_label_request_id := 0
var show_transient_progress_label := false
var pending_infection_flash_on := true
var pending_source_flash_on := true
var pending_bomb_flash_on := true
var is_resolving_turn := false
var is_game_over := false
var can_finish_after_success := false
var virus_texture: Texture2D
var bomb_texture: Texture2D
var rng := RandomNumberGenerator.new()

var debug_forced_spawn_rolls: Array = []
var debug_forced_spawn_indices: Array = []
var debug_forced_spread_targets: Array = []
var debug_forced_wall_indices: Array = []
var debug_disable_random_walls := false
var debug_forced_bomb_palette_slot := -1
var debug_forced_start_palette: Array = []
var debug_forced_palette_layout: Array = []
var debug_disable_initial_source := false
var debug_forced_initial_source_index := -1


func _ready() -> void:
	# Настраиваем базовые визуальные параметры сцены и тексты popup-окна.
	background.color = BACKGROUND_COLOR
	progress_fill.color = ACTIVE_GREEN
	progress_preview.color = PREVIEW_GREEN
	undo_button.text = UNDO_TEXT
	clear_button.text = CLEAR_TEXT
	next_button.text = NEXT_TEXT
	success_label.text = SUCCESS_TEXT
	restart_button.text = RESTART_TEXT
	finish_button.text = FINISH_TEXT
	finish_button.visible = false
	pause_label.text = PAUSE_TITLE_TEXT
	pause_exit_button.text = PAUSE_EXIT_TEXT
	pause_continue_button.text = PAUSE_CONTINUE_TEXT
	virus_texture = _load_virus_texture()
	bomb_texture = _load_bomb_texture()
	rng.randomize()

	# Создаем динамические кнопки поля и палитры, а затем подключаем overlay-зоны.
	_build_board()
	_build_palette()
	_configure_zone_overlays()

	# Подключаем обработчики управления и обновления интерфейса.
	undo_button.pressed.connect(_on_undo_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	pause_exit_button.pressed.connect(_on_pause_exit_pressed)
	pause_continue_button.pressed.connect(_on_pause_continue_pressed)
	progress_track.resized.connect(_update_progress_bar)
	red_zone_overlay.resized.connect(_update_zone_overlays)
	yellow_zone_overlay.resized.connect(_update_zone_overlays)
	bomb_zone_overlay.resized.connect(_update_zone_overlays)

	# Полностью сбрасываем головоломку и синхронизируем прогресс-бар после создания сцены.
	_restart_puzzle()
	call_deferred("_update_progress_bar")


func _build_board() -> void:
	# Создаем все клетки игрового поля и сразу добавляем в них спрайт вируса и текстовый слой.
	for index in range(TOTAL_CELLS):
		var cell: Button = Button.new()
		# Настраиваем саму кнопку клетки.
		cell.focus_mode = Control.FOCUS_NONE
		cell.custom_minimum_size = BOARD_CELL_SIZE
		cell.clip_contents = true
		cell.pressed.connect(_on_board_cell_pressed.bind(index))

		var icon: TextureRect = TextureRect.new()
		# Готовим спрайт вируса, который будет включаться только у клетки-источника.
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.visible = false
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 7.0
		icon.offset_top = 7.0
		icon.offset_right = -7.0
		icon.offset_bottom = -7.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = virus_texture

		var label: Label = Label.new()
		# Готовим текст для очков и вспомогательных значений внутри клетки.
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", IMPACT_FONT)
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", TEXT_LIGHT)

		# Собираем визуальные слои клетки и сохраняем ссылки для дальнейших обновлений.
		cell.add_child(icon)
		cell.add_child(label)
		board_grid.add_child(cell)
		board_buttons.append(cell)
		board_icons.append(icon)
		board_labels.append(label)


func _build_palette() -> void:
	# Создаем шесть кнопок палитры, из которых игрок выбирает фигуры текущего хода.
	for index in range(PALETTE_COUNT):
		var button: Button = Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = PALETTE_CELL_SIZE
		button.pressed.connect(_on_palette_slot_pressed.bind(index))
		var icon: TextureRect = TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.visible = false
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 6.0
		icon.offset_top = 6.0
		icon.offset_right = -6.0
		icon.offset_bottom = -6.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = bomb_texture
		button.add_child(icon)
		palette_grid.add_child(button)
		palette_buttons.append(button)
		palette_icons.append(icon)


func _configure_zone_overlays() -> void:
	# Назначаем визуальный стиль красной зоны усиления.
	red_zone_overlay.call(
		"set_style",
		Color(1.0, 0.3764706, 0.40392157, 0.2),
		Color(0.8509804, 0.27058825, 0.28627452, 0.85)
	)
	# Назначаем визуальный стиль желтой защитной зоны.
	yellow_zone_overlay.call(
		"set_style",
		Color(0.98039216, 0.8627451, 0.40392157, 0.18),
		Color(1.0, 0.84313726, 0.23921569, 0.95)
	)
	# Назначаем визуальный стиль темно-красной зоны бомбы.
	bomb_zone_overlay.call(
		"set_style",
		Color(0.4509804, 0.12156863, 0.12156863, 0.2),
		Color(0.8509804, 0.27058825, 0.28627452, 0.85)
	)


func _initialize_board() -> void:
	# Полностью очищаем служебные массивы поля перед новым запуском сцены.
	board_state.clear()
	board_tile_types.clear()
	board_scores.clear()
	board_virus_owner_ids.clear()
	for _unused in range(TOTAL_CELLS):
		# Для каждой клетки подготавливаем пустое состояние, тип, очки и владельца вируса.
		board_state.append(CELL_EMPTY)
		board_tile_types.append(TILE_NONE)
		board_scores.append(0)
		board_virus_owner_ids.append(-1)


func _restart_puzzle() -> void:
	# Сбрасываем все игровые счетчики, таймеры и модальные состояния.
	committed_score = 0
	round_index = 0
	next_source_id = 1
	turns_since_game_start = 0
	turns_since_last_source = 0
	has_spawned_any_source = false
	selected_palette_index = -1
	transient_progress_value = 0
	show_transient_progress_label = false
	progress_label_request_id += 1
	pending_infection_flash_on = true
	pending_source_flash_on = true
	pending_bomb_flash_on = true
	pending_source_spawn_index = -1
	is_resolving_turn = false
	is_game_over = false
	can_finish_after_success = false
	success_overlay.visible = false
	pause_overlay.visible = false
	success_label.text = SUCCESS_TEXT
	restart_button.text = RESTART_TEXT
	finish_button.visible = false
	placement_history.clear()
	active_yellow_zone_effects.clear()
	active_bomb_zone_effects.clear()
	pending_infection_indices.clear()
	pending_infection_owner_ids.clear()
	active_red_zone_rects.clear()
	active_yellow_zone_rects.clear()
	active_bomb_zone_rects.clear()
	bomb_freed_indices.clear()
	pending_bomb_indices.clear()

	# Переинициализируем поле и заново загружаем стартовую палитру.
	_initialize_board()
	_generate_walls()
	_load_palette_for_round()
	_maybe_spawn_initial_source()
	_update_modal_layers()
	_update_ui()


func _load_palette_for_round() -> void:
	# Очищаем текущую палитру и снимаем выделение перед новым ходом.
	palette_types.clear()
	palette_available.clear()
	selected_palette_index = -1

	var layout: Array[int] = _get_palette_layout()
	for tile_type in layout:
		# Переносим типы фигур текущего раунда в рабочие массивы палитры.
		palette_types.append(tile_type)
		palette_available.append(true)
	_inject_bomb_into_palette()


func _get_palette_layout() -> Array[int]:
	# Возвращаем набор фигур для текущего раунда с ограничением по последнему шаблону.
	var layout: Array[int] = []
	if not debug_forced_palette_layout.is_empty():
		for tile_type in debug_forced_palette_layout:
			layout.append(int(tile_type))
		return layout
	if round_index == 0:
		var start_layout: Array = debug_forced_start_palette if not debug_forced_start_palette.is_empty() else _build_random_start_palette()
		for tile_type in start_layout:
			layout.append(int(tile_type))
		return layout
	var layout_index: int = mini(round_index, ROUND_PALETTES.size() - 1)
	var source_layout: Array = ROUND_PALETTES[layout_index]
	for tile_type in source_layout:
		layout.append(int(tile_type))
	_shuffle_int_array(layout)
	return layout


func _build_random_start_palette() -> Array[int]:
	var layout: Array[int] = [TILE_GREEN, TILE_GREEN, TILE_GREEN]
	var special_pool: Array[int] = [TILE_GREEN, TILE_GREEN, TILE_RED, TILE_YELLOW]
	while layout.size() < PALETTE_COUNT:
		layout.append(special_pool[rng.randi_range(0, special_pool.size() - 1)])
	_shuffle_int_array(layout)
	return layout


func _shuffle_int_array(values: Array[int]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var cached_value: int = values[index]
		values[index] = values[swap_index]
		values[swap_index] = cached_value


func _inject_bomb_into_palette() -> void:
	# С небольшой вероятностью заменяем одну зеленую фигуру в палитре на бомбу.
	var target_slot := -1
	if debug_forced_bomb_palette_slot >= 0:
		target_slot = debug_forced_bomb_palette_slot
	elif rng.randf() < BOMB_PALETTE_CHANCE:
		var green_slots: Array[int] = []
		for index in range(palette_types.size()):
			if palette_types[index] == TILE_GREEN:
				green_slots.append(index)
		if not green_slots.is_empty():
			target_slot = green_slots[rng.randi_range(0, green_slots.size() - 1)]

	if target_slot >= 0 and target_slot < palette_types.size():
		palette_types[target_slot] = TILE_BOMB


func _generate_walls() -> void:
	# В начале партии создаем немного серых стен, которые блокируют поле и спавн вируса.
	if not debug_forced_wall_indices.is_empty():
		for index_value in debug_forced_wall_indices:
			_place_wall(int(index_value))
		return
	if debug_disable_random_walls:
		return

	var target_walls: int = rng.randi_range(4, MAX_WALL_COUNT)
	var attempts := 0
	while _count_walls() < target_walls and attempts < 64:
		attempts += 1
		var horizontal: bool = rng.randf() < 0.5
		var segment_length: int = rng.randi_range(2, 3)
		var start_row: int = rng.randi_range(0, GRID_ROWS - 1)
		var start_column: int = rng.randi_range(0, GRID_COLUMNS - 1)
		var segment_indices: Array[int] = []
		var fits := true
		for offset in range(segment_length):
			var row := start_row + (0 if horizontal else offset)
			var column := start_column + (offset if horizontal else 0)
			if row >= GRID_ROWS or column >= GRID_COLUMNS:
				fits = false
				break
			var board_index: int = row * GRID_COLUMNS + column
			if board_state[board_index] != CELL_EMPTY:
				fits = false
				break
			segment_indices.append(board_index)
		if not fits:
			continue
		if _count_walls() + segment_indices.size() > MAX_WALL_COUNT:
			continue
		for board_index in segment_indices:
			_place_wall(board_index)


func _count_walls() -> int:
	# Подсчитываем текущее количество стен на поле для ограничения генерации.
	var wall_count := 0
	for tile_type in board_tile_types:
		if tile_type == TILE_WALL:
			wall_count += 1
	return wall_count


func _place_wall(index: int) -> void:
	# Переводим клетку в состояние серой стены.
	if index < 0 or index >= TOTAL_CELLS:
		return
	board_state[index] = CELL_COMMITTED
	board_tile_types[index] = TILE_WALL
	board_scores[index] = 0
	board_virus_owner_ids[index] = -1


func _maybe_spawn_initial_source() -> void:
	if debug_disable_initial_source:
		return

	var candidates: Array[int] = _get_source_spawn_candidates()
	if candidates.is_empty():
		return

	var spawn_index := -1
	if debug_forced_initial_source_index >= 0:
		if candidates.has(debug_forced_initial_source_index):
			spawn_index = debug_forced_initial_source_index
	elif rng.randf() < INITIAL_SOURCE_CHANCE:
		spawn_index = _choose_source_spawn_index(candidates)

	if spawn_index < 0:
		return

	_place_virus_source_without_penalty(spawn_index)


func _place_virus_source_without_penalty(spawn_index: int) -> void:
	var owner_id: int = next_source_id
	next_source_id += 1
	board_state[spawn_index] = CELL_COMMITTED
	board_tile_types[spawn_index] = TILE_VIRUS
	board_scores[spawn_index] = 0
	board_virus_owner_ids[spawn_index] = owner_id
	has_spawned_any_source = true
	turns_since_last_source = 0


func _unhandled_input(event: InputEvent) -> void:
	# Escape внутри мини-игры открывает локальное окно выхода и не отдает управление общему pause menu сцены.
	if not visible:
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if success_overlay.visible:
		return
	if pause_overlay.visible:
		_close_pause_overlay()
	else:
		_open_pause_overlay()
	get_viewport().set_input_as_handled()


func _open_pause_overlay() -> void:
	# Во время анимаций системного хода и после финала локальную паузу не показываем.
	if is_resolving_turn:
		return
	if is_game_over:
		return
	pause_overlay.visible = true
	_update_modal_layers()


func _close_pause_overlay() -> void:
	# Закрываем локальный pause-overlay и возвращаем фокус мини-игре.
	pause_overlay.visible = false
	_update_modal_layers()


func _update_modal_layers() -> void:
	# Общий blur-слой включаем для локальной паузы и финальных окон выигрыша/проигрыша.
	modal_blur.visible = pause_overlay.visible or success_overlay.visible


func toggle_pause_overlay_from_pause_menu() -> void:
	# Глобальное pause menu перенаправляет Escape сюда, если в данный момент активна мини-игра.
	if not visible:
		return
	if success_overlay.visible:
		return
	if pause_overlay.visible:
		_close_pause_overlay()
	else:
		_open_pause_overlay()


func _on_palette_slot_pressed(index: int) -> void:
	# Во время разрешения хода и после финала новые действия игрока запрещены.
	if is_resolving_turn:
		return
	if is_game_over:
		return
	if not palette_available[index]:
		return

	# Повторный клик снимает выбор, иначе выделяем новую ячейку палитры.
	if selected_palette_index == index:
		selected_palette_index = -1
	else:
		selected_palette_index = index

	_update_ui()


func _on_board_cell_pressed(index: int) -> void:
	# Не позволяем размещать фигуры во время разрешения хода и после завершения партии.
	if is_resolving_turn:
		return
	if is_game_over:
		return
	if pause_overlay.visible:
		return
	if selected_palette_index == -1:
		return
	if board_state[index] != CELL_EMPTY:
		return

	# Переносим выбранный тип из палитры на игровое поле как pending-клетку.
	var tile_type: int = palette_types[selected_palette_index]
	board_state[index] = CELL_PENDING
	board_tile_types[index] = tile_type
	board_scores[index] = 0
	board_virus_owner_ids[index] = -1
	palette_available[selected_palette_index] = false
	placement_history.append(
		{
			"board_index": index,
			"palette_index": selected_palette_index,
			"tile_type": tile_type,
		}
	)
	selected_palette_index = -1
	# После установки пересчитываем зоны, очки и доступность управления.
	_update_ui()


func _on_undo_pressed() -> void:
	# Undo нельзя выполнять во время анимации хода, после финала или при пустой истории.
	if is_resolving_turn:
		return
	if is_game_over:
		return
	if pause_overlay.visible:
		return
	if placement_history.is_empty():
		return

	# Возвращаем последнюю поставленную клетку обратно в палитру.
	var last_placement: Dictionary = placement_history.pop_back()
	var board_index: int = int(last_placement.get("board_index", -1))
	var palette_index: int = int(last_placement.get("palette_index", -1))

	if board_index >= 0:
		_clear_board_cell(board_index)
	if palette_index >= 0:
		palette_available[palette_index] = true

	# После возврата снимаем выбор, чтобы ячейка не оставалась активной.
	selected_palette_index = -1
	_update_ui()


func _on_clear_pressed() -> void:
	# Clear тоже не должен работать в середине системного хода или после финала.
	if is_resolving_turn:
		return
	if is_game_over:
		return
	# Проходим по истории текущего раунда и очищаем только незакоммиченные клетки.
	for placement in placement_history:
		var board_index: int = int(placement.get("board_index", -1))
		if board_index >= 0:
			_clear_board_cell(board_index)
	placement_history.clear()
	selected_palette_index = -1
	# После очистки выдаем тот же набор фигур заново и обновляем интерфейс.
	_load_palette_for_round()
	_update_ui()


func _on_next_pressed() -> void:
	# Запрещаем повторный запуск Next, если ход уже обрабатывается или игра завершена.
	if is_resolving_turn:
		return
	if is_game_over:
		return

	# Блокируем ввод игрока на время подсчета очков, очистки и распространения вируса.
	is_resolving_turn = true
	selected_palette_index = -1

	# Сначала фиксируем действия игрока и начисляем/списываем очки за текущий раунд.
	var turn_delta: int = _commit_player_turn()
	if turn_delta != 0:
		_display_transient_progress_value(turn_delta)
	_update_ui()

	# После подсчета очков даем бомбам мигнуть и очистить свои зоны.
	var bomb_delta: int = await _preview_and_apply_bombs()
	if bomb_delta != 0:
		_display_transient_progress_value(bomb_delta)
	_update_ui()

	# Затем даем желтым зонам очистить попавшие внутрь вирусные клетки.
	_apply_active_yellow_cleanup()
	_update_ui()

	# После очистки запускаем фазу распространения вируса и ее мигающий предпросмотр.
	var spread_entries: Array[Dictionary] = _build_spread_entries()
	if not spread_entries.is_empty():
		await _preview_spread_entries(spread_entries)
		var spread_delta: int = _commit_spread_entries(spread_entries)
		if spread_delta != 0:
			_display_transient_progress_value(spread_delta)
		_update_ui()

	# Отсчитываем ход для вероятности нового источника и при необходимости спавним его.
	if has_spawned_any_source:
		turns_since_last_source += 1
	else:
		turns_since_game_start += 1
	var source_delta: int = await _resolve_virus_source_spawn()
	if source_delta != 0:
		_display_transient_progress_value(source_delta)

	# Завершаем ход: убираем одноходовую желтую защиту, выдаем новую палитру и проверяем финалы.
	active_yellow_zone_effects.clear()
	active_bomb_zone_effects.clear()
	bomb_freed_indices.clear()
	round_index += 1
	_load_palette_for_round()
	is_resolving_turn = false
	_update_ui()
	_check_for_end_state()


func _commit_player_turn() -> int:
	# Перед фиксацией хода запоминаем желтые зоны, которые должны пережить этот цикл вируса.
	active_yellow_zone_effects = _build_yellow_zone_effects(_get_pending_yellow_indices())
	# Отдельно запоминаем зоны бомб, чтобы взорвать их после начисления очков.
	active_bomb_zone_effects = _build_bomb_zone_effects(_get_pending_bomb_indices())
	pending_bomb_indices = _get_pending_bomb_indices()

	# Считаем суммарный вклад всех pending-зеленых клеток в текущем ходе.
	var delta: int = _get_current_pending_total()
	committed_score = maxi(0, committed_score + delta)

	# После подсчета переводим поставленные игроком клетки в committed-состояние.
	for placement in placement_history:
		var board_index: int = int(placement.get("board_index", -1))
		if board_index >= 0:
			board_state[board_index] = CELL_COMMITTED

	placement_history.clear()
	return delta


func _apply_active_yellow_cleanup() -> void:
	# Если активной защиты нет, то и очищать нечего.
	if active_yellow_zone_effects.is_empty():
		return

	# Удаляем все вирусные клетки, которые попали внутрь только что активированной желтой зоны.
	for effect in active_yellow_zone_effects:
		for index in range(TOTAL_CELLS):
			if not _zone_effect_contains_index(effect, index):
				continue
			if board_tile_types[index] != TILE_VIRUS and board_tile_types[index] != TILE_INFECTED:
				continue
			_clear_board_cell(index)


func _preview_and_apply_bombs() -> int:
	# Если активных бомб нет, сразу завершаем фазу без изменений.
	if active_bomb_zone_effects.is_empty():
		pending_bomb_indices.clear()
		return 0

	# Сначала мигаем самими бомбами, а затем очищаем все клетки в их зонах.
	var blink_steps: int = maxi(1, int(round(SPREAD_PREVIEW_DURATION / SPREAD_PREVIEW_STEP)))
	for blink_step in range(blink_steps):
		pending_bomb_flash_on = blink_step % 2 == 0
		_update_ui()
		await get_tree().create_timer(SPREAD_PREVIEW_STEP).timeout

	pending_bomb_flash_on = true
	var cleared_indices: Array[int] = _collect_bomb_cleared_indices()
	var freed_indices: Array[int] = _collect_bomb_freed_empty_indices(cleared_indices)
	for board_index in cleared_indices:
		_clear_board_cell(board_index)
	bomb_freed_indices = freed_indices
	pending_bomb_indices.clear()
	active_bomb_zone_effects.clear()
	active_bomb_zone_rects.clear()
	_update_zone_overlays()
	_update_ui()
	return 0


func _collect_bomb_cleared_indices() -> Array[int]:
	# Собираем все непустые клетки, попавшие хотя бы в одну зону взрыва.
	var cleared_indices: Array[int] = []
	for effect in active_bomb_zone_effects:
		for index in range(TOTAL_CELLS):
			if not _zone_effect_contains_index(effect, index):
				continue
			if board_state[index] == CELL_EMPTY:
				continue
			if not cleared_indices.has(index):
				cleared_indices.append(index)
	return cleared_indices


func _collect_bomb_freed_empty_indices(cleared_indices: Array[int]) -> Array[int]:
	# Отмечаем только те клетки, которые стали свободными именно из-за взрыва.
	var freed_indices: Array[int] = []
	for board_index in cleared_indices:
		if board_tile_types[board_index] == TILE_WALL:
			continue
		freed_indices.append(board_index)
	return freed_indices


func _build_spread_entries() -> Array[Dictionary]:
	# Собираем будущие заражения по каждому активному источнику отдельно.
	var entries: Array[Dictionary] = []
	var reserved_indices: Array[int] = []
	for source_id in _get_active_source_ids():
		# Для каждого источника берем не больше двух клеток, не занятых уже другим spread-резервом.
		var candidates: Array[int] = _get_spread_candidates_for_owner(source_id, reserved_indices)
		var chosen_targets: Array[int] = _choose_spread_targets(candidates)
		for board_index in chosen_targets:
			reserved_indices.append(board_index)
			entries.append(
				{
					"board_index": board_index,
					"owner_id": source_id,
				}
			)
	return entries


func _get_active_source_ids() -> Array[int]:
	# Находим все уникальные идентификаторы источников вируса на поле.
	var source_ids: Array[int] = []
	for index in range(TOTAL_CELLS):
		if board_state[index] != CELL_COMMITTED:
			continue
		if board_tile_types[index] != TILE_VIRUS:
			continue
		var owner_id: int = board_virus_owner_ids[index]
		if owner_id >= 0 and not source_ids.has(owner_id):
			source_ids.append(owner_id)
	return source_ids


func _get_spread_candidates_for_owner(owner_id: int, reserved_indices: Array[int]) -> Array[int]:
	# Собираем клетки, в которые можно распространить конкретный вирусный кластер.
	var high_priority_candidates: Array[int] = []
	var low_priority_candidates: Array[int] = []
	for cluster_index in _get_virus_cluster_indices(owner_id):
		for neighbor in _get_orthogonal_neighbors(cluster_index):
			# Не даем разным источникам претендовать на одну и ту же клетку в этом ходе.
			if reserved_indices.has(neighbor):
				continue
			# Исключаем дубли из списка кандидатов.
			if high_priority_candidates.has(neighbor) or low_priority_candidates.has(neighbor):
				continue
			# Желтая зона блокирует заражение до завершения текущего хода.
			if _is_in_active_yellow_zone(neighbor):
				continue
			# Не заражаем уже зараженные клетки, источники, стены, желтые клетки и бомбы.
			if (
				board_tile_types[neighbor] == TILE_VIRUS
				or board_tile_types[neighbor] == TILE_INFECTED
				or board_tile_types[neighbor] == TILE_WALL
				or board_tile_types[neighbor] == TILE_YELLOW
				or board_tile_types[neighbor] == TILE_BOMB
			):
				continue
			# Свободные клетки после взрыва считаем менее приоритетными, чем нетронутые цели.
			if board_state[neighbor] == CELL_EMPTY and bomb_freed_indices.has(neighbor):
				low_priority_candidates.append(neighbor)
				continue
			# Разрешаем заражать как пустые, так и занятые зелёные/красные клетки.
			if board_state[neighbor] == CELL_EMPTY or board_tile_types[neighbor] == TILE_GREEN or board_tile_types[neighbor] == TILE_RED:
				high_priority_candidates.append(neighbor)
	if not high_priority_candidates.is_empty():
		return high_priority_candidates
	return low_priority_candidates


func _get_virus_cluster_indices(owner_id: int) -> Array[int]:
	# Возвращаем все клетки, принадлежащие одному источнику: сам источник и зараженные им поля.
	var cluster_indices: Array[int] = []
	for index in range(TOTAL_CELLS):
		if board_state[index] == CELL_EMPTY:
			continue
		if board_virus_owner_ids[index] != owner_id:
			continue
		if board_tile_types[index] == TILE_VIRUS or board_tile_types[index] == TILE_INFECTED:
			cluster_indices.append(index)
	return cluster_indices


func _choose_spread_targets(candidates: Array[int]) -> Array[int]:
	# Пустой список кандидатов сразу завершает выбор.
	var selected: Array[int] = []
	if candidates.is_empty():
		return selected

	# В тестах используем заранее заданные цели заражения, чтобы сценарий был детерминированным.
	if not debug_forced_spread_targets.is_empty():
		var forced_targets: Variant = debug_forced_spread_targets.pop_front()
		if forced_targets is Array:
			for value in forced_targets:
				var forced_index: int = int(value)
				if candidates.has(forced_index) and not selected.has(forced_index):
					selected.append(forced_index)
				if selected.size() >= min(SPREAD_TARGET_COUNT, candidates.size()):
					return selected

	# В обычной игре случайно берем до двух разных клеток из доступного списка.
	var remaining: Array[int] = candidates.duplicate()
	while not remaining.is_empty() and selected.size() < SPREAD_TARGET_COUNT:
		var choice_index: int = rng.randi_range(0, remaining.size() - 1)
		selected.append(remaining[choice_index])
		remaining.remove_at(choice_index)
	return selected


func _preview_spread_entries(entries: Array[Dictionary]) -> void:
	# Сохраняем будущие заражения, чтобы временно подсветить их миганием до фиксации.
	pending_infection_indices.clear()
	pending_infection_owner_ids.clear()
	for entry in entries:
		pending_infection_indices.append(int(entry.get("board_index", -1)))
		pending_infection_owner_ids.append(int(entry.get("owner_id", -1)))

	# В течение секунды попеременно включаем и выключаем фиолетовую подсветку preview-клеток.
	var blink_steps: int = maxi(1, int(round(SPREAD_PREVIEW_DURATION / SPREAD_PREVIEW_STEP)))
	for blink_step in range(blink_steps):
		pending_infection_flash_on = blink_step % 2 == 0
		_update_ui()
		await get_tree().create_timer(SPREAD_PREVIEW_STEP).timeout

	pending_infection_flash_on = true
	_update_ui()


func _commit_spread_entries(entries: Array[Dictionary]) -> int:
	# После предпросмотра окончательно превращаем выбранные клетки в зараженные.
	var delta := 0
	for entry in entries:
		var board_index: int = int(entry.get("board_index", -1))
		var owner_id: int = int(entry.get("owner_id", -1))
		if board_index < 0:
			continue
		board_state[board_index] = CELL_COMMITTED
		board_tile_types[board_index] = TILE_INFECTED
		board_scores[board_index] = 0
		board_virus_owner_ids[board_index] = owner_id
		delta -= 2

	# Списываем суммарный штраф за все новые зараженные клетки и очищаем preview-состояние.
	committed_score = maxi(0, committed_score + delta)
	pending_infection_indices.clear()
	pending_infection_owner_ids.clear()
	pending_infection_flash_on = true
	return delta


func _resolve_virus_source_spawn() -> int:
	# Отдельно готовим появление источника, даем ему мигнуть и только потом фиксируем на поле.
	var spawn_index: int = _prepare_virus_source_spawn()
	if spawn_index < 0:
		return 0
	await _preview_source_spawn(spawn_index)
	return _commit_virus_source_spawn(spawn_index)


func _prepare_virus_source_spawn() -> int:
	# Сначала вычисляем шанс появления нового источника для текущего хода.
	var spawn_chance_percent: float = _get_source_spawn_chance_percent()
	if spawn_chance_percent <= 0.0:
		return -1

	var roll: float = _roll_spawn_percent()
	if roll >= spawn_chance_percent:
		return -1

	# Если шанс сработал, выбираем клетку и создаем новый источник вируса.
	var spawn_candidates: Array[int] = _get_source_spawn_candidates()
	if spawn_candidates.is_empty():
		return -1
	return _choose_source_spawn_index(spawn_candidates)


func _preview_source_spawn(spawn_index: int) -> void:
	# Перед появлением источника временно мигаем клеткой так же, как при spread-preview.
	pending_source_spawn_index = spawn_index
	var blink_steps: int = maxi(1, int(round(SPREAD_PREVIEW_DURATION / SPREAD_PREVIEW_STEP)))
	for blink_step in range(blink_steps):
		pending_source_flash_on = blink_step % 2 == 0
		_update_ui()
		await get_tree().create_timer(SPREAD_PREVIEW_STEP).timeout
	pending_source_flash_on = true
	_update_ui()


func _commit_virus_source_spawn(spawn_index: int) -> int:
	# После мигания окончательно создаем новый источник и списываем его штраф.
	var owner_id: int = next_source_id
	next_source_id += 1
	board_state[spawn_index] = CELL_COMMITTED
	board_tile_types[spawn_index] = TILE_VIRUS
	board_scores[spawn_index] = 0
	board_virus_owner_ids[spawn_index] = owner_id
	pending_source_spawn_index = -1
	has_spawned_any_source = true
	turns_since_last_source = 0
	committed_score = maxi(0, committed_score - 2)
	return -2


func _get_source_spawn_candidates() -> Array[int]:
	# Новый источник не появляется на занятых клетках, в стенах и в активной желтой защите.
	var candidates: Array[int] = []
	for index in range(TOTAL_CELLS):
		if board_state[index] != CELL_EMPTY:
			continue
		if _is_in_active_yellow_zone(index):
			continue
		if board_tile_types[index] == TILE_WALL:
			continue
		candidates.append(index)
	return candidates


func _choose_source_spawn_index(candidates: Array[int]) -> int:
	# В тестах можно принудительно указать клетку спавна, иначе берем случайную.
	if not debug_forced_spawn_indices.is_empty():
		var forced_index: int = debug_forced_spawn_indices.pop_front()
		if candidates.has(forced_index):
			return forced_index

	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _roll_spawn_percent() -> float:
	# Поддерживаем тестовый режим с фиксированными бросками шанса.
	if not debug_forced_spawn_rolls.is_empty():
		return debug_forced_spawn_rolls.pop_front()
	return rng.randf_range(0.0, 100.0)


func _get_source_spawn_chance_percent() -> float:
	# До первого вируса шанс растет на 20% за ход, а потом действует отдельная лестница.
	if not has_spawned_any_source:
		return minf(100.0, float(turns_since_game_start) * FIRST_SOURCE_CHANCE_STEP)
	match turns_since_last_source:
		0, 1:
			return 0.0
		2:
			return 0.5
		3:
			return 5.0
		4:
			return 25.0
		5:
			return 45.0
		_:
			return minf(100.0, 45.0 + 20.0 * float(turns_since_last_source - 5))


func _update_ui() -> void:
	# Сначала пересчитываем динамические очки и состояния, зависящие от текущего хода.
	_refresh_dynamic_effects()

	# Затем обновляем все клетки поля по их текущему визуальному состоянию.
	for index in range(board_buttons.size()):
		_sync_board_cell(index)

	# После поля синхронизируем палитру и кнопки действий.
	for index in range(palette_buttons.size()):
		_sync_palette_slot(index)

	undo_button.disabled = is_resolving_turn or placement_history.is_empty()
	clear_button.disabled = is_resolving_turn or placement_history.is_empty()
	next_button.disabled = is_resolving_turn or is_game_over
	_update_zone_overlays()
	_update_progress_bar()


func _refresh_dynamic_effects() -> void:
	# Полностью сбрасываем временные очки и пересчитываем их заново только для pending-зеленых клеток.
	_clear_dynamic_scores()
	_apply_green_scores()


func _clear_dynamic_scores() -> void:
	# Обнуляем динамические очки для всех клеток перед новым пересчетом.
	for index in range(TOTAL_CELLS):
		board_scores[index] = 0


func _apply_green_scores() -> void:
	# Для каждой pending-зеленой клетки рассчитываем итоговый множитель от всех красных зон.
	for index in range(TOTAL_CELLS):
		if not _is_pending_green(index):
			continue
		board_scores[index] = _get_green_score(index)


func _is_pending_green(index: int) -> bool:
	# Проверяем, что клетка является новой зелёной ячейкой текущего раунда.
	return board_state[index] == CELL_PENDING and board_tile_types[index] == TILE_GREEN


func _get_green_score(index: int) -> int:
	# Каждое пересечение красной зоны удваивает базовое значение зеленой клетки.
	var overlap_count: int = _get_pending_red_overlap_count(index)
	return int(pow(2.0, float(overlap_count)))


func _get_pending_red_overlap_count(index: int) -> int:
	# Считаем, в сколько красных зон одновременно попадает зеленая pending-клетка.
	var overlap_count := 0
	for red_index in _get_pending_red_indices():
		if _is_in_square_zone(index, red_index, 1, 1):
			overlap_count += 1
	return overlap_count


func _get_pending_red_indices() -> Array[int]:
	# Возвращаем список всех pending-красных усилителей на поле.
	var red_indices: Array[int] = []
	for index in range(TOTAL_CELLS):
		if board_state[index] == CELL_PENDING and board_tile_types[index] == TILE_RED:
			red_indices.append(index)
	return red_indices


func _get_pending_yellow_indices() -> Array[int]:
	# Возвращаем список желтых клеток, поставленных в текущем ходу.
	var yellow_indices: Array[int] = []
	for index in range(TOTAL_CELLS):
		if board_state[index] == CELL_PENDING and board_tile_types[index] == TILE_YELLOW:
			yellow_indices.append(index)
	return yellow_indices


func _get_pending_bomb_indices() -> Array[int]:
	# Возвращаем список бомб, которые игрок поставил в текущем раунде.
	var bomb_indices: Array[int] = []
	for index in range(TOTAL_CELLS):
		if board_state[index] == CELL_PENDING and board_tile_types[index] == TILE_BOMB:
			bomb_indices.append(index)
	return bomb_indices


func _build_yellow_zone_effects(indices: Array[int]) -> Array[Dictionary]:
	# Для каждой желтой клетки рассчитываем ее фактический размер защиты с учетом красных зон.
	var effects: Array[Dictionary] = []
	for index in indices:
		var overlap_count: int = _get_pending_red_overlap_count(index)
		var zone_size: int = BASE_YELLOW_ZONE_SIZE
		if overlap_count > 0:
			zone_size = 5 + overlap_count - 1
		effects.append(_make_zone_effect(index, zone_size))
	return effects


func _build_bomb_zone_effects(indices: Array[int]) -> Array[Dictionary]:
	# Строим зоны поражения бомб по тем же правилам усиления красными клетками.
	var effects: Array[Dictionary] = []
	for index in indices:
		var overlap_count: int = _get_pending_red_overlap_count(index)
		var zone_size: int = BASE_YELLOW_ZONE_SIZE
		if overlap_count > 0:
			zone_size = 5 + overlap_count - 1
		effects.append(_make_zone_effect(index, zone_size))
	return effects


func _make_zone_effect(center_index: int, zone_size: int) -> Dictionary:
	# Преобразуем размер зоны в удобную структуру с радиусами по строкам и столбцам.
	var span: int = zone_size - 1
	var radius_low: int = span / 2
	var radius_high: int = span - radius_low
	return {
		"center_index": center_index,
		"zone_size": zone_size,
		"radius_low": radius_low,
		"radius_high": radius_high,
	}


func _get_visible_yellow_zone_effects() -> Array[Dictionary]:
	# Во время хода показываем либо уже зафиксированную защиту, либо текущий pending-просмотр.
	if not active_yellow_zone_effects.is_empty():
		return active_yellow_zone_effects
	return _build_yellow_zone_effects(_get_pending_yellow_indices())


func _get_visible_bomb_zone_effects() -> Array[Dictionary]:
	# До взрыва показываем либо уже зафиксированные зоны бомб, либо текущий pending-просмотр.
	if not active_bomb_zone_effects.is_empty():
		return active_bomb_zone_effects
	return _build_bomb_zone_effects(_get_pending_bomb_indices())


func _is_in_active_yellow_zone(index: int) -> bool:
	# Проверяем, закрыта ли клетка активной желтой защитой в текущем разрешении хода.
	for effect in active_yellow_zone_effects:
		if _zone_effect_contains_index(effect, index):
			return true
	return false


func _zone_effect_contains_index(effect: Dictionary, index: int) -> bool:
	# Определяем, попадает ли клетка внутрь прямоугольной зоны конкретного эффекта.
	var center_index: int = int(effect.get("center_index", -1))
	if center_index < 0:
		return false

	var center_row: int = center_index / GRID_COLUMNS
	var center_column: int = center_index % GRID_COLUMNS
	var row: int = index / GRID_COLUMNS
	var column: int = index % GRID_COLUMNS
	var radius_low: int = int(effect.get("radius_low", 1))
	var radius_high: int = int(effect.get("radius_high", 1))

	return (
		row >= center_row - radius_low
		and row <= center_row + radius_high
		and column >= center_column - radius_low
		and column <= center_column + radius_high
	)


func _is_in_square_zone(index: int, center_index: int, radius_low: int, radius_high: int) -> bool:
	# Универсальная проверка попадания клетки в квадратную область вокруг центра.
	var center_row: int = center_index / GRID_COLUMNS
	var center_column: int = center_index % GRID_COLUMNS
	var row: int = index / GRID_COLUMNS
	var column: int = index % GRID_COLUMNS
	return (
		row >= center_row - radius_low
		and row <= center_row + radius_high
		and column >= center_column - radius_low
		and column <= center_column + radius_high
	)


func _get_orthogonal_neighbors(index: int) -> Array[int]:
	# Возвращаем только ортогональных соседей клетки: вверх, вниз, влево и вправо.
	var neighbors: Array[int] = []
	var row: int = index / GRID_COLUMNS
	var column: int = index % GRID_COLUMNS
	if row > 0:
		neighbors.append(index - GRID_COLUMNS)
	if row < GRID_ROWS - 1:
		neighbors.append(index + GRID_COLUMNS)
	if column > 0:
		neighbors.append(index - 1)
	if column < GRID_COLUMNS - 1:
		neighbors.append(index + 1)
	return neighbors


func _sync_board_cell(index: int) -> void:
	# Получаем все визуальные слои клетки, чтобы нарисовать нужное состояние.
	var cell: Button = board_buttons[index]
	var label: Label = board_labels[index]
	var icon: TextureRect = board_icons[index]
	var state: int = board_state[index]
	var tile_type: int = board_tile_types[index]
	label.add_theme_color_override("font_color", TEXT_LIGHT)
	label.add_theme_font_size_override("font_size", 28)

	# Подбираем нужную иконку и включаем ее только для источника вируса, бомбы или preview-спавна.
	if pending_source_spawn_index == index:
		icon.texture = virus_texture
		icon.visible = pending_source_flash_on
	elif tile_type == TILE_VIRUS and state != CELL_EMPTY:
		icon.texture = virus_texture
		icon.visible = true
	elif tile_type == TILE_BOMB and state != CELL_EMPTY:
		icon.texture = bomb_texture
		icon.visible = true
	else:
		icon.visible = false

	if pending_source_spawn_index == index:
		# Источник вируса появляется через отдельное мигание в пустой клетке.
		if pending_source_flash_on:
			_apply_board_styles(cell, ACTIVE_PURPLE, ACTIVE_PURPLE_DARK, SELECTED_BORDER)
		else:
			_apply_board_styles(cell, PANEL_DARK, PANEL_HOVER, SELECTED_BORDER)
		label.text = ""
	elif pending_bomb_indices.has(index):
		# Бомба перед взрывом мигает темно-красным цветом.
		if pending_bomb_flash_on:
			_apply_board_styles(cell, ACTIVE_BOMB, ACTIVE_BOMB_DARK, SELECTED_BORDER)
		else:
			_apply_board_styles(cell, PANEL_DARK, PANEL_HOVER, SELECTED_BORDER)
		label.text = ""
	elif pending_infection_indices.has(index):
		# Во время preview мигаем фиолетовым цветом на будущих заражениях.
		if pending_infection_flash_on:
			_apply_board_styles(cell, ACTIVE_PURPLE, ACTIVE_PURPLE_DARK, SELECTED_BORDER)
		else:
			_apply_board_styles(cell, PANEL_DARK, PANEL_HOVER, SELECTED_BORDER)
		label.text = ""
	elif state == CELL_PENDING and tile_type == TILE_GREEN:
		_apply_board_styles(cell, ACTIVE_GREEN, ACTIVE_GREEN_DARK, SELECTED_BORDER)
		label.text = "+%d" % board_scores[index]
	elif state == CELL_PENDING and tile_type == TILE_RED:
		_apply_board_styles(cell, ACTIVE_RED, ACTIVE_RED_DARK, SELECTED_BORDER)
		label.text = ""
	elif state == CELL_PENDING and tile_type == TILE_YELLOW:
		_apply_board_styles(cell, ACTIVE_YELLOW, ACTIVE_YELLOW_DARK, SELECTED_BORDER)
		label.text = ""
	elif state == CELL_PENDING and tile_type == TILE_BOMB:
		_apply_board_styles(cell, ACTIVE_BOMB, ACTIVE_BOMB_DARK, SELECTED_BORDER)
		label.text = ""
	elif state == CELL_COMMITTED and tile_type == TILE_GREEN:
		_apply_board_styles(cell, COMMITTED_GREEN, COMMITTED_GREEN, COMMITTED_GREEN)
		label.text = ""
	elif state == CELL_COMMITTED and tile_type == TILE_RED:
		_apply_board_styles(cell, COMMITTED_RED, COMMITTED_RED, COMMITTED_RED)
		label.text = ""
	elif state == CELL_COMMITTED and tile_type == TILE_YELLOW:
		_apply_board_styles(cell, COMMITTED_YELLOW, COMMITTED_YELLOW, COMMITTED_YELLOW)
		label.text = ""
	elif state == CELL_COMMITTED and tile_type == TILE_VIRUS:
		_apply_board_styles(cell, ACTIVE_PURPLE, ACTIVE_PURPLE_DARK, ACTIVE_PURPLE_DARK)
		label.text = ""
	elif state == CELL_COMMITTED and tile_type == TILE_INFECTED:
		_apply_board_styles(cell, COMMITTED_PURPLE, COMMITTED_PURPLE, COMMITTED_PURPLE)
		label.text = ""
	elif state == CELL_COMMITTED and tile_type == TILE_WALL:
		_apply_board_styles(cell, COMMITTED_WALL, COMMITTED_WALL, COMMITTED_WALL)
		label.text = "////"
		label.add_theme_color_override("font_color", WALL_HATCH_COLOR)
		label.add_theme_font_size_override("font_size", 18)
	else:
		# Для пустой клетки возвращаем нейтральное оформление.
		_apply_board_styles(cell, PANEL_DARK, PANEL_HOVER, SELECTED_BORDER)
		label.text = ""


func _apply_board_styles(button: Button, normal_color: Color, hover_color: Color, focus_border: Color) -> void:
	# Единообразно назначаем стиль кнопке поля для всех основных состояний.
	button.add_theme_stylebox_override("normal", _make_stylebox(normal_color, PANEL_BORDER, 6))
	button.add_theme_stylebox_override("hover", _make_stylebox(hover_color, PANEL_BORDER, 6))
	button.add_theme_stylebox_override("pressed", _make_stylebox(hover_color, PANEL_BORDER, 6))
	button.add_theme_stylebox_override("focus", _make_stylebox(normal_color, focus_border, 6))


func _sync_palette_slot(index: int) -> void:
	# Получаем кнопку палитры и определяем ее тип и доступность.
	var slot: Button = palette_buttons[index]
	var icon: TextureRect = palette_icons[index]
	var tile_type: int = palette_types[index]
	var available: bool = palette_available[index]
	icon.texture = bomb_texture
	icon.visible = available and tile_type == TILE_BOMB

	if not available:
		# Недоступную клетку палитры затемняем и не подсвечиваем.
		_apply_palette_styles(slot, PANEL_DARK, PANEL_DARK, 3)
		return

	var fill_color: Color = ACTIVE_GREEN
	var hover_color: Color = ACTIVE_GREEN_DARK
	if tile_type == TILE_RED:
		fill_color = ACTIVE_RED
		hover_color = ACTIVE_RED_DARK
	elif tile_type == TILE_YELLOW:
		fill_color = ACTIVE_YELLOW
		hover_color = ACTIVE_YELLOW_DARK
	elif tile_type == TILE_BOMB:
		fill_color = ACTIVE_BOMB
		hover_color = ACTIVE_BOMB_DARK

	# Активную фигуру дополнительно выделяем более толстой рамкой.
	var border_color: Color = SELECTED_BORDER if index == selected_palette_index else fill_color
	var border_width: int = 6 if index == selected_palette_index else 3
	_apply_palette_styles(slot, fill_color, border_color, border_width, hover_color)


func _apply_palette_styles(
	button: Button,
	fill_color: Color,
	border_color: Color,
	border_width: int,
	hover_color: Color = Color(-1, -1, -1, -1)
) -> void:
	# Если отдельный hover-цвет не задан, вычисляем его автоматически из основного.
	var resolved_hover: Color = hover_color if hover_color.a >= 0.0 else fill_color.lightened(0.06)
	button.add_theme_stylebox_override("normal", _make_stylebox(fill_color, border_color, border_width))
	button.add_theme_stylebox_override("hover", _make_stylebox(resolved_hover, border_color, border_width))
	button.add_theme_stylebox_override("pressed", _make_stylebox(resolved_hover.darkened(0.08), border_color, border_width))
	button.add_theme_stylebox_override("focus", _make_stylebox(fill_color, SELECTED_BORDER, border_width))
	button.add_theme_stylebox_override("disabled", _make_stylebox(fill_color, border_color, border_width))


func _update_zone_overlays() -> void:
	# Перестраиваем прямоугольники для обоих overlay-слоев и передаем их на отрисовку.
	active_red_zone_rects = _build_red_zone_rects()
	active_yellow_zone_rects = _build_yellow_zone_rects()
	active_bomb_zone_rects = _build_bomb_zone_rects()
	red_zone_overlay.call("set_zone_rects", active_red_zone_rects)
	yellow_zone_overlay.call("set_zone_rects", active_yellow_zone_rects)
	bomb_zone_overlay.call("set_zone_rects", active_bomb_zone_rects)


func _build_red_zone_rects() -> Array[Rect2]:
	# Красная зона всегда имеет базовый размер 3x3 вокруг pending-усилителя.
	var rects: Array[Rect2] = []
	for red_index in _get_pending_red_indices():
		rects.append(_build_rect_for_zone(red_zone_overlay, _make_zone_effect(red_index, 3)))
	return rects


func _build_yellow_zone_rects() -> Array[Rect2]:
	# Желтая зона строится по уже рассчитанным эффектам с учетом расширения от красных клеток.
	var rects: Array[Rect2] = []
	for effect in _get_visible_yellow_zone_effects():
		rects.append(_build_rect_for_zone(yellow_zone_overlay, effect))
	return rects


func _build_bomb_zone_rects() -> Array[Rect2]:
	# Для бомбы показываем текущие pending-зоны или уже активированные зоны перед взрывом.
	var rects: Array[Rect2] = []
	for effect in _get_visible_bomb_zone_effects():
		rects.append(_build_rect_for_zone(bomb_zone_overlay, effect))
	return rects


func _build_rect_for_zone(overlay: Control, effect: Dictionary) -> Rect2:
	# Преобразуем логическую зону по клеткам в экранный прямоугольник overlay-слоя.
	var center_index: int = int(effect.get("center_index", -1))
	var radius_low: int = int(effect.get("radius_low", 1))
	var radius_high: int = int(effect.get("radius_high", 1))
	var row: int = center_index / GRID_COLUMNS
	var column: int = center_index % GRID_COLUMNS

	var min_row: int = maxi(0, row - radius_low)
	var max_row: int = mini(GRID_ROWS - 1, row + radius_high)
	var min_column: int = maxi(0, column - radius_low)
	var max_column: int = mini(GRID_COLUMNS - 1, column + radius_high)

	var top_left_index: int = min_row * GRID_COLUMNS + min_column
	var bottom_right_index: int = max_row * GRID_COLUMNS + max_column
	var top_left_rect: Rect2 = board_buttons[top_left_index].get_global_rect()
	var bottom_right_rect: Rect2 = board_buttons[bottom_right_index].get_global_rect()
	var canvas_inverse: Transform2D = overlay.get_global_transform_with_canvas().affine_inverse()
	var local_top_left: Vector2 = canvas_inverse * top_left_rect.position
	var local_bottom_right: Vector2 = canvas_inverse * bottom_right_rect.end
	return Rect2(local_top_left, local_bottom_right - local_top_left)


func _update_progress_bar() -> void:
	# Если трек еще не создан, выходим без пересчета размеров.
	if not is_instance_valid(progress_track):
		return

	# Отдельно считаем зафиксированную часть и предпросмотр только для положительного pending-прироста.
	var track_width: float = progress_track.size.x
	var committed_ratio: float = clampf(float(committed_score) / float(PROGRESS_TARGET_SCORE), 0.0, 1.0)
	var pending_total: int = _get_current_pending_total()
	var preview_ratio: float = 0.0
	if pending_total > 0:
		preview_ratio = clampf(float(pending_total) / float(PROGRESS_TARGET_SCORE), 0.0, 1.0 - committed_ratio)

	var committed_width: float = track_width * committed_ratio
	var preview_width: float = track_width * preview_ratio
	progress_fill.offset_right = committed_width
	progress_preview.offset_left = committed_width
	progress_preview.offset_right = committed_width + preview_width
	_update_progress_label(committed_width, track_width, pending_total)


func _update_progress_label(committed_width: float, track_width: float, pending_total: int) -> void:
	# Приоритет у временного значения после Next, иначе показываем текущий pending-результат.
	var label_value := 0
	var should_show := false
	if show_transient_progress_label and transient_progress_value != 0:
		label_value = transient_progress_value
		should_show = true
	elif pending_total != 0:
		label_value = pending_total
		should_show = true

	if not should_show:
		progress_label.visible = false
		return

	# Подписываем прогресс и удерживаем текст внутри границ трека.
	progress_label.visible = true
	progress_label.text = "%+d" % label_value
	progress_label.reset_size()
	var label_width: float = progress_label.size.x
	var label_height: float = progress_label.size.y
	var x_position: float = clampf(committed_width + 10.0, 10.0, track_width - label_width - 10.0)
	progress_label.position = Vector2(x_position, (progress_track.size.y - label_height) * 0.5)


func _display_transient_progress_value(value: int) -> void:
	# Запоминаем последнее итоговое изменение и запускаем таймер автоскрытия подписи.
	transient_progress_value = value
	progress_label_request_id += 1
	var request_id: int = progress_label_request_id
	show_transient_progress_label = value != 0
	_update_progress_bar()
	_run_progress_label_timer(request_id)


func _run_progress_label_timer(request_id: int) -> void:
	# Ждем заданное время и скрываем подпись только если не появился более новый запрос.
	await get_tree().create_timer(PROGRESS_LABEL_DISPLAY_TIME).timeout
	if request_id != progress_label_request_id:
		return
	show_transient_progress_label = false
	transient_progress_value = 0
	_update_progress_bar()


func _get_current_pending_total() -> int:
	# Суммируем только pending-клетки текущего хода игрока.
	var total := 0
	for placement in placement_history:
		var board_index: int = int(placement.get("board_index", -1))
		if board_index >= 0:
			total += board_scores[board_index]
	return total


func _check_for_end_state() -> void:
	# Успех имеет приоритет над любыми состояниями нехватки памяти.
	if committed_score < PROGRESS_TARGET_SCORE:
		if not _has_any_free_cells():
			if _has_virus_overflow():
				_show_overlay(VIRUS_OVERFLOW_TEXT, false)
				return
			_show_overlay(MEMORY_OVERFLOW_TEXT, false)
			return
		return
	_show_overlay(SUCCESS_TEXT, true)


func _are_all_cells_infected() -> bool:
	# Проверяем, занято ли все поле только вирусными источниками и зараженными клетками.
	for index in range(TOTAL_CELLS):
		if board_state[index] == CELL_EMPTY:
			return false
		if board_tile_types[index] != TILE_VIRUS and board_tile_types[index] != TILE_INFECTED:
			return false
	return true


func _has_virus_overflow() -> bool:
	# Считаем критическое заражение, если свободных клеток нет и вирус занял не меньше двух третей поля.
	if _has_any_free_cells():
		return false
	return float(_get_infected_cells_count()) >= ceil(float(TOTAL_CELLS) * (2.0 / 3.0))


func _get_infected_cells_count() -> int:
	# Подсчитываем общее количество вирусных источников и зараженных клеток на поле.
	var infected_cells := 0
	for tile_type in board_tile_types:
		if tile_type == TILE_VIRUS or tile_type == TILE_INFECTED:
			infected_cells += 1
	return infected_cells


func _has_any_free_cells() -> bool:
	# Проверяем наличие хотя бы одной свободной клетки на поле.
	for cell_state in board_state:
		if cell_state == CELL_EMPTY:
			return true
	return false


func _show_overlay(message: String, allow_finish: bool = false) -> void:
	# Унифицированно открываем финальное popup-окно с нужным текстом и кнопкой рестарта.
	is_game_over = true
	can_finish_after_success = allow_finish
	success_label.text = message
	restart_button.text = RESTART_TEXT
	finish_button.visible = allow_finish
	success_overlay.visible = true
	_close_pause_overlay()
	_update_modal_layers()
	if allow_finish:
		emit_signal("puzzle_completed")


func _on_restart_pressed() -> void:
	# Кнопка на popup-окне всегда перезапускает текущую сцену с нуля.
	_restart_puzzle()


func _on_finish_pressed() -> void:
	# После успешного завершения позволяем свернуть пазл и вернуться в локацию.
	if not can_finish_after_success:
		return
	emit_signal("exit_requested")


func _on_pause_exit_pressed() -> void:
	# Выход из локальной паузы сбрасывает несохраненный прогресс и возвращает игрока обратно в сцену.
	_close_pause_overlay()
	_restart_puzzle()
	emit_signal("exit_requested")


func _on_pause_continue_pressed() -> void:
	# Продолжение просто закрывает локальное pause-окно и оставляет игрока в мини-игре.
	_close_pause_overlay()


func _clear_board_cell(index: int) -> void:
	# Полностью очищаем выбранную клетку и удаляем связь с любым вирусным кластером.
	board_state[index] = CELL_EMPTY
	board_tile_types[index] = TILE_NONE
	board_scores[index] = 0
	board_virus_owner_ids[index] = -1


func _load_virus_texture() -> Texture2D:
	# Возвращаем импортированный ресурс спрайта вируса без ручной загрузки изображения.
	return VIRUS_TEXTURE


func _load_bomb_texture() -> Texture2D:
	# Возвращаем импортированный ресурс спрайта бомбы.
	return BOMB_TEXTURE


func _make_stylebox(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	# Создаем единый StyleBoxFlat, чтобы не дублировать настройку рамок по всему скрипту.
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	return style
