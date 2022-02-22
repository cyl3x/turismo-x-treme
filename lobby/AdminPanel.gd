extends Control


onready var mapSelector = $Settings/MapSelection

var maps = []


# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible = false
	maps = get_maps()
	for map in maps:
		var split = map.split(".")
		mapSelector.add_item(split[0])

func get_maps():
	var output = []
	var dir = Directory.new()
	if dir.open("res://maps") == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				output.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		
	return output
	
func refresh():
	$Settings/RoundCount.value = Server.get_laps()
	$Settings/MapSelection.select(maps.find(Server.get_map(), 0))
	$Settings/startTimerButton.pressed = Server.get_start_timer_active()

func _on_settings_pressed():
	self.visible = !self.visible
	
func _on_map_selected(index):
	Server.set_map(mapSelector.get_item_text(index))

func _on_round_count_changed(value):
	Server.set_laps(value)

func _on_start_timer_toggled(button_pressed):
	Server.set_start_timer(button_pressed)
