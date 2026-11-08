extends Control

func _ready() -> void:
    print(DotEnv.get_env("DEBUG"))