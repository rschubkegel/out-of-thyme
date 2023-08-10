extends Control


func _ready(): $ButtonReplay.grab_focus()


func set_distance(distance: float): pass


func set_destination(destination: float): $DestinationLabel.text = "Distance to delivery: %.0f ft" % destination


func set_time(time: float): $TimeLabel.text = "Time remaining: %.0f sec" % abs(time)


func set_thyme(thyme: int): $ThymeLabel.text = "Thyme remaining: %d" % thyme
