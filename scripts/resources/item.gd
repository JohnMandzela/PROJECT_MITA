class_name Item
extends Resource

# Название предмета
@export var display_name: String

# Описание предмета
@export_multiline var description: String

# Текст, который будет отображаться при использовании предмета
@export var use_text: String

# TODO: генерировать динамически из свойств
# Описание действия, которое будет выполнено при использовании предмета
@export var action: String

# Восстановление бодрости
@export var vigor_modifier: int = 0

# Восстановление психики
@export var psyche_modifier: int = 0

# Путь к иконке предмета
var icon_path := ""

# Иконка предмета
var icon: Resource = null


# Инициализирует иконку предмета. Должна вызываться сразу после загрузки ресурса
func init_icon(id: String) -> void:
    icon_path = "res://images/items/%s.png" % id
    
    if ResourceLoader.exists(icon_path):
        icon = ResourceLoader.load(icon_path)
    else:
        push_warning("Иконка для предмета '%s' не найдена по пути: %s" % [display_name, icon_path])


func _get_use_effects() -> Dictionary:
    var effects := {}

    if vigor_modifier != 0:
        effects["vigor"] = vigor_modifier
    if psyche_modifier != 0:
        effects["psyche"] = psyche_modifier

    return effects


# Возвращает текст с описанием эффектов предмета
func get_use_text(use_effects: Dictionary) -> String:
    var effect_descriptions := []

    if use_effects.has("vigor"):
        effect_descriptions.append("Бодрость: %+d" % use_effects["vigor"])
        
    if use_effects.has("psyche"):
        effect_descriptions.append("Психика: %+d" % use_effects["psyche"])

    return use_text if use_text != "" else "Использовать"


# TODO: удалить, когда будет рефакторинг UI
func to_dictionary() -> Dictionary:
    var dict := {
        "display_name": display_name,
        "description": description,
        "use_text": use_text,
        "icon_path": icon_path,
    }

    var use_effects := get_use_effects()

    if use_effects:
        

        dict["use_effects"] = use_effects
        dict["action"] = "Использовать: " + ", ".join(effect_descriptions)

    return dict
