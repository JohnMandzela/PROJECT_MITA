extends Node2D


@export var dialogue: DialogueResource
@onready var Mike: CharacterBody2D = $Mike_NPC
@onready var Mom: CharacterBody2D = $Mom_NPC
@onready var animation_darken: AnimationPlayer = $CanvasLayer/AnimationDarken
@onready var animation_lighten: AnimationPlayer = $CanvasLayer/AnimationLighten

var speed := 120.0
var target_y := 0.0
var mom_moving := false


func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "start", [self])

func mom_move(distance: float):
	target_y = Mom.position.y + distance
	mom_moving = true


func darken_screen() -> void:
	animation_darken.play("darken")
	await get_tree().create_timer(0.5).timeout


func darken_screen_backwards() -> void:
	animation_darken.play_backwards("darken")
	await get_tree().create_timer(0.5).timeout

func wait(time):
	await get_tree().create_timer(time).timeout

func lighten_screen() -> void:
	animation_lighten.play("lighten")
	await get_tree().create_timer(1.0).timeout


func lighten_screen_backwards() -> void:
	animation_lighten.play_backwards("lighten")
	await get_tree().create_timer(1.0).timeout


func hide_portrait(character_name: String) -> void:
	"""
	Скрывает портрет персонажа.
	
	Параметры:
	- character_name: имя персонажа для скрытия портрета
	
	Использование в диалоге: do hide_portrait("Майк")
	"""
	# Эта функция может быть расширена для взаимодействия с системой портретов диалога
	# На данный момент это заглушка, которая позволяет вызову выполниться без ошибок
	pass


func _process(delta):
	if mom_moving:
		Mom.position.y += speed * delta
		
		if Mom.position.y >= target_y:
			Mom.position.y = target_y
			mom_moving = false

func switch_balloon(balloon_name: String) -> void:
	"""
	Переключает визуальный режим текущего пузыря диалога прямо во время диалога.
	
	Параметры:
	- balloon_name: "simple" для упрощённого режима (текст по центру, без фона и портретов)
	
	Использование в диалоге: do switch_balloon("simple")
	"""
	if balloon_name != "simple":
		return
	
	# Ищем текущий активный balloon в дочерних узлах сцены
	var active_balloon = _find_active_balloon()
	if not active_balloon:
		push_warning("switch_balloon: не найден активный balloon в сцене")
		return
	
	# Вызываем метод переключения режима прямо на существующем balloon
	if active_balloon.has_method("switch_to_simple_mode"):
		active_balloon.switch_to_simple_mode()


func _find_active_balloon() -> Node:
	"""Ищет активный balloon среди дочерних узлов текущей сцены"""
	# Balloon добавляется как дочерний узел текущей сцены через DialogueManager
	var current_scene = get_tree().current_scene
	if current_scene:
		for child in current_scene.get_children():
			if child is CanvasLayer and child.has_method("switch_to_simple_mode"):
				return child
	# Запасной вариант: ищем в корне
	for child in get_tree().root.get_children():
		if child is CanvasLayer and child.has_method("switch_to_simple_mode"):
			return child
	return null


func dialogue_end():
	var mike_room_scene = load("res://scenes/Goshivon/mike_room.tscn")
	get_tree().change_scene_to_packed(mike_room_scene)
