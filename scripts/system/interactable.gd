@abstract
class_name Interactable
extends CollisionObject2D

## Общая логика интерактивных объектов: зон (Area2D) и статичных объектов (StaticBody2D).
##
## Шаблонный метод — can_interact()/on_interact(). Наследники переопределяют
## пару _can_interact()/_on_interact(); _is_running ведёт база, чтобы объект
## не запускался повторно, пока выполняется предыдущее взаимодействие.

@export var action: EventAction

var label: Label

var _is_running := false


func _ready() -> void:
	label = get_node_or_null("Label") as Label
	if label:
		label.visible = false


# Можно ли взаимодействовать прямо сейчас
func can_interact() -> bool:
	return not _is_running and _can_interact()


# Начать взаимодействие. Повторный вызов во время выполнения игнорируется
func on_interact() -> void:
	if _is_running:
		return

	_is_running = true
	await _on_interact()
	_is_running = false


func on_focused() -> void:
	if label:
		label.visible = true


func on_unfocused() -> void:
	if label:
		label.visible = false


# Хук для наследников; по умолчанию спрашивает action
func _can_interact() -> bool:
	return action != null and action.can_interact(_create_context())


# Хук для наследников; по умолчанию выполняет action
func _on_interact() -> void:
	if action:
		await action.on_interact(_create_context())


func _create_context() -> EventAction.InteractionContext:
	return EventAction.InteractionContext.new(self, _get_player())


# Игрок, от имени которого выполняется взаимодействие
func _get_player() -> Player:
	if not is_instance_valid(GameManager.player):
		return null

	return GameManager.player as Player
