extends DialogueEventBase

@onready var audio: AudioStreamPlayer = $ItemGot


func take_item(item_name: String) -> void:
	if not GameManager.item_check(item_name):
		GameManager.item_was_took(item_name)
		_play_interact_sound()
		if GameManager.item_check(item_name):
			print("Получено " + item_name)


func drop_item(item_name: String) -> void:
	if GameManager.item_check(item_name):
		GameManager.item_was_dropped(item_name)
		if not GameManager.item_check(item_name):
			print("Выброшено " + item_name)


func _play_interact_sound() -> void:
	if audio and not audio.playing:
		audio.play()
