extends Control

const max_speed = 220 # fuer tacho
const needle_start_rotation = -136
const needle_max_rotation = 136 + 92
onready var needle = $speedneedle
onready var speed = $speed

func set_speed(speed_value):
	needle.rect_rotation = needle_start_rotation + needle_max_rotation * (speed_value / max_speed)
	speed.text = str(stepify(speed_value, 1))
	
func set_boosting(is_boosting):
	if is_boosting:
		speed.add_color_override("font_color", Color.goldenrod)
	else:
		speed.add_color_override("font_color", Color.white)
