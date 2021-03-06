extends Node

# Settings
var SERVER_IP = "127.0.0.1"
var SERVER_PORT = 25600
var IS_STANDALONE_SERVER = false
var ADMIN_ID = 0
var MAX_PLAYERS = 14

var hostname = "godot.cyl3x.de:25600"

var VIEWPORT_SCALE_FACTOR = -1.0
var IS_MOBILE

onready var lobby = get_node("/root/Lobby")
onready var player_list = get_node("/root/Lobby/main/HBox/Server")

var network = null

var queue

var settings = {}
var player_spawn_order = []

var players_done = []
var server_ready = false

var _game_running = false
var game_pre_configuring = false
var game_pre_configuring_player_ready = false

var ip_adresses = {
	"internal": "0.0.0.0",
	"external": "0.0.0.0"
}

signal server_started()
signal connection_failed()
signal connection_succeeded()
signal connection_pending()
signal game_reset()
signal game_started()
signal game_ended()
signal admin_changed()
signal run_name_changed(run_name)
signal kicked(reason)
signal end_timer(time)
signal viewport_factor_changed(factor)
signal dialog(type, title, text)

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	var _discart1 = get_tree().connect("network_peer_connected", self, "_on_player_connected")
	var _discart2 = get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	var _discart3 = get_tree().connect("connection_failed", self, "_on_connection_failed")
	var _discart4 = get_tree().connect("server_disconnected", self, "_server_disconnected")
	var _discart5 = get_tree().connect("connected_to_server", self, "_connected_to_server")
	var _discart6 = Players.connect("list_updated", self, "_player_list_updated")
	
	if Config.has_setting("render_factor"):
		VIEWPORT_SCALE_FACTOR = Config.get_setting("render_factor")
		
	if Config.has_server_setting("hostname"):
		hostname = Config.get_server_setting("hostname")
		
	if OS.get_name() in [ "Android", "iOS" ]:
		IS_MOBILE = true
		if VIEWPORT_SCALE_FACTOR == -1.0:
			VIEWPORT_SCALE_FACTOR = 0.6
			Config.set_setting("render_factor", 0.6)
	elif VIEWPORT_SCALE_FACTOR == -1.0:
		VIEWPORT_SCALE_FACTOR = 1.0
		Config.set_setting("render_factor", 1.0)
	
	settings["run_name"] = Players.get_nickname() + "'s Game"
	
	queue = preload("res://server/queue.gd").new()
	queue.start()
	
	if Config.has_server_setting("laps"):
		set_laps(Config.get_server_setting("laps"))
	else:
		set_laps(4)
	
	if Config.has_server_setting("map"):
		set_map(Config.get_server_setting("map"))
	else:
		set_map("Don Speedway")
	
	if Config.has_server_setting("start_timer"):
		set_start_timer(Config.get_server_setting("start_timer"))
	else:
		set_start_timer(false)
	
func host_server(port):
	network = NetworkedMultiplayerENet.new()
	MAX_PLAYERS = clamp(MAX_PLAYERS, 1, 14)
	network.create_server(int(port), int(MAX_PLAYERS))
	get_tree().set_network_peer(network)
		
	emit_signal("connection_succeeded")
	emit_signal("server_started")
	
	settings["run_name"] = Players.get_nickname() + "'s Game"
	
	ADMIN_ID = 0
	Sync.player_list = {}

	print("Server: Started on port " + str(port))
	
func connect_to_server(name, port):
	network = NetworkedMultiplayerENet.new()
	SERVER_IP = name
	SERVER_PORT = port
	ADMIN_ID = 0
	Sync.player_list = {}
	
	network.create_client(name, int(port))
	
	if network.get_connection_status() == NetworkedMultiplayerENet.CONNECTION_DISCONNECTED:
		emit_signal("connection_failed")
		emit_signal("dialog", 1, "Connection failed", "Host not available")
		print("Connection: Host " + str(name) + ":" + str(port) + " not available")
	else:
		get_tree().set_network_peer(network)
		emit_signal("connection_pending")
		print("Connection: Try to connect to " + str(name) + ":" + str(port))
		Config.set_server_setting("hostname", str(name) + ":" + str(port))

func _on_player_connected(id):
	if _game_running and is_server():
		print("Server: " + str(id) + " tried to connect to a running game")
		rpc_id(id, "kick", "Game is already running ...")
	else:
		print("Players: " + str(id) + " connected")
		print("Players: " + str(Players.size() + 1) +  " Player(s) connected")

