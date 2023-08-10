extends CharacterBody2D


signal fell_off_train

enum FallState {
	GROUNDED,
	JUMPING,
	FALLING
}

const Organ = preload("res://objects/train/organ/script.gd")

@export_node_path("Node2D") var organ_car
@export var horizontal_speed = 400
@export var fall_acceleration = 35
@export var jump_speed_initial = 150
@export var jump_speed_deceleration_initial = 20
@export var jump_speed_deceleration_acceleration = 1.2
@export var coyote_time_initial = .1
@export var jump_sounds: Array[AudioStream]
@export var fall_sounds: Array[AudioStream]
@onready var jump_speed_current = jump_speed_initial
@onready var jump_speed_deceleration_current = jump_speed_deceleration_initial
@onready var coyote_time_current = coyote_time_initial
var fall_state = FallState.FALLING
var available_seat: Node2D # reference to seat that is available to sit on
var is_seated: bool: # is the conductor seated
	get: return $AnimationPlayer.current_animation == "playing_organ"
	set(value):
		if value: $AnimationPlayer.play("playing_organ")
		else: $AnimationPlayer.play("idle")


func _ready():
	velocity = Vector2.ZERO
	if !organ_car: push_error("Reference to organ car not set")
	$AnimationPlayer.connect("animation_finished", stop_playing_organ_if_was_playing_organ)


func _physics_process(delta):
	velocity.x = 0
	
	if not is_seated: handle_inputs()
	
	# handle vertical movement
	if fall_state == FallState.JUMPING:
		velocity.y -= jump_speed_current
		jump_speed_current -= jump_speed_deceleration_current
		jump_speed_deceleration_current *= jump_speed_deceleration_acceleration
		if jump_speed_current <= 0:
			fall_state = FallState.FALLING
	elif fall_state == FallState.FALLING:
		velocity.y += fall_acceleration
		if position.y > 1100 and fall_sounds.find($AudioStreamPlayer2D.stream) == -1:
			$AudioStreamPlayer2D.stream = fall_sounds.pick_random()
			$AudioStreamPlayer2D.play()
	
	# apply movement
	move_and_slide()
	coyote_time_current -= delta
	if is_on_floor():
		fall_state = FallState.GROUNDED
		coyote_time_current = coyote_time_initial
	elif fall_state == FallState.GROUNDED:
		fall_state = FallState.FALLING
	
	# lose if fell off train
	if position.y > 1440:
		emit_signal("fell_off_train")
		queue_free()


func handle_inputs():
	# handle organ playing inputs
	var organ_key_pressed = get_first_organ_key_pressed()
	if (organ_key_pressed != null) and (available_seat != null):
		is_seated = true
		velocity.x = 0
		if abs(available_seat.global_position.x - position.x) > .5:
			var t = create_tween()
			t.tween_property(self, "position:x", available_seat.global_position.x, .2)
		(get_node(organ_car) as Organ).toot_pipes(organ_key_pressed)
	
	else:
		# handle horizontal inputs
		if Input.is_action_pressed("move_right"):
			velocity.x += horizontal_speed
		if Input.is_action_pressed("move_left"):
			velocity.x -= horizontal_speed
		
		# handle horizontal animation
		if velocity.x == 0:
			if is_on_floor() && !is_seated && $AnimationPlayer.current_animation != "idle":
				$AnimationPlayer.play("idle")
		else:
			if is_on_floor() and $AnimationPlayer.current_animation != "run":
				$AnimationPlayer.play("run")
			if velocity.x > 0: $SideSprites.scale.x = -1
			elif velocity.x < 0: $SideSprites.scale.x = 1

		# handle jumping inputs
		if Input.is_action_just_pressed("jump"):
			if fall_state == FallState.GROUNDED || coyote_time_current >= 0:
				fall_state = FallState.JUMPING
				jump_speed_current = jump_speed_initial
				jump_speed_deceleration_current = jump_speed_deceleration_initial
				velocity.y = -jump_speed_current
				$AnimationPlayer.play("jump")
				$AudioStreamPlayer2D.stream = jump_sounds.pick_random()
				$AudioStreamPlayer2D.play()
		elif Input.is_action_just_released("jump"):
			if fall_state == FallState.JUMPING:
				fall_state = FallState.FALLING
				velocity.y = velocity.y / 2 + fall_acceleration


# returns int (for organ group) or null if none is pressed
func get_first_organ_key_pressed():
	for i in range(4):
		if Input.is_action_just_pressed("toot_%d" % (i + 1)): return i
	return null


func set_available_organ_seat(value: Node2D): available_seat = value


func remove_available_organ_seat(_seat: Node2D): available_seat = null


func stop_playing_organ_if_was_playing_organ(anim_name: StringName):
	if anim_name == "playing_organ": is_seated = false
