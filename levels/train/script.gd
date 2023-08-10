extends Node


# if emitted with score <= 0, the player lost
signal win(time_remaining: float, thyme_remaining: int, distance_travelled: float, distance_remaining: float)
signal lose(time_remaining: float, thyme_remaining: int, distance_travelled: float, distance_remaining: float)

const Pot = preload("res://objects/train/thyme/pot/script.gd")
const MAX_SPEED = 1.5
const TIME_TO_ZERO = 7.0
const TIME_TO_ONE = 2.6
const TIME_TO_MAX = 4.0
const DISTANCE_MULTIPLIER = 38.0

@export var time_limit = 60 # how long until sunset, in seconds
@export var distance_to_target = 2000 # how far until you win
var is_in_engine = true
var train_speed = 0.0
var train_speed_tween: Tween
var thyme_count: int:
	get:
		var available_thyme = 0
		for p in get_tree().get_nodes_in_group("pot"):
			if not (p as Pot).is_empty:
				available_thyme += 1
		return available_thyme
var play_time = 0.0
var distance_travelled = 0.0


func _ready():
	$Sun.init_sunset(time_limit)
	$KeepGoingLabel.scale = Vector2.ZERO
	if get_parent().data["high_scores"].size() == 0:
		$ProtectLabel.visible = true
		var time = .4
		var loops = 6
		var t = create_tween()
		t.set_loops(loops)
		t.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property($ProtectLabel, "position", $ProtectLabel.position - Vector2(0, 20), time)
		t.tween_property($ProtectLabel, "position", $ProtectLabel.position + Vector2(0, 20), time)
		t = create_tween()
		t.tween_interval(time * (loops - 1))
		t.tween_property($ProtectLabel, "scale", Vector2.ZERO, time * 1)
		t.tween_callback($ProtectLabel.set.bind("visible", false))
	else: $ProtectLabel.visible = false


func _process(delta):
	for a in get_tree().get_nodes_in_group("train_speed_animators"):
		(a as AnimationPlayer).speed_scale = train_speed
	play_time += delta
	distance_travelled += train_speed * delta * DISTANCE_MULTIPLIER
	if play_time >= time_limit: emit_lose()
	elif distance_travelled >= distance_to_target: emit_win()
	else:
		$TimeLabel.text = "Time remaining: %d s" % ceil(time_limit - play_time)
		$DistanceLabel.text = "Distance to delivery: %.0f ft" % (distance_to_target - distance_travelled)
		if ((time_limit - play_time) < (time_limit / 4)) and !$HurryLabel.visible:
			$HurryLabel.visible = true
			var t = create_tween()
			for _i in 3:
				t.tween_property($HurryLabel, "scale", Vector2(1.7, 1.5), .3)
				t.tween_property($HurryLabel, "scale", Vector2.ONE, .3)
			t.tween_property($HurryLabel, "scale", Vector2.ZERO, .3)
	if train_speed < 0.2:
		if $KeepGoingLabel/Timer.is_stopped(): $KeepGoingLabel/Timer.start()
	else: $KeepGoingLabel/Timer.stop()


func on_engine_entered():
	is_in_engine = true
	if train_speed_tween: train_speed_tween.kill()
	if train_speed < 1:
		accel_to_one()
	else:
		accel_to_max()


func on_engine_exited():
	is_in_engine = false
	if train_speed_tween: train_speed_tween.kill()
	decelerate()


func accel_to_one():
	var duration = (1.0 - train_speed) * TIME_TO_ONE
	train_speed_tween = create_tween()
	train_speed_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	train_speed_tween.tween_property(self, "train_speed", 1.0, duration)
	train_speed_tween.tween_callback(accel_to_max)
	$EngineCar.on_speed_up()
	if $KeepGoingLabel/AnimationPlayer.is_playing(): $KeepGoingLabel/AnimationPlayer.stop()
	$KeepGoingLabel/Timer.stop()
	var t = create_tween()
	t.tween_property($KeepGoingLabel, "scale", Vector2.ZERO, 1.0)


func accel_to_max():
	var duration = TIME_TO_MAX
	train_speed_tween = create_tween()
	train_speed_tween.tween_property(self, "train_speed", MAX_SPEED, duration)
	$EngineCar.on_speed_up()


func decelerate():
	var duration = train_speed * TIME_TO_ZERO
	train_speed_tween = create_tween()
	train_speed_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	train_speed_tween.tween_property(self, "train_speed", 0.0, duration)
	$EngineCar.on_slow_down()


func on_bird_escaped_with_thyme(): pass


func on_bird_grabbed_thyme(): if thyme_count == 0: emit_lose()


func emit_lose(): emit_signal("lose", time_limit - play_time, thyme_count, distance_travelled, distance_to_target - distance_travelled)


func emit_win(): emit_signal("win", time_limit - play_time, thyme_count, distance_travelled, distance_to_target - distance_travelled)


func _on_timer_timeout():
	$KeepGoingLabel/AnimationPlayer.play("throb")
