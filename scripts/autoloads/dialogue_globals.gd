extends Node

# Словарь префиксов портретов персонажей
# TODO: сделать по-человечески
const PORTRAIT_PREFIXES = {
	"Майк": "Mike",
	"Эмили": "Emily",
}

# Допустимые эмоции персонажей
# Задаются в диалогах через теги 
const EMOTES: PackedStringArray = [
	"happy", "sad", "angry", "shame"
]
