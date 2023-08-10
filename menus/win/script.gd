extends Control


const BASE_SCORE = 1000
var time_bonus = 0
var thyme_bonus = 0


func _ready(): $ButtonReplay.grab_focus()


func set_time_remaining(value: float):
	time_bonus = ceil(value * 200)
	$LabelScoreTime.text = "Time bonus: %d x 200 = %d" % [ceil(value), time_bonus]
	set_total_score()


func set_thyme_remaining(value: int):
	thyme_bonus = value * 200
	$LabelScoreThyme.text = "Thyme bonus: %d x 200 = %d" % [value, thyme_bonus]
	set_addition_text()
	set_total_score()


func set_addition_text():
	$LabelAddition.text = "%d + %d + %d =" % [BASE_SCORE, time_bonus, thyme_bonus]


func set_total_score():
	var total = BASE_SCORE + time_bonus + thyme_bonus
	$LabelScoreTotal.text = "Total score: %d" % total
