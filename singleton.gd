extends Node


var current_scene: Node
var menu_main = preload("res://menus/SceneMenuMain.tscn")
var menu_win = preload("res://menus/win/SceneMenuWin.tscn")
var menu_lose = preload("res://menus/lose/SceneMenuLose.tscn")
var level_train = preload("res://levels/train/SceneLevelTrain.tscn")
var last_window_mode
var data = {
	"high_scores": [],
	"muted": false
}


func _ready():
	last_window_mode = DisplayServer.window_get_mode()
	load_data()
	main()


func _unhandled_input(event):
	if event.is_action_pressed("fullscreen"):
		var new_last = DisplayServer.window_get_mode()
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(last_window_mode)
		last_window_mode = new_last


func load_scene(scene: PackedScene):
	if current_scene: remove_child(current_scene)
	current_scene = scene.instantiate()
	add_child(current_scene)


func play():
	load_scene(level_train)
	current_scene.connect("win", on_game_over.bind(true))
	current_scene.connect("lose", on_game_over.bind(false))
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func exit(): get_tree().quit()


func main():
	load_scene(menu_main)
	current_scene.load_scores(data["high_scores"])
	current_scene.get_node("%PlayButton").connect("pressed", play)
	var exit_button = current_scene.get_node("%ExitButton")
	if exit_button: exit_button.connect("pressed", exit)


func on_game_over(time_remaining: float, thyme_remaining: int, distance_travelled: float, distance_remaining: float, won: bool):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if won:
		var base_win_score = 1000
		var time_bonus = ceil(time_remaining * 200)
		var thyme_bonus = thyme_remaining * 200
		save_score(base_win_score + time_bonus + thyme_bonus)
		load_scene(menu_win)
		current_scene.set_time_remaining(time_remaining)
		current_scene.set_thyme_remaining(thyme_remaining)
		current_scene.get_node("ButtonReplay").connect("pressed", play)
		current_scene.get_node("ButtonMain").connect("pressed", main)
	else:
		load_scene(menu_lose)
		current_scene.get_node("ButtonReplay").connect("pressed", play)
		current_scene.get_node("ButtonMain").connect("pressed", main)
		current_scene.set_distance(distance_travelled)
		current_scene.set_destination(distance_remaining)
		current_scene.set_time(time_remaining)
		current_scene.set_thyme(thyme_remaining)


func save_data():
	var save_game = FileAccess.open("user://scores.save", FileAccess.WRITE)
	save_game.store_line(JSON.stringify(data))


# https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
func save_score(score: int):
	data["high_scores"].push_back(score)
	data["high_scores"].sort()
	data["high_scores"].reverse()
	data["high_scores"].slice(0, 10) # save top 10 scores
	save_data()


# https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
func load_data():
	if not FileAccess.file_exists("user://scores.save"): return
	var save_game = FileAccess.open("user://scores.save", FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		var node_data = json.get_data()
		for k in node_data: data[k] = node_data[k]
