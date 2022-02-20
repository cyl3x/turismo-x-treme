extends Node

var thread
var mutex
var run = true
var threaded = false


var sync_tickrate_hz = 40 #33.33333333333 #hz
var sync_tickrate = int(1000.0/sync_tickrate_hz) #hz
const slowed_sync_tickrate = 5.0 #hz
var slowed_sync_ticks = 0 #per sync_tickrate
const sync_data_tickrate = 1.0 #hz
var sync_data_ticks = 0 #per sync_tickrate
const sync_place_tickrate = 5.0 #hz
var sync_place_ticks = 0 #per sync_tickrate

var last_settings_hash = {}.hash()

var me = 0
var is_server = false
var pre_configured = false

var reset = false
var finished = false

var ingame = false

var recv_player_data = {}
var recv_player_past_checks = {}

var player_list = {}
var player_list_hash = {}.hash()
var player_fin_array = [] #finished

var wait = false
var wait_time = -1
var wait_last_time = -1

var player_past_checkpoint = -1

const car_pos = {
	"slow_mov": false,
	"map_offset": 0,
	"pos": {}
}
const pos = {
	"lap": 0, 
	"place": 0, 
	"fin_as": -1, 
	"last": -1, 	
	"past": -1, 	
}
const data = {
	"nickname": "",
	"car": ""
}
var player_pos = pos
var player_data = data
var player_car_pos = car_pos
var last_data_hash = player_data.hash()
var last_car_pos_hash = player_car_pos.hash()

var run_milli = OS.get_ticks_msec()


func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	mutex = Mutex.new()
	
	if threaded:
		thread = Thread.new()
		var err = thread.start(self, "_thread_process", 0)
		if err != 0:
			print("Error: Sync-thread crashed: " + str(err))

func _process(_delta):
	if not threaded:
		run = true
		_thread_process(0)

func _thread_process(_u):
	while run:
		if OS.get_ticks_msec() - run_milli >= (sync_tickrate):
			run_milli = OS.get_ticks_msec()

			if me == 0 and Server.is_network_active():
				me = get_tree().get_network_unique_id()
			elif me != 0 and not Server.is_network_active():
				me = 0

			ingame = Server._game_running

			_lock()
			if me != 0:
				_sync()
			_unlock()

			if player_list_hash != player_list.hash():
				player_list_hash = player_list.hash()
				Players.set_new_list(player_list)
				
			if wait:
				wait_time -= 1.0/sync_tickrate
				_wait_timer()
				
			if reset:
				_lock()
				reset = false
				_reset()
				_unlock()
			
		if not threaded:
			run = false
	
