class_name ItemIds

# Единственный источник id предметов.
#
# Значение = имя файла в res://content/items/<id>.tres. Меняешь файл — меняй константу
# и запись в ALL (тест tests/unit/test_ids.gd поймает расхождение).

const COLA := "cola"
const COFFEE_CUP := "coffee_cup"
const TEDDY_BEAR := "teddy_bear"

const ALL: PackedStringArray = [
	COLA,
	COFFEE_CUP,
	TEDDY_BEAR,
]
