@tool
extends Node2D


const BULGE_DURATION = 0.3

@export_color_no_alpha var color = Color.DIM_GRAY:
	get: return color
	set(value):
		color = value
		$Line2D.default_color = value
@export_range(1, 50) var size = 10:
	get: return size
	set(value):
		size = value
		$Line2D.width = size
		$Line2D.points[1].y = ceil(size * -lerp(5.0, 10.0, value / 50.0))
		$AnimatedSprite2D.position.y = $Line2D.points[1].y
@export var audio_files: Array[AudioStream]
var bulge_y_pos = 0
var bulge_radius = 0


func bulge():
	# calc vars
	var min_rad = $Line2D.width / 2
	var max_rad = $Line2D.width * 1.3
	bulge_radius = min_rad
	bulge_y_pos = -min_rad
	
	# tween bulge position
	var t1 = create_tween()
	t1.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t1.tween_property(self, "bulge_y_pos", $Line2D.points[1].y + min_rad, BULGE_DURATION)
	
	# tween bulge radius
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t2.tween_property(self, "bulge_radius", max_rad, BULGE_DURATION / 2.0)
	t2.tween_property(self, "bulge_radius", min_rad, BULGE_DURATION / 2.0)
	
	# only do this for some pipes...
	if randf() > .5:
		# play blast animation
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.speed_scale = (randf() / 2) + 1
		$AnimatedSprite2D.play("default")
		$AnimatedSprite2D.modulate.a = randf()
		$AnimatedSprite2D.scale.x = 1 if randf() > .5 else -1
		
		# play blast sfx
		$AudioStreamPlayer.stop()
		$AudioStreamPlayer.pitch_scale = (randi_range(0, 10) / 10.0) + .75
		$AudioStreamPlayer.stream = audio_files.pick_random()
		$AudioStreamPlayer.play()


func _process(_delta):
	if Engine.is_editor_hint(): return
	queue_redraw()


func _draw():
	if Engine.is_editor_hint(): return
	if bulge_y_pos < 0 and bulge_y_pos > $Line2D.points[1].y:
		var pos = Vector2(0, bulge_y_pos)
		draw_circle(pos, bulge_radius, color)
