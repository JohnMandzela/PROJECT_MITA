extends Node

var player_scene: PackedScene = preload("res://scenes/player.tscn")
var player: CharacterBody2D
var pending_spawn_point: String = ""

var screen_fader
var _pending_scene: String

func _ready() -> void:
	screen_fader = preload("res://scenes/system/screen_fader.tscn").instantiate()   # подзагружаем анимацию перехода
	add_child(screen_fader)

	screen_fader.fade_finished.connect(_on_fade_finished)

# Начинаем перемещение в другую локацию
func start_scene_transition(scene_path: String, spawn_point: String) -> void:
	_pending_scene = scene_path
	pending_spawn_point = spawn_point
	screen_fader.fade_out()                                                     # затемняем экран

# Меняем локацию после затемнения экрана
func _on_fade_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/" + _pending_scene + ".tscn")
	screen_fader.fade_in()                                                      # осветляем экран