func _on_player_disconnected(id):
	print("Players: " + str(id) + " disconnected")
	print("Players: " + str(Players.size() - 1) +  " Player(s) connected")
	Sync.request_left_player(id)
	Players.player_left(id)
	
func _connected_to_server():
	emit_signal("connection_succeeded")
	print("Connection: Successfully connected")
	
func _on_connection_failed():
	print("Connection: Server not available")
	emit_signal("connection_failed")
	emit_signal("dialog", 1, "Connection failed", "Server not available")
	
func _server_disconnected():
	print("Connection: Server closed connection")
	emit_signal("dialog", 1, "Disconnect", "Server closed connection")
	close_client()
	
########################################
#         Register stuff                 

func close_server():
	if is_server():
		for id in Players.keys():
			if id != 1:
				rpc_id(id, "kick", "Server Closed")
				network.disconnect_peer(id)

		server_ready = false
		players_done = []
		
		network.close_connection()
		network = null
		
		reset_game()

func close_client():
	if network == null:
		get_tree().quit()
		print("Game: Quit")
	else:
		network.close_connection()
		network = null
		print("Connection: Reseted")
		reset_game()

func reset_game():
	ADMIN_ID = 0
	player_spawn_order = []
	players_done.clear()
	get_tree().set_pause(false)
	_game_running = false
	Players.reset()
	Sync.request_reset()

	if has_node("/root/gameManager") && get_node("/root/gameManager") != null:
		get_node("/root/gameManager").queue_free()

	if not IS_STANDALONE_SERVER:
		print("Game: Reseted")
	else:
		print("Server: Lobby Reseted")

	emit_signal("game_reset")

###############################################
#              GameStart stuff

remote func kick(reason):
	if !is_server():
		Sync.request_reset()
		print("Kicked: " + reason)
		emit_signal("kicked", reason)
		emit_signal("dialog", 1, "Disconnect", reason)
		close_client()

func server_startGame():
	if is_admin():
		rpc_id(1, "request_pre_configure_game", settings)
		
remotesync func request_pre_configure_game(new_settings):
	var keys = Sync.player_list.keys()
	keys.shuffle()
	rpc("pre_configure_game", new_settings, keys)
	
remotesync func pre_configure_game(new_settings, player_order):
	settings = new_settings
	player_spawn_order = player_order
	
	get_tree().paused = true

	if is_server():
		print("Game: Preconfigure game of Players ...")

	if !_game_running:
		game_pre_configuring = true
		
		var already = []
		for id in Players.keys():
			var res = Players.get_car_res(id)
			if not res in already:
				queue.queue_resource(Players.get_car_res(id))
				already.append(res)
		queue.queue_resource(make_map_res(settings.map))
		queue.queue_resource("res://game/gameManager.tscn")
	
func pre_configure_game_finish():
	if game_pre_configuring and not get_node("/root").has_node("gameManager"):
		if not queue.is_ready("res://game/gameManager.tscn") or not queue.is_ready(make_map_res(settings.map)):
			if not Sync.pre_configured:
				return (queue.get_progress("res://game/gameManager.tscn") + queue.get_progress(make_map_res(settings.map))) / 2
			
		var gm = queue.get_resource("res://game/gameManager.tscn").instance()
		gm.name = "gameManager"
		get_node("/root").add_child(gm)
		get_node("/root").move_child(gm, 0)
		
		return 0.99
	elif game_pre_configuring and get_node("/root").has_node("gameManager") and game_pre_configuring_player_ready:
		game_pre_configuring_player_ready = false
		game_pre_configuring = false
		rpc_id(1, "done_preconfiguring")
		return -1
	else: return 0.99


remotesync func done_preconfiguring():
	if is_server():
		var who = get_tree().get_rpc_sender_id()

		if who in players_done:
			print("Preconfiguring: Player " + Players.get_nickname() + " (" + str(who) + ") was already marked as 'done'")
			return
			
		if not (IS_STANDALONE_SERVER and who == 1):
			players_done.append(who)
			print("Preconfiguring: " + str(players_done.size()) + "/" + str(Players.size()) + " Player(s) are ready (" + str(who) + ")")

		if players_done.size() == Players.size():
			print("Preconfiguring: Starting game ...")
			rpc("post_configure_game")

