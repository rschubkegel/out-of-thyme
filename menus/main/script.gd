extends Control


const SCORE_PREFIXES = [
	"GOAT",
	"MVP",
	"Top dawg",
	"Just OK",
	"Barely made it",
]


func _ready():
	# remove exit button on web
	if OS.get_name() == "Web":
		%ExitButton.queue_free()
	%PlayButton.grab_focus()
	AudioServer.set_bus_mute(0, get_parent().data["muted"])
	on_mute_set()


func load_scores(high_scores):
	if high_scores.size() > 0:
		var placeholder = %ScoresContainer.get_children()[0]
		for c in %ScoresContainer.get_children():
			%ScoresContainer.remove_child(c)
		for i in range(min(high_scores.size(), 5)):
			var label = placeholder.duplicate()
			label.text = "%s: %d" % [SCORE_PREFIXES[i], high_scores[i]]
			%ScoresContainer.add_child(label)


func toggle_mute():
	AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
	get_parent().data["muted"] = AudioServer.is_bus_mute(0)
	get_parent().save_data()
	on_mute_set()


func on_mute_set():
	if AudioServer.is_bus_mute(0):
		$MuteButton/Mute.visible = true
		$MuteButton/Unmute.visible = false
	else:
		$MuteButton/Mute.visible = false
		$MuteButton/Unmute.visible = true


func reset_scores():
	get_parent().data["high_scores"] = []
	get_parent().save_data()
	get_parent().main()
