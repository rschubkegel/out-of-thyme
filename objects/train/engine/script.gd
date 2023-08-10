extends StaticBody2D


signal engine_entered
signal engine_exited

var is_occupied = true
var light_tween


func emit_engine_entered(_body):
	emit_signal("engine_entered")


func emit_engine_exited(_body):
	emit_signal("engine_exited")


func on_speed_up():
	if not is_occupied:
		show_light()
		$BellAnimator.play("ring")
	is_occupied = true


func on_slow_down():
	is_occupied = false
	hide_light()


func show_light():
	if light_tween: light_tween.kill()
	light_tween = create_tween()
	light_tween.tween_property($Sprite2D/LightCone, "modulate:a", 1, .5)


func hide_light():
	if light_tween: light_tween.kill()
	light_tween = create_tween()
	light_tween.tween_property($Sprite2D/LightCone, "modulate:a", 0, .35)
