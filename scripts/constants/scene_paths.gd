class_name ScenePaths

# Пути к сценам, на которые ссылаются из кода.
# Для переходов «локация → локация» предпочитайте @export PackedScene:
# путь, прописанный строкой в скрипте, ломается при переносе сцены молча.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const MOM_HOME := "res://scenes/locations/mom_home.tscn"
