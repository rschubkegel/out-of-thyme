extends Node


signal clump_finished

const Level = preload("res://levels/train/script.gd")
const Pot = preload("res://objects/train/thyme/pot/script.gd")
const Bird = preload("res://objects/bird/script.gd")
const BirdScene = preload("res://objects/bird/Bird.tscn")
const MIN_CLUMP_TIME = 6.5
const MAX_CLUMP_TIME = 9.5
const MIN_CLUMP_AMOUNT = 3
const MAX_CLUMP_AMOUNT = 5
const MIN_SPAWN_TIME = 0.3
const MAX_SPAWN_TIME = 0.9

@export_node_path("Node") var level
var cur_clump_num = 0


func _enter_tree(): set_delayed_clump_spawn(MIN_CLUMP_TIME / 2)


func spawn_bird():
	# create node and target it to a random bush of thyme
	var available_thyme = get_available_thyme()
	if available_thyme.size() > 0:
		var bird: Bird = BirdScene.instantiate()
		bird.position = $StartingPositions.get_children().pick_random().position
		bird.target = available_thyme.pick_random()
		bird.target.connect("thyme_taken", func(): if bird: bird.target = null)
		bird.connect("escaped_with_thyme", (get_node(level) as Level).on_bird_escaped_with_thyme)
		bird.connect("grabbed_thyme", (get_node(level) as Level).on_bird_grabbed_thyme)
		add_child(bird)
	
	# keep spawning birds until clump done
	cur_clump_num -= 1
	if cur_clump_num > 0:
		var t = create_tween()
		t.tween_interval(randf_range(MIN_SPAWN_TIME, MAX_SPAWN_TIME))
		t.tween_callback(spawn_bird)
	else:
		emit_signal("clump_finished")


func spawn_clump():
	cur_clump_num = clampi(get_available_thyme().size() + 1, MIN_CLUMP_AMOUNT, MAX_CLUMP_AMOUNT)
	spawn_bird()
	await "clump_finished"
	set_delayed_clump_spawn(randf_range(MIN_CLUMP_TIME, MAX_CLUMP_TIME))


func set_delayed_clump_spawn(delay: float):
	var t = create_tween()
	t.tween_interval(delay)
	t.tween_callback(spawn_clump)


func get_available_thyme():
	var result = []
	var empty_pots = get_tree().get_nodes_in_group("pot").filter(func(p: Pot): return not p.is_empty)
	var targeted_pots = get_targeted_pots()
	if targeted_pots.size() >= empty_pots.size(): return empty_pots
	for p in empty_pots:
		if targeted_pots.find(p) == -1:
			result.push_back(p)
	return result


func get_targeted_pots():
	var result = []
	var birds = get_tree().get_nodes_in_group("bird")
	for b in birds:
		var p = (b as Bird).target
		if result.find(p) == -1: result.push_back(p)
	return result
