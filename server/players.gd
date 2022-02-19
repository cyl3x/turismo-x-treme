extends Node

const default_car = "Dodge"

var _cam_pos = Vector3(0,0,0)

var list = {}
var list_hash = {}.hash()
var new_list = {}
var new_list_update = false
var will_data_update = false
var show_fps = false
var alternative_controls = false

const color_list : Array = [
	"#f4f4f4",
	"#ffea04",
	"#f57c1f",
	"#dd1a22",
	"#7e131b",
	"#b61c7e",
	"#f6accd",
	"#4b2f93",
	"#00395e",
	"#00bed4",
	"#009247",
	"#004b2d",
	"#6a2e14",
	"#3a180e",
	"#e4edce",
	"#42433e",
	"#c39738",
	"#878c8f",
]

signal list_updated()
signal list_data_updated()
signal list_car_pos_updated()
signal list_pos_updated()

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	var nickname = ""
	
	if OS.has_environment("USERNAME"):
		nickname = OS.get_environment("USERNAME")
	elif OS.has_environment("USER"):
		nickname = OS.get_environment("USER")
	else:
		var f = File.new()
		f.open('res://assets/nicknames.txt', File.READ)
		var line = RandomNumberGenerator.new()
		line.randomize()
		line = line.randi_range (1,200)
		for i in 200:
			if i == line:
				nickname = f.get_line()
			else:
				f.get_line()
			
	Sync.request_nickname(nickname)
		
#########################################
#              Leon

func set_cam_pos(pos: Vector3):
	_cam_pos = pos

func get_cam_pos() -> Vector3:
	return _cam_pos

#########################################
#        Getter / Setter
func get_nickname(id : int = Sync.me) -> String:
	if id == 0 or id == Sync.me or not list.has(id):
		return Sync.player_data.nickname
	else:
		return list[id].data.nickname
	
func get_car_name(id : int = Sync.me) -> String:
	if id == 0 or id == Sync.me:
		return Sync.player_data.car
	else:
		return list[id].data.car
	
func get_car_res(id : int = Sync.me) -> String:
	if id == 0 or id == Sync.me:
		return _make_car_res(Sync.player_data.car)
	else:
		return _make_car_res(list[id].data.car)

func get_place(id : int = Sync.me) -> int:
	if id == 0 or id == Sync.me:
		return Sync.player_pos.place
	elif not list.has(id):
		return 99
	else:
		return list[id].pos.place
		
func get_lap(id : int = Sync.me) -> int:
	if id == 0 or id == Sync.me:
		return Sync.player_pos.lap
	else:
		return list[id].pos.lap
		
func get_map_offset(id : int = Sync.me) -> float:
	if id == 0 or id == Sync.me:
		return Sync.player_car_pos.map_offset
	else:
		return list[id].car_pos.map_offset

func get_car_position(id : int = Sync.me):
	return list[id].car_pos.pos

func get_color(id : int = Sync.me) -> String:
	if list.has(id):
		return color_list[list[id].keys().find(id)]
	else: return "#000000"

func set_car_position(id : int, car_pos):
	if id == Sync.me:
		Sync.request_car_pos(car_pos)

func set_car(car : String):
	var directory = Directory.new();
	if directory.file_exists(_make_car_res(car)):
		Sync.request_car(car)
	else:
		print("Game: Selected Car is not valid")
		
func set_nickname(nickname : String):
	Sync.request_nickname(nickname)
	
func set_map_offset(offset):
	Sync.request_map_offset(offset)

#########################################
#        Sync Server / Clients

func past_checkpoint(id: int):
	Sync.request_past_checkpoint(id)

func has(id : int):
	return list.has(id)

func get(id):
	if list.has(id):
		return list[id]
	else:
		return null

func keys():
	return list.keys()

func size():
	return list.size()
	
func is_me(id : int):
	return id == Sync.me

func _make_car_res(car_name):
	return "res://cars/" + car_name + "/" + car_name + ".tscn"

		
func has_finished(id: int = Sync.me):
	return Sync.player_fin_array.has(id)

func set_new_list(new_new_list):
	new_list = new_new_list
	new_list_update = true
	
func player_left(_id):
	will_data_update = true
	
func reset():
	will_data_update = true

func _process(_delta):
	if new_list_update:
		new_list_update = false
		list = new_list.duplicate()
		list_hash = list.hash()
		emit_signal("list_updated")
		
		if not Server._game_running || will_data_update:
			will_data_update = false
			if not Server.IS_STANDALONE_SERVER:
				emit_signal("list_data_updated")
		elif not Server.IS_STANDALONE_SERVER:
			emit_signal("list_pos_updated")
			emit_signal("list_car_pos_updated")
