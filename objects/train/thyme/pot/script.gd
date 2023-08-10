extends Node2D


signal thyme_taken
signal thyme_returned

const Bird = preload("res://objects/bird/script.gd")
const MAX_POT_FRAME = 4
const MAX_THYME_FRAME = 2
@onready var pot = $Pot
@onready var thyme = $Pot/Thyme
var is_empty = false
var thyme_tween: Tween


func _ready():
	pot.frame = randi() % MAX_POT_FRAME
	thyme.frame = randi() % MAX_THYME_FRAME
	if pot.frame % 2 == 1: thyme.position.y += 15
	pot.scale.x *= 1 if randf() > 0.5 else -1


func add_thyme():
	is_empty = false
	if thyme_tween: thyme_tween.kill()
	thyme_tween = create_tween()
	thyme_tween.tween_property(thyme, "scale", Vector2.ONE, 0.6)
	emit_signal("thyme_returned")


func shake_thyme():
	var time = 0.1
	if thyme_tween: thyme_tween.kill()
	thyme_tween = create_tween()
	thyme_tween.set_loops(4)
	thyme_tween.tween_property(thyme, "scale", Vector2(0.8, 1.4), time)
	thyme_tween.tween_property(thyme, "scale", Vector2(1.3, 0.8), time)
	thyme_tween.tween_property(thyme, "scale", Vector2.ONE, time)


func remove_thyme():
	is_empty = true
	if thyme_tween: thyme_tween.kill()
	thyme_tween = create_tween()
	thyme_tween.tween_property(thyme, "scale", Vector2(.5, 0), 0.6)
	emit_signal("thyme_taken")


func on_body_entered(body): (body as Bird).pot_reached(self)
