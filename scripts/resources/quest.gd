class_name Quest
extends Resource

# Название квеста
@export var title: String

# Текст, который будет отображаться в дневнике после начала квеста
@export_multiline var started_text: String

# Текст, который будет отображаться в дневнике после завершения квеста
@export_multiline var completed_text: String

# Промежуточные этапы квеста, где ключ - ID флага, а значение - текст в дневнике
@export var stages: Dictionary[String, String] = {}
