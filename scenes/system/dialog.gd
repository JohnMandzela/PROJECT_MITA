extends Control

@export var text_speed := 0.03

# UI узлы
@onready var nameLabel = $PanelBackground/Name
@onready var textLabel = $PanelBackground/Text
@onready var optionsContainer = $Options_Container
@onready var portrait = $Portrait

# Состояние диалога
var current_text := ""
var is_typing := false

var dialog_lines: Array
var current_idx := 0

func _show_line():
	optionsContainer.clear_children()
	textLabel.text = ""
	is_typing = true

	var line_text = dialog_lines[current_idx]

	for char in line_text:
		if not is_typing:
			break
		textLabel.text += char
		await get_tree().create_timer(text_speed).timeout

	is_typing = false

func _ready():
	var lines = [
		"Привет, герой!",
        "Куда ты направляешься?"
	]

	var callbacks = [
		{
			"Пойти в лес": func():
				print("Игрок идет в лес"),
			"Идти в город": func():
				print("Игрок идет в город"),
		}
	]

	start_dialog("Mike", preload("res://images/characters/Mike.png"), lines, callbacks)

func start_dialog(name: String, portrait_tex: Texture, lines: Array, callbacks: Array):
	nameLabel.text = name
	portrait.texture = portrait_tex

	dialog_lines = lines
	current_idx = 0

	_show_line()

func _create_options(opts_dict: Dictionary):
	for text in opts_dict.keys():
		var btn = Button.new()
		btn.text = text
		optionsContainer.add_child(btn)

		btn.pressed.connect(func():
			_on_option_selected(opts_dict[text])
		)

func _on_option_selected(callback: Callable):
	optionsContainer.clear_children()
	callback.call()
	current_idx += 1
	_show_line()

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and is_typing:
		is_typing = false
		textLabel.text = current_text  # сразу весь
