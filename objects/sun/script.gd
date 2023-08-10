@tool
extends Node2D


const SUN_TARGET_Y = 1400

@export_range(0, 10000) var radius = 500
@export_color_no_alpha var sun_color: Color
@export_color_no_alpha var sky_end_color: Color


func _draw():
	draw_circle(position, radius, sun_color)
	if Engine.is_editor_hint():
		draw_circle(Vector2(position.x, SUN_TARGET_Y), 5, sky_end_color)


func init_sunset(time: float):
	var start_x = 2560 / 4
	var start_y = radius / -2
	position = Vector2(start_x, start_y)
	if not Engine.is_editor_hint():
		var t = create_tween()
		t.tween_property(self, "position:y", SUN_TARGET_Y + radius, time)
		t.parallel().tween_property(get_node("../Sky"), "color", sky_end_color, time)
