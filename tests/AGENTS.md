# AGENTS.md — тесты

## Что здесь

`tests/unit/` — модульные тесты на [GUT 9.5](https://github.com/bitwes/Gut).

## Запуск

Из корня проекта:

```powershell
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
& $godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

`-ginclude_subdirs` обязателен: без него GUT смотрит только в `res://tests` и не видит `unit/`.

Полезные ключи: `-gunit_test_name=test_flag` (один тест), `-gselect=test_inventory.gd` (один файл),
`-glog=2` (подробный вывод).

## Соглашения

- Файл `test_<что_тестируем>.gd`, класс `extends GutTest`.
- Автолоады (`GameManager`, `Inventory`, `Quests`, `SaveSystem`) доступны как обычно: тесты идут внутри проекта.
- Состояние автолоадов общее на весь прогон: сбрасывай его в `before_each`, а не в конце теста.
- Тесты не должны трогать настоящие сохранения (`user://quicksave.bin`, `user://save_*.bin`). Если нужен
  файл — пиши во временный путь `user://test_*.bin` и удаляй его в `after_each`.
- Ноды из тестов создавай через `add_child_autofree()` / `add_child_autoqfree()`, чтобы не думать об уборке.
- Нельзя писать `ObjectEvent.new()` / `ZoneEvent.new()`: они наследуются от абстрактного `CollisionObject2D`.
  Создавай `StaticBody2D`/`Area2D` и навешивай скрипт через `set_script()`, а вызовы делай через `call()`
  (статическая типизация не знает, что скрипт навешан).
- Скрипты, привязанные к сцене (зоны, обработчики взаимодействий), лучше тестировать на реальной сцене:
  `load("res://scenes/…").instantiate()` + `add_child_autofree()`.

## Что уже покрыто

| Файл | Что проверяет |
|---|---|
| `test_flags.gd` | все константы `Flags` попали в `Flags.ALL`, нет дубликатов, `set_flag` не хранит `false`, сигнал `flag_updated` |
| `test_inventory.gd` | формат сохранения `to_dict`/`from_dict`, круговой путь через `store_var`, мусор в данных, `reset()` чистит оба мира |
| `test_quests.gd` | состояния квестов и их восстановление из сохранения |
| `test_save_system.gd` | пути слотов, чтение сводки сохранения, битые файлы |
| `test_interactable.gd` | `Interactable.can_interact()`/`_is_running`, `Label` у зон, слои коллизий `ObjectEvent` |
| `test_balloon.gd` | простой режим балуна: панель скрыта, `DialogueLabel` переезжает в `SimpleArea`, повторное переключение безопасно; реплика рассказчика гасит активный портрет |
| `test_dialogue_controller.gd` | контроллер и контекст создаются балуном, ожидание ввода на обычной реплике, ответы блокируют авто-переход |
| `test_dialogue_context.gd` | `locals` пустой и пишется, `wait()` соблюдает время, предупреждение о ненайденном звуке |
| `test_ids.gd` | `ItemIds`/`QuestIds`/`InputActions` существуют в проекте, нет дубликатов, все константы добавлены в `ALL` |