func _sync():
	# Playercode
	if !Server.IS_STANDALONE_SERVER:
		if ingame:
			#check finish
			if not finished and player_fin_array.has(me):
				finished = true
				Server.end_game_for(me)
			#sync
			if last_car_pos_hash != player_car_pos.hash():
				last_car_pos_hash = player_car_pos.hash()
				# Car pos
				if player_car_pos.slow_mov:
					slowed_sync_ticks += 1
					if slowed_sync_ticks >= (sync_tickrate/slowed_sync_tickrate):
						slowed_sync_ticks = 0
						rpc_unreliable("_player_recv_player_car_pos", me, player_car_pos)
				else:
					rpc_unreliable("_player_recv_player_car_pos", me, player_car_pos)

			if player_past_checkpoint > -1:
				rpc_id(1, "_server_recv_player_past_checkpoint", me, player_past_checkpoint)
				player_past_checkpoint = -1
		else:
			sync_data_ticks += 1
			if last_data_hash != player_data.hash() or sync_data_ticks >= (sync_tickrate/sync_data_tickrate):
				sync_data_ticks = 0
				last_data_hash = player_data.hash()
				rpc_id(1, "_server_recv_player_data", me, player_data)

	# Server code
	if get_tree().is_network_server():
		# Process player DATA
		var players_to_update = {}
		if not ingame:
			if Server.is_admin() and last_settings_hash != Server.settings.hash():
				last_settings_hash = Server.settings.hash()
				Server.sync_settings_to_server()

			for id in recv_player_data:
				if not player_list.has(id): _add_player(id)
				players_to_update[id] = recv_player_data[id]
				recv_player_data.erase(id)
			
			if players_to_update.hash() != {}.hash():
				_player_recv_update_player_data(players_to_update)
				rpc("_player_recv_player_data", player_list)
			

		var player_pos_to_update = {}
		
		var hash_pos = player_pos_to_update.hash()
		
		var check_hash_fin = player_fin_array.hash()
		# Process player POSITIONS
		if ingame:	
			for id in recv_player_past_checks:
				if player_list[id].pos.hash() != {}.hash():
					player_pos_to_update[id] = _calc_lap(id, player_list[id].pos.duplicate(), recv_player_past_checks[id])
					recv_player_past_checks.erase(id)
			
			var new_places = _calc_places({})
			_player_recv_update_place(new_places)
			
			sync_place_ticks += 1
			if sync_place_ticks >= (sync_tickrate/sync_place_tickrate):
				sync_place_ticks = 0
				rpc_unreliable("_player_recv_update_place", new_places)
			
			for id in new_places:
				if player_pos_to_update.has(id):
					player_pos_to_update[id].place = new_places[id]
					
			if hash_pos != player_pos_to_update.hash():
				_player_recv_update_player_pos(player_pos_to_update)
				rpc_unreliable("_player_recv_update_player_pos", player_pos_to_update)
				
			if check_hash_fin != player_fin_array.hash():
				rpc("_player_recv_finished_list", player_fin_array)
				_player_recv_finished_list(player_fin_array)
			
			_check_end_game()

remotesync func _server_recv_player_data(id : int, new_recv_player_data):
	_lock()
	recv_player_data[id] = new_recv_player_data
	_unlock()
remotesync func _server_recv_player_past_checkpoint(id : int, past_checkpoint: int):
	_lock()
	recv_player_past_checks[id] = past_checkpoint
	_unlock()

remotesync func _player_recv_player_data(list):
	_lock()
	player_list = list
	_unlock()
remote func _player_recv_update_player_data(list):
	_lock()
	for id in list:
		if not player_list.has(id): continue
		_add_player(id)
		player_list[id].data = list[id]
	_unlock()
remote func _player_recv_update_player_pos(list):
	_lock()
	for id in list:
		if not player_list.has(id): continue
		player_list[id].pos = list[id]
		if id == me:
			player_pos = list[id]
	_unlock()
remote func _player_recv_update_player_car_pos(list):
	_lock()
	for id in list:
		if not player_list.has(id): continue
		player_list[id].car_pos = list[id]
	_unlock()
remote func _player_recv_update_place(list):
	_lock()
	for id in list:
		if not player_list.has(id): continue
		player_list[id].pos.place = list[id]
		if id == me:
			player_pos.place = list[id]
	_unlock()
remote func _player_recv_finished_list(list: Array):
	_lock()
	player_fin_array = list
	_unlock()

remotesync func _player_recv_player_car_pos(id:int, car_pos):
	_lock()
	player_list[id].car_pos = car_pos
	_unlock()

func _add_player(id : int):
	if not player_list.has(id):
		player_list[id] = {
			"data": {},
			"pos": pos,
			"car_pos": car_pos,
		}

func _calc_lap(id, pos, past):
	if past == 0:
		if pos.last == -1 and pos.lap > 0:
			if id != 1 and pos.lap != 1:
				print("Error: Player " + str(id) + " (" + Players.get_nickname(id) + ") has passed Start/Finish with wrong checkpoint id's, what a cheater")
		elif pos.last != 0:
			pos.lap += 1
		else:
			print("Error: Player " + str(id) + " (" + Players.get_nickname(id) + ") has passed Start/Finish without passing another/all checkpoint(s), lap invalid")
	elif past > 0:
		if past - 1 != pos.last:
			print("Warning: Player " + str(id) + " (" + Players.get_nickname(id) + ") has passed checkpoint '" + str(past) + "' without passing checkpoint '" + str(past - 1) + "'")
			past -= 1
		
	if past != -1 and past != pos.last:
		pos.last = past
		pos.past = -1

	if pos.lap > Server.get_laps():
		player_fin_array.append(id)
		pos.fin_as = player_fin_array.find_last(id) + 1

	return pos

