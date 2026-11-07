class_name QuestIds

# Единственный источник id квестов.
#
# Значение = имя файла в res://content/quests/<id>.tres. Меняешь файл — меняй константу
# и запись в ALL (тест tests/unit/test_ids.gd поймает расхождение).

const FIND_COLA := "find_cola"
const MORNING_ROUTINE := "morning_routine"
const CHECK_LAPTOP := "check_laptop"
const DEBUG_CODE := "debug_code"

const ALL: PackedStringArray = [
	FIND_COLA,
	MORNING_ROUTINE,
	CHECK_LAPTOP,
	DEBUG_CODE,
]
