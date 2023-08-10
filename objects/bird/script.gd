extends CharacterBody2D


signal grabbed_thyme
signal escaped_with_thyme
signal dropped_thyme(Node2D)

enum BirdState {
	FLYING_TO_THYME,
	PICKING_UP_THYME,
	FLYING_BACK_WITH_THYME,
	LOST_TARGET,
	STUNNED_BY_ORGAN,
	FLYING_AWAY_FROM_ORGAN
}

const Pot = preload("res://objects/train/thyme/pot/script.gd")
const Thyme = preload("res://objects/thyme/Thyme.tscn")

@export var target: Pot:
	get: return target
	set(value):
		target = value
		if value == null and state == BirdState.FLYING_TO_THYME:
			state = BirdState.LOST_TARGET
@export var speed = 500
@export var thyme_pause = 1.1
@export var hit_sounds: Array[AudioStream]
@export var whoosh_sounds: Array[AudioStream]
@onready var start = position
@onready var x_pos_tween = create_tween()
@onready var y_pos_tween = create_tween()
var state = BirdState.FLYING_TO_THYME:
	get: return state
	set(value):
		match value:
			BirdState.LOST_TARGET:
				x_pos_tween.kill()
				y_pos_tween.kill()
				$Body.scale.x = -1
				x_pos_tween = create_tween()
				y_pos_tween = create_tween()
				var duration = position.distance_to(start) / speed
				x_pos_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
				y_pos_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
				x_pos_tween.tween_property(self, "position:x", start.x, duration)
				y_pos_tween.tween_property(self, "position:y", start.y, duration)
			BirdState.STUNNED_BY_ORGAN:
				x_pos_tween.kill()
				y_pos_tween.kill()
				if $Body/Thyme.visible:
					emit_signal("dropped_thyme", self)
					$Body/Thyme.visible = false
#					var thyme = Thyme.instantiate()
#					thyme.position = position
#					thyme.z_index = 10
#					var th = create_tween()
#					var dist = 1440 - thyme.position.y
#					var offset = Vector2(dist / -2, dist)
#					var dest = thyme.position + offset
#					var time = dist / 10.0
#					th.tween_property(thyme, "position", dest, time)
#					th.tween_callback(thyme.queue_free)
#					get_parent().add_child(thyme)
				$AnimationPlayer.speed_scale = 2
				var destination = Vector2(position.x - (position.y / 2), -10)
				var time = position.distance_to(destination) / (speed * 2)
				var t = create_tween()
				t.tween_callback(func(): $Body.scale.x = 1)
				t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
				t.tween_property(self, "position", destination, time)
				t.parallel().tween_property(self, "rotation", 10 * time, time)
				t.tween_callback(queue_free)
				$AudioStreamPlayer2D.stop()
				$AudioStreamPlayer2D.stream = hit_sounds.pick_random()
				$AudioStreamPlayer2D.play()
		state = value


func _ready():
	if target: create_tween_default()
	else: print("Bird has no target")


func create_tween_default():
	# calc duration
	var duration = position.distance_to(target.global_position) / speed
	
	# set easing
	x_pos_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	y_pos_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	# start -> target
	x_pos_tween.tween_property(self, "position:x", target.global_position.x, duration)
	y_pos_tween.tween_property(self, "position:y", target.global_position.y - 25, duration)
	x_pos_tween.tween_callback(func(): state = BirdState.PICKING_UP_THYME)
	
	# pause
	x_pos_tween.tween_interval(thyme_pause)
	y_pos_tween.tween_interval(thyme_pause)
	x_pos_tween.tween_callback(func(): state = BirdState.FLYING_BACK_WITH_THYME)
	
	# flip direction
	x_pos_tween.tween_callback(func(): $Body.scale.x = -1)
	
	# set easing
	x_pos_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	y_pos_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	
	# target -> start
	x_pos_tween.tween_property(self, "position:x", start.x, duration)
	y_pos_tween.tween_property(self, "position:y", start.y, duration)
	
	# remove bird
	emit_signal("escaped_with_thyme")
	x_pos_tween.tween_callback(queue_free)


func pot_reached(pot: Pot):
	if pot == target:
		pot.shake_thyme()
		var t = create_tween()
		t.tween_interval(thyme_pause)
		t.tween_callback(func(): if pot and pot.has_method("remove_thyme"): pot.remove_thyme())
		t.tween_callback(emit_signal.bind("grabbed_thyme"))
		t.tween_callback(play_whoosh_sound)
		t.tween_callback(func(): $Body/Thyme.visible = true)


func play_whoosh_sound():
	$AudioStreamPlayer2D.stream = whoosh_sounds.pick_random()
	$AudioStreamPlayer2D.play()


func stun():
	if state != BirdState.STUNNED_BY_ORGAN: state = BirdState.STUNNED_BY_ORGAN