func _calc_places(updated_car_pos):
	var placed: Array = []
	for id in player_list:
		var score = 0
		
		if updated_car_pos.has(id):
			score += updated_car_pos[id].map_offset * 100
		else:
			score += player_list[id].car_pos.map_offset * 100
			
		score += player_list[id].pos.lap * 10000000
		
		if player_list[id].pos.fin_as > 0:
			score += 10000000 / player_list[id].pos.fin_as
			
		placed.append({ "score": score, "id": id })
	
	placed.sort_custom(self, "_sort_list")
	
	var to_update = {}
	for i in range(placed.size()):
		var id = placed[i].id
		to_update[id] = (i + 1)
	
	return to_update
	
func _check_end_game():
	if player_list.size() > 0 and player_fin_array.size() >= 3 and player_list.size() > 3 and player_fin_array.size() < player_list.size() and not wait:
		wait = true
		wait_time = 60 * 2.5
		wait_last_time = 60 * 2.5
		Server.sync_end_timer(wait_time)
	elif player_list.size() > 0 and player_fin_array.size() == player_list.size() and not wait:
		wait = true
		wait_time = 60
		wait_last_time = 60
		Server.sync_end_timer(wait_time)
	elif player_list.size() == 0:
		Server.end_game_for(1)

func _wait_timer():
	if wait_time >= 0 and wait:
		# Sync per second
		if int(wait_time) != wait_last_time:
			wait_last_time = wait_time
			Server.sync_end_timer(int(wait_time))
	elif wait and wait_time < 0:
		wait = false
		var update_players = {}
		for id in player_list:
			if not player_fin_array.has(id):
				player_fin_array.append(id)
				update_players[id].pos = player_list[id].pos
				update_players[id].pos.fin_as = player_fin_array.find_last(id) + 1
				Server.end_game_for(id)
			elif player_fin_array.size() == player_list.size():
				Server.end_game_for(id)
		rpc_unreliable("_player_recv_update_player_pos", update_players)

func _reset():
	player_car_pos = car_pos
	player_pos = pos
	ingame = false
	finished = false
	
	recv_player_data = {}
	recv_player_past_checks = {}

	player_list = {}
	player_list_hash = {"fake":{}}.hash()
	player_fin_array = []

	player_past_checkpoint = -1
	me = 0
		
	wait = false
	wait_time = -1
	wait_last_time = -1
	
func request_left_player(id :int):
	_lock()
	player_list.erase(id)
	_unlock()

func request_reset():
	_lock()
	reset = true
	_unlock()

func request_past_checkpoint(idx):
	_lock()
	player_past_checkpoint = idx
	_unlock()

func request_car_pos(new_car_pos):
	_lock()
	player_car_pos.pos = new_car_pos
	_unlock()

func request_map_offset(new_map_offset):
	_lock()
	player_car_pos.map_offset = new_map_offset
	_unlock()

func request_slow_move(slow_move):
	_lock()
	player_car_pos.slow_mov = slow_move
	_unlock()

func request_nickname(new_nickname):
	_lock()
	player_data.nickname = new_nickname
	_unlock()

func request_car(new_car):
	_lock()
	player_data.car = new_car
	_unlock()
	
func override_player_list(list):
	_lock()
	player_list = list
	_unlock()

func _sort_list(a, b):
		return a.score > b.score
		
func _lock():
	if threaded:
		mutex.lock()
	
func _unlock():
	if threaded:
		mutex.unlock()

func _exit_tree():
	run = false
	if threaded:
		thread.wait_to_finish()
		
func checkCMDArgs(args):
	if args.has("syncrate"):
		sync_tickrate_hz = float(args["syncrate"])
		sync_tickrate = int(1000.0/sync_tickrate_hz)
		print("Sync: Set synchronisation rate to " + str(sync_tickrate_hz) + "hz")
