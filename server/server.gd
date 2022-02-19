extends Node

# Settings
const COMPRESS_MODE = 4
var SERVER_IP = "127.0.0.1"
var SERVER_PORT = 25600
var IS_STANDALONE_SERVER = false
var ADMIN_ID = 0
var MAX_PLAYERS = 14

var VIEWPORT_SCALE_FACTOR = 1.0

onready var lobby = get_node("/root/Lobby")
onready var player_list = get_node("/root/Lobby/Server")

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
signal kicked(reason)
signal end_timer(time)
signal viewport_factor_changed(factor)

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	var _discart1 = get_tree().connect("network_peer_connected", self, "_on_player_connected")
	var _discart2 = get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	var _discart3 = get_tree().connect("connection_failed", self, "_on_connection_failed")
	var _discart4 = get_tree().connect("server_disconnected", self, "_server_disconnected")
	var _discart5 = get_tree().connect("connected_to_server", self, "_connected_to_server")
	var _discart6 = Players.connect("list_updated", self, "_player_list_updated")
	
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		VIEWPORT_SCALE_FACTOR = 0.6
	
	queue = preload("res://server/queue.gd").new()
	queue.start()
	
	settings["laps"] = 4
	settings["map"] = "Don Speedway"
	
func host_server(port):
	network = NetworkedMultiplayerENet.new()
	#network.compression_mode(COMPRESS_MODE)

	network.create_server(int(port), int(MAX_PLAYERS))
	get_tree().set_network_peer(network)
		
	emit_signal("connection_succeeded")
	emit_signal("server_started")
	
	ADMIN_ID = 0

	print("Server: Started on port " + str(port))
	
func connect_to_server(hostname, port):
	network = NetworkedMultiplayerENet.new()
	SERVER_IP = hostname
	SERVER_PORT = port
	#network.compression_mode(COMPRESS_MODE)
		
	print("Connection: Try to connect to " + str(hostname) + ":" + str(port))
	
	network.create_client(hostname, int(port))
	get_tree().set_network_peer(network)

	emit_signal("connection_pending")

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
	player_list.set_error_message("Server not available")
	lobby.enable_normal()
	
func _server_disconnected():
	print("Connection: Server closed connection")
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
		player_list.set_error_message(reason)
		close_client()

func server_startGame():
	if is_admin():
		rpc_id(1, "request_pre_configure_game", settings)
		
remotesync func request_pre_configure_game(settings):
	var keys = Sync.player_list.keys()
	keys.shuffle()
	rpc("pre_configure_game", settings, keys)
	
remotesync func pre_configure_game(new_settings, player_order):
	settings = new_settings
	player_spawn_order = player_order

	if is_server():
		Sync.request_server_pre_configure()
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

		assert(who in Players.keys() or who == 1, "Preconfiguring: Non-exsting Player can not be ready?") # Exists
		assert(not who in players_done, "Preconfiguring: Player is already marked as 'done'") # Was not added yet
			
		players_done.append(who)

		var correction = 1 if IS_STANDALONE_SERVER else 0 

		if who != 1 or !IS_STANDALONE_SERVER:
			print("Game: " + str(players_done.size() - correction) + "/" + str(Players.size()) + " Player(s) are ready (" + str(who) + ")")

		if (players_done.size() - correction) == Players.size():
			print("Game: Starting game ...")
			rpc("post_configure_game")

remotesync func post_configure_game():
	# Only the server is allowed to tell a client to unpause
	if 1 == get_tree().get_rpc_sender_id():
		_game_running = true
		game_pre_configuring_player_ready = false
		emit_signal("game_started")
		
		
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
		settings = new_settings

func set_map(map : String):
	if is_admin():
		var directory = Directory.new();
		if directory.file_exists(make_map_res(map)):
			settings["map"] = map
		else:
			print("Game: Selected Map is not valid")
	else:
		print("Game: No permission to set settings")
		
func set_laps(laps : int):
	if is_admin():
		settings["laps"] = laps
	else:
		print("Game: No permission to set settings")
		
func get_map():
	return settings["map"]
		
func get_laps():
	return settings["laps"]
	
func is_game_running():
	return _game_running

func is_network_active():
	if network != null:
		return network.get_connection_status() == network.CONNECTION_CONNECTED
	else: return false
		
###############################################
#              Miscellaneous
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
		else: ADMIN_ID = 0

remotesync func _set_admin(admin_id):
	ADMIN_ID = admin_id
	if not _game_running:
		lobby.enable_admin(ADMIN_ID == Sync.me)

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
	#return IP.get_local_interfaces()[0].addresses[0]
	return IP.get_local_addresses()[0]
	
func game_pre_configuring_player_is_ready():
	if game_pre_configuring and not game_pre_configuring_player_ready:
		game_pre_configuring_player_ready = true
