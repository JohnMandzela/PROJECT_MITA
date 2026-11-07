class_name Enums

# Направления
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

# Допустимые эмоции персонажей. Задаются в диалогах через теги
enum Emote {
	HAPPY,
	SAD,
	ANGRY,
	SHAME,
	# Сбрасывает эмоцию персонажа на «по умолчанию»
	DEFAULT,
}
