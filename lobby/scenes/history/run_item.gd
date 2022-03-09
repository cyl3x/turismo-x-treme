extends Control

onready var hbox = $hbox
onready var background = $background
onready var l_id = $hbox/id
onready var l_run_name = $hbox/run_name
onready var l_map = $hbox/map
onready var l_laps = $hbox/laps
onready var l_players = $hbox/players
onready var l_date = $hbox/date

const l_count = 6
const color_selfhost = Color("#1a93c7")
const color_normal = Color("#1EA7E1")

var current_id = -1

var realign = false

signal pressed(id)

func init(id : int, run_name : String, map : String, laps : int, players : int, unix_time : int, selfhost : bool):
	l_id.text = "#" + str(id)
	l_run_name.text = str(run_name)
	l_map.text = str(map)
	l_laps.text = str(laps)
	l_players.text = str(players) + "P."
	
	var time : Dictionary = OS.get_datetime_from_unix_time(unix_time)
	
	l_date.text = "%02d:%02d %02d.%02d.%02d" % [time.hour, time.minute, time.day, time.month, int(str(time.year).substr(2))]
	
	if selfhost:
		background.modulate = color_selfhost
	else:
		background.modulate = color_normal
		
	current_id = id
	
	realign = true

func _on_Button_pressed():
	if current_id > -1:
		emit_signal("pressed", current_id)

func _process(_delta):
	if realign:
		var separation = (l_id.rect_position.x - (background.rect_position.x + 10 * (l_count - 1))) / (l_count - 1)
		hbox.add_constant_override("separation", separation)
		hbox.alignment = hbox.ALIGN_CENTER
		realign = false
