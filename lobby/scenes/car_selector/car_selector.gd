extends Control

onready var car_name = $PlayerSettings/CarName

var index = 0

var car_list = []

signal switch(to)

func _ready():
	var _discart1 = Server.connect("game_reset", self, "_reset")
	car_list = _get_cars()
	index = car_list.find(Players.get_car_name())
	_change_car()

func _on_car_select(intdx):
	index = _clamp_around(index, intdx)
	_change_car()

func _clamp_around(value, change):
	if value + change < 0: return car_list.size() - 1
	elif value + change > car_list.size() - 1: return 0
	else: return value + change
	
func _change_car():
	Players.set_car(car_list[index])
	car_name.text = str(car_list[index])
	
func _get_cars():
	var output = []
	var dir = Directory.new()
	if dir.open("res://cars") == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				output.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		
	return output

func _reset():
	index = car_list.find(Players.get_car_name())
	_change_car()


func _on_Back_pressed():
	emit_signal("switch", "main")
