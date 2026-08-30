class_name EventAction
extends Resource


func can_interact(_context: InteractionContext) -> bool:
    return true


func on_interact(_context: InteractionContext) -> void:
    pass


# Контекст взаимодействия с ивентом
class InteractionContext:
    var event: Node
    var player: Player
    
    func _init(event_: Node, player_: Player) -> void:
        self.event = event_
        self.player = player_
