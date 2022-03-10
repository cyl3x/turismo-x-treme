extends Control

onready var hbox = $hbox
onready var background = $background
onready var l_place = $hbox/place
onready var l_nickname = $hbox/nickname
onready var l_car_name = $hbox/car_name
onready var l_best_lap_time = $hbox/best_lap_time
onready var l_total_lap_time = $hbox/total_lap_time
onready var l_left_before_end = $hbox/left_before_end

const l_count = 6
const color_normal = Color("#1a93c7")
const color_me = Color("#1EA7E1")
const color_left = Color("#F0F0F0")

var realign = false

var current_place = 99

func init(nickname : String, car_name : String, place : int, best_lap_millis, total_lap_millis, left_before_end : bool, is_me : bool):
	l_nickname.text = str(nickname)
	l_car_name.text = str(car_name)
	
	if best_lap_millis: l_best_lap_time.text = _format_millis(best_lap_millis)
	else: l_best_lap_time.text = "-"
	
	if total_lap_millis: l_total_lap_time.text = _format_millis(total_lap_millis)
	else: l_total_lap_time.text = "-"
	
	l_left_before_end.text = str(left_before_end)
	
	if place != 99:
		l_place.text = str(place) + "."
	else:
		l_place.text = "-"
	
	if not left_before_end:
		current_place = place
	
	if is_me:
		background.modulate = color_me
	elif left_before_end:
		background.modulate = color_left
	else:
		background.modulate = color_normal
		
	realign = true

func _format_millis(total_millis) -> String:
	var millis = (total_millis) % 1000
	var seconds = (total_millis / 1000) % 60
	var minutes = (total_millis / (1000 * 60)) % 60
	return "%02d:%02d.%03d" % [int(minutes), int(seconds), int(millis)]

func get_place():
	return current_place

func _process(_delta):
	if realign:
		var separation = (l_place.rect_position.x - (background.rect_position.x + 10 * (l_count - 1))) / (l_count - 1)
		hbox.add_constant_override("separation", separation)
		hbox.alignment = hbox.ALIGN_CENTER
		realign = false
