class_name ScreenFader
extends CanvasLayer

signal fade_out_finished
signal fade_in_finished

## Длительность перехода по умолчанию, секунды
const DEFAULT_DURATION := 0.5

@onready var overlay: ColorRect = $ColorRect
@onready var timer: Timer = $Timer

## Сколько ждать между затемнением и появлением. null — ждать ручного fade_in().
var _hold_seconds = null
var _tween: Tween


func _ready() -> void:
	timer.timeout.connect(fade_in)


## Затемнение экрана в заданный цвет (по умолчанию чёрный).
## seconds — сколько держать цвет перед автоматическим fade_in (null — не убирать).
## duration — длительность самого перехода.
func fade_out(seconds = null, color := Color.BLACK, duration := DEFAULT_DURATION) -> void:
	_hold_seconds = seconds
	timer.stop()

	_start_tween(Color(color.r, color.g, color.b, 1.0), duration)
	_tween.finished.connect(_on_fade_out_finished, CONNECT_ONE_SHOT)


## Плавное появление (цвет уходит в прозрачность)
func fade_in(duration := DEFAULT_DURATION) -> void:
	_hold_seconds = null
	timer.stop()

	_start_tween(Color(overlay.color.r, overlay.color.g, overlay.color.b, 0.0), duration)
	_tween.finished.connect(_on_fade_in_finished, CONNECT_ONE_SHOT)


## Мгновенно заливает экран цветом — без анимации. Нужно при пропуске катсцены.
func set_color(color: Color) -> void:
	_stop_tween()
	timer.stop()
	_hold_seconds = null
	overlay.color = color


## Мгновенно убирает затемнение, сохраняя текущий цвет
func clear_screen() -> void:
	set_color(Color(overlay.color.r, overlay.color.g, overlay.color.b, 0.0))


func _start_tween(target: Color, duration: float) -> void:
	_stop_tween()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(overlay, "color", target, maxf(duration, 0.01))


func _stop_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _on_fade_out_finished() -> void:
	fade_out_finished.emit()

	match _hold_seconds:
		null:
			return
		0:
			fade_in()
		_:
			timer.start(_hold_seconds)


func _on_fade_in_finished() -> void:
	fade_in_finished.emit()