remotesync func post_configure_game():
	# Only the server is allowed to tell a client to unpause
	if 1 == get_tree().get_rpc_sender_id():
		History.start_new_game(settings["run_name"], settings["map"], settings["laps"], settings["start_timer"], Players.size(), is_server())
		_game_running = true
		game_pre_configuring_player_ready = false
		emit_signal("game_started")
		print("Game: Game started")
		
		
###############################################
#              GameEnd Stuff
		
func end_game_for(id: int):
	rpc_id(id, "end_game")
	
remotesync func end_game():
	emit_signal("game_ended")

func sync_end_timer(time):
	rpc_unreliable("update_end_timer", time)

remotesync func update_end_timer(time):
	emit_signal("end_timer", time)
	
###############################################
#              Server Settings
func sync_settings_to_server():
	if is_admin():
		rpc_id(1, "_recv_admin_settings", settings)

remotesync func _recv_admin_settings(new_settings):
	if is_server() and is_admin(get_tree().get_rpc_sender_id()):
		set_laps(new_settings["laps"])
		set_map(new_settings["map"])
		set_start_timer(new_settings["start_timer"])

func set_map(map : String):
	if is_admin() || !is_network_active():
		var directory = Directory.new();
		if directory.file_exists(make_map_res(map)):
			Config.set_server_setting("map", map)
			settings["map"] = map
		else:
			print("Game: Selected Map is not valid")
	else:
		print("Game: No permission to set settings")
		
func set_laps(laps : int):
	if is_admin() || !is_network_active():
		Config.set_server_setting("laps", laps)
		settings["laps"] = laps
	else:
		print("Game: No permission to set settings")
		
func set_run_name(run_name : String):
	if is_admin() || !is_network_active():
		settings["run_name"] = run_name
		emit_signal("run_name_changed", run_name)
	else:
		print("Game: No permission to set settings")
		
func set_start_timer(start_timer : bool):
	if is_admin() || !is_network_active():
		Config.set_server_setting("start_timer", start_timer)
		settings["start_timer"] = start_timer
	else:
		print("Game: No permission to set settings")
		
func get_map():
	return settings["map"]
		
func get_laps():
	return settings["laps"]
		
func get_start_timer_active():
	return settings["start_timer"]
		
func get_run_name():
	return settings["run_name"]
	
func is_game_running():
	return _game_running

func is_network_active():
	if network != null:
		return network.get_connection_status() == network.CONNECTION_CONNECTED
	else: return false
		
###############################################
#              Miscellaneous
func get_hostname():
	return hostname
	
func set_hostname(new_hostname):
	hostname = new_hostname

func is_admin(id = Sync.me):
	return ADMIN_ID == id
	
func is_server():
	return (is_network_active() && get_tree().is_network_server()) || IS_STANDALONE_SERVER

func make_map_res(map_name : String):
	return "res://maps/" + map_name + "/" + map_name + ".tscn"

func get_queue():
	return queue
	
func _player_list_updated():
	if is_server():
		if IS_STANDALONE_SERVER and Players.size() == 0 and _game_running:
			print("Server: All Players left, restarting Lobby ...")
			close_server()
			host_server(SERVER_PORT)
		elif Players.size() > 0:
			var first_id = Players.keys()[0]
			if first_id != ADMIN_ID:
				ADMIN_ID = first_id
				print("Server: Set Admin to " + str(ADMIN_ID))
				rpc_id(first_id, "_set_admin", first_id)
		else:
			ADMIN_ID = 0

remotesync func _set_admin(admin_id):
	ADMIN_ID = admin_id
	emit_signal("admin_changed")

func checkCMDArgs(args):
	if args.has("port"):
		SERVER_PORT = args["port"]
		print("Server: Set port to " + str(SERVER_PORT))
	if args.has("max-players"):
		MAX_PLAYERS = args["max-players"]
		print("Server: Set max players to " + str(MAX_PLAYERS))
	if args.has("server") && args["server"] == true:
		IS_STANDALONE_SERVER = true
		print("Server: Starting standalone server ...")
		host_server(SERVER_PORT)
		
func get_size_of(value) -> int:
	var sizeof = 0
	for bit in var2bytes(value):
		sizeof += bit
	return sizeof
	
func set_viewport_factor(value: float):
	VIEWPORT_SCALE_FACTOR = value
	emit_signal("viewport_factor_changed")
	
func internal_ip():
	var ips = IP.get_local_addresses()
	ips.erase("127.0.0.1")
	return ips[0]
	
func game_pre_configuring_player_is_ready():
	if game_pre_configuring and not game_pre_configuring_player_ready:
		game_pre_configuring_player_ready = true
