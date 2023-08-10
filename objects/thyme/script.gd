extends Node2D


signal on_player_entered(thyme: Node2D)

const GRAVITY_CONSTANT = 30.0


func emit_on_player_entered(): emit_signal("on_player_entered", self)
