class_name Flags

# Единственный источник имён игровых флагов.
#
# В GameManager.game_flags хранятся только УСТАНОВЛЕННЫЕ флаги: отсутствие
# ключа означает, что флаг не установлен (значение false не хранится).
#
# Строковые значения флагов менять нельзя — они попадают в сохранения.

const BED_INTERACTED := "bed_interacted"
const SHOWER_USED := "shower_used"
const COFFEE_PICKED_UP := "offices_coffee_picked_up"
const PUZZLE_COMPLETED := "programming_office_samples_puzzle_completed"

# Все объявленные флаги. Новый флаг добавляй константой выше и сюда.
const ALL: PackedStringArray = [
	BED_INTERACTED,
	SHOWER_USED,
	COFFEE_PICKED_UP,
	PUZZLE_COMPLETED,
]


# Возвращает true, если флаг объявлен в этом классе
static func is_valid(flag_name: String) -> bool:
	return ALL.has(flag_name)


# Ловит дубликаты имён флагов в dev-сборке (в release assert вырезается)
static func _static_init() -> void:
	var seen := {}
	for flag_name in ALL:
		assert(not seen.has(flag_name), "Flags: дубликат флага '%s'" % flag_name)
		seen[flag_name] = true
