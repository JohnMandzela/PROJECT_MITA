extends Node

## Отладочные переключатели, которые не попадают в репозиторий.
##
## Значения читаются из res://.env (файл в .gitignore) через автолоад DotEnv.
## Ключи без префикса, булевы значения: true/false, 1/0, yes/no, on/off.
##
## Пример .env:
##     SKIP_INTRO=true
##
## В release-сборке значения игнорируются и остаются дефолтными.

## Пропускать стартовую катсцену (для быстрой отладки других сцен)
var skip_intro := false


func _ready() -> void:
	reload()


## Перечитывает значения из окружения (заполняется DotEnv при старте)
func reload() -> void:
	if not OS.is_debug_build():
		return

	skip_intro = _bool("SKIP_INTRO", false)


## Преобразует строковое значение из .env в bool.
## Пустое или нераспознанное значение → default_value.
static func parse_bool(raw: String, default_value := false) -> bool:
	var value := raw.strip_edges().to_lower()

	if value in ["1", "true", "yes", "on"]:
		return true
	if value in ["0", "false", "no", "off"]:
		return false

	return default_value


func _bool(key: String, default_value := false) -> bool:
	return parse_bool(DotEnv.get_env(key), default_value)
