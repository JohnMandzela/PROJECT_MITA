class_name Sounds

# Единственный источник звуков.
#
# Значение — загруженный AudioStream, поэтому константа подходит везде, где нужен
# звук: в диалогах `do play_sound(Sounds.RUSTLE)`, в коде
# `SoundManager.play_sound(Sounds.ITEM_PICKUP)`.
#
# Новый звук: файл в res://assets/audio/sounds/, константа здесь и запись в ALL
# (тест tests/unit/test_ids.gd поймает расхождение).

const RUSTLE: AudioStream = preload("res://assets/audio/sounds/rustle.mp3")
const OPEN: AudioStream = preload("res://assets/audio/sounds/open.mp3")
const ITEM_PICKUP: AudioStream = preload("res://assets/audio/sounds/item_pickup.wav")
const SHOWER_WASH: AudioStream = preload("res://assets/audio/sounds/shower_wash.mp3")
const TOILET_FLUSH: AudioStream = preload("res://assets/audio/sounds/toilet_flush.mp3")

const ALL: Array[AudioStream] = [
	RUSTLE,
	OPEN,
	ITEM_PICKUP,
	SHOWER_WASH,
	TOILET_FLUSH,
]
