extends Node

const default_car = "Dodge"

var current_car_stats = {}

var _cam_pos = Vector3(0,0,0)

var list = {}
var list_hash = {}.hash()
var new_list = {}
var new_list_update = false
var new_list_player_size_update = false
var will_data_update = false
var show_fps = false
var view_distance = 100

var best_times = {}
var total_times = {}
var best_times_hash = {}.hash()
var total_times_hash = {}.hash()

enum JoystickMode {OFF, ON, BUTTONS, ACCELEROMETER}
var touch_controls = JoystickMode.OFF

const color_list : Array = [
	"#72BE68", # grün
	"#F1CB0B", # gelb
	"#FE7709", # orange
	"#F8B98E", # lachsfarben
	"#F1485B", # rot, mal sehen (admin?)
	"#B776D8", # lila
	"#36862C", # dunkelgrün
	"#094FA0", # dunkelblau
	"#f6accd", # rosa
	"#00bed4", # tuerkis
	"#b61c7e", # pink
	"#6a2e14", # braun
	"#C05B16", # braun-orange
	"#e4edce", # beasch
	"#89B7FE", # blau, mal sehen
]

signal list_updated()
signal list_data_updated()
signal list_car_pos_updated()
signal list_pos_updated()
signal player_left()
signal best_times_updated()
signal total_times_updated()
signal start_time_updated(time)
signal car_switched(car)

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
	
	if Config.has_player_setting("car_name"):
		set_car(Config.get_player_setting("car_name"))
	else:
		set_car(default_car)
		
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
		return make_car_res(Sync.player_data.car)
	else:
		return make_car_res(list[id].data.car)

func get_place(id : int = Sync.me) -> int:
	if id == 0 or id == Sync.me:
		if Sync.player_pos.fin_as > 0:
			return Sync.player_pos.fin_as
		else:
			return Sync.player_pos.place
	elif not list.has(id):
		return 99
	else:
		if list[id].pos.fin_as > 0:
			return list[id].pos.fin_as
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
	if id == Sync.me:
		return "#89B7FE"
	elif list.has(id):
		return color_list[list.keys().find(id)]
	else: return "#000000"

func set_car_position(id : int, car_pos):
	if id == Sync.me:
		Sync.request_car_pos(car_pos)

func set_car(car : String):
	var directory = Directory.new();
	if directory.file_exists(make_car_res(car)):
		Sync.request_car(car)
		emit_signal("car_switched", car)
		Config.set_player_setting("car_name", car)
	else:
		print("Game: Selected Car is not valid")
		if Config.has_player_setting("car_name") and Config.get_player_setting("car_name") == car:
			set_car(default_car)
		
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
	
func is_me(id : int) -> bool:
	return id == Sync.me

func make_car_res(car_name):
	return "res://cars/" + car_name + "/" + car_name + ".tscn"

		
func has_finished(id: int = Sync.me):
	return Sync.player_fin_array.has(id)

func set_new_list(new_new_list):
	new_list_player_size_update = new_new_list.size() < list.size()
	new_list = new_new_list
	new_list_update = true
	
func player_left(_id):
	will_data_update = true
	
func reset():
	will_data_update = true
	best_times = {}
	total_times = {}

func start_time_update(time):
	emit_signal("start_time_updated", time)
	
func touch_controls_active():
	return Players.touch_controls > 0

func _process(_delta):
	if new_list_update:
		new_list_update = false
		list = new_list.duplicate()
		list_hash = list.hash()
		emit_signal("list_updated")
		
		if new_list_player_size_update:
			new_list_player_size_update = false
			emit_signal("player_left")
		
		if not Server._game_running || will_data_update:
			will_data_update = false
			if not Server.IS_STANDALONE_SERVER:
				emit_signal("list_data_updated")
		elif not Server.IS_STANDALONE_SERVER:
			emit_signal("list_pos_updated")
			emit_signal("list_car_pos_updated")
			
	if best_times.hash() != best_times_hash:
		best_times_hash = best_times.hash()
		emit_signal("best_times_updated")
			
	if total_times.hash() != total_times_hash:
		total_times_hash = total_times.hash()
		emit_signal("total_times_updated")
