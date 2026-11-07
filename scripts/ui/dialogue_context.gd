class_name DialogueContext
extends Node

## Всё, что видно диалогу из .dialogue-файлов, кроме UI-функций балуна.
##
## Контекст — первый элемент temporary_game_states, поэтому `set locals.x = …`
## и `do play_sound(...)`/`do fade_out()` попадают сюда. Живёт столько же,
## сколько сам балун (новый балун — новый контекст).

## Локальные переменные диалога. Живут только в рамках диалога и не сохраняются.
var locals: Dictionary = { }


## Пауза. Используется в диалогах: do wait(0.3)
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Проигрывает звук по id из res://assets/audio/sounds/<id>.{wav,ogg,mp3}.
## С wait_for_completion = true диалог ждёт конца звука.
func play_sound(sound_id: String, wait_for_completion := true) -> void:
	var found_resource_path := ""
	for fmt in ["wav", "ogg", "mp3"]:
		var path := "res://assets/audio/sounds/%s.%s" % [sound_id, fmt]
		if ResourceLoader.exists(path, "AudioStream"):
			found_resource_path = path
			break

	if found_resource_path.is_empty():
		push_warning("Звук '%s' не найден" % sound_id)
		return

	var sound: AudioStream = load(found_resource_path)
	var player := SoundManager.play_sound(sound)
	if wait_for_completion:
		await player.finished


## Затемнение экрана. Если передана длительность, диалог ждёт плавного
## появления обратно; если нет — только конца затемнения.
func fade_out(seconds: Variant = null) -> void:
	GameManager.screen_fader.fade_out(seconds)

	if seconds != null:
		await GameManager.screen_fader.fade_in_finished
	else:
		await GameManager.screen_fader.fade_out_finished


## Плавное появление
func fade_in() -> void:
	GameManager.screen_fader.fade_in()
	await GameManager.screen_fader.fade_in_finished
