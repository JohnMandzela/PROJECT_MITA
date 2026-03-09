extends Node

# Словарь префиксов портретов персонажей
# TODO: сделать по-человечески
const PORTRAIT_PREFIXES = {
	"Майк": "mike"
}

# Допустимые эмоции персонажей
# Задаются в диалогах через теги 
var EMOTES := Set.of([
	"happy", "sad", "angry"
])
