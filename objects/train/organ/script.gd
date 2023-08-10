@tool
extends Node2D


signal seat_entered(organ_seat: Node2D)
signal seat_exited(organ_seat: Node2D)

const Bird = preload("res://objects/bird/script.gd")
const Pipe = preload("res://objects/train/organ/pipe/script.gd")
const TOOT_STAGGER = 0.02
const BLAST_AREA_DURATION = 0.3

@export_range(1, 12) var sections = 4:
	get: return sections
	set(value):
		sections = value
		group_width = scaled_rect.size.x / value
		for c in $BlastAreas.get_children(): $BlastAreas.remove_child(c)
		for i in range(sections): add_blast_area(i)
@onready var initial_keys_scale = $Car/Organ.scale
var scaled_rect: Rect2:
	get:
		var initial_rect: Rect2 = $Car/Car.get_rect()
		var scale = 1.15#$Car/Car.scale.x
		var inset = 0
		return Rect2(
			initial_rect.position.x * scale - inset,
			initial_rect.position.y * scale - inset,
			initial_rect.end.x * scale - inset,
			initial_rect.end.y * scale - inset,
		)
var group_width: float


func _ready():
	if Engine.is_editor_hint(): return
	# add pipes to groups
	var rect = scaled_rect
	group_width = rect.size.x / sections
	for p in get_tree().get_nodes_in_group("pipes"):
		var x_from_left = (rect.size.x / 2) + (p as Pipe).position.x
		var group = floor(x_from_left / group_width)
		group = min(max(group, 0), sections)
		(p as Pipe).add_to_group("pipes-%d" % group)
	# add blast areas
	for c in $BlastAreas.get_children(): $BlastAreas.remove_child(c)
	for i in range(sections): add_blast_area(i)


func emit_organ_entered(body: PhysicsBody2D):
	if body.name == "Conductor":
		emit_signal("seat_entered", self)


func emit_organ_exited(body: PhysicsBody2D):
	if body.name == "Conductor":
		emit_signal("seat_exited", self)


func toot_pipes(group: int):
	# enable area2d for a moment so birds get blasted
	enable_blast_area(group)
	var t = create_tween()
	t.tween_interval(BLAST_AREA_DURATION)
	t.tween_callback(disable_blast_area.bind(group))
	
	# animate keys
	bulge_keys()
	
	# animate pipes
	t = create_tween()
	var pipes = get_tree().get_nodes_in_group("pipes-%d" % group)
	pipes.shuffle()
	for p in pipes:
		t.tween_interval(TOOT_STAGGER)
		t.tween_callback(func(): (p as Pipe).bulge())


func bulge_keys():
	var bulge_duration = 0.08
	var bulge_amt = 0.1
	var keyframes = [
		Vector2(initial_keys_scale.x * (1 + bulge_amt), initial_keys_scale.y * (1 - bulge_amt)),
		Vector2(initial_keys_scale.x * (1 - bulge_amt), initial_keys_scale.y * (1 + bulge_amt)),
		initial_keys_scale
	]
	var t = create_tween()
	for k in keyframes: t.tween_property($Car/Organ, "scale", k, bulge_duration)


func enable_blast_area(group: int):
	var area = ($BlastAreas.get_children()[group] as Area2D)
	var shape2d = (area.get_children()[0] as CollisionShape2D)
	shape2d.disabled = false
	add_blast_background(shape2d.position)


func disable_blast_area(group: int):
	var area = ($BlastAreas.get_children()[group] as Area2D)
	var shape2d = (area.get_children()[0] as CollisionShape2D)
	shape2d.disabled = true


func add_blast_area(group: int):
	var area = Area2D.new()
	area.set_collision_layer_value(1, false)
	area.set_collision_layer_value(4, true)
	area.set_collision_mask_value(1, false)
	area.set_collision_mask_value(4, true)
	area.connect("body_entered", on_blast_area_body_entered)
	var shape2d = CollisionShape2D.new()
	shape2d.disabled = true
	var shape = RectangleShape2D.new()
	var height = 1000
	shape.size = Vector2(group_width, height)
	shape2d.shape = shape
	shape2d.position = Vector2((group_width * (group + 0.5)) + (scaled_rect.position.x / 2), height / -2)
	area.add_child(shape2d)
	$BlastAreas.add_child(area)


func add_blast_background(pos: Vector2):
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://objects/train/organ/blast-background.png")
	sprite.scale = Vector2(.37, .65)
	sprite.position.y = pos.y
	sprite.position.x = pos.x
	sprite.z_index = -1
	sprite.modulate.a = 0
	add_child(sprite)
	var t = create_tween()
	t.tween_property(sprite, "modulate:a", 1, .1)
	t.tween_property(sprite, "modulate:a", 0, 1)
	t.tween_callback(sprite.queue_free)


func on_blast_area_body_entered(body: PhysicsBody2D): (body as Bird).stun()
