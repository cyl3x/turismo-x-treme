extends Node

var settings
var map_name
var map
var spawn_points
var _game_ended = false
var wait_time = 0
onready var lobby = get_node("/root/Lobby")

var boost_colors = {
	"active": PoolColorArray([Color.red.lightened(0.3), Color.orange, Color.yellow]),
	"passive": PoolColorArray([Color.blue.lightened(0.5), Color.cornflower, Color.aqua]),
	"recharge_cooldown": PoolColorArray([Color.gray.darkened(0.4), Color.gray.darkened(0.2), Color.gray]),
	"offsets": PoolRealArray([0, 0.2, 1])
}

const screen_margin: float = 15.0
onready var player_list = get_node("PlayerList")
onready var speedometer = get_node("Speedometer")
onready var place = get_node("place")
onready var lap = get_node("lap")
onready var timer = get_node("timer")
onready var return_to_lobby = get_node("ReturnLobby")
onready var boost_bar = get_node("BoostBar")

var queue = Server.get_queue()

func _ready():
	var _discart1 = Players.connect("list_updated", self, "_update_ui")
	var _discart2 = Server.connect("game_ended", self, "game_ended")
	var _discart3 = Server.connect("end_timer", self, "_end_timer")
	
	
	map_name = Server.get_map()
	if Server.is_server() && !Server.IS_STANDALONE_SERVER:
		print("Game: Loading " + map_name + " map with " + str(Server.get_laps()) + " laps")
	else:
		print("Game: Loading " + map_name + " map")
		
	#print(Server.make_map_res(map_name))
	map = queue.get_resource(Server.make_map_res(map_name)).instance()
	map.name = "world"
	add_child(map)
	
	if Server.IS_STANDALONE_SERVER:
		map.visible = false

	spawn_points = map.get_node("Spawns").get_children()

	#if Server.is_server():
	#	rpc("spawn_players")
	spawn_players()
		
	map.get_node("Tracking/Checkpoint0").connect("body_shape_entered", self, "_handle_checkpoints", [0])
	map.get_node("Tracking/Checkpoint1").connect("body_shape_entered", self, "_handle_checkpoints", [1])
	create_minimap(map.get_node("Tracking/Trackpath").get_curve())

	# Init PlayerList
	for key in Players.keys():
		player_list.add_item(" " + str(Players.get_place(key)) + ".  " + str(Players.get_nickname(key)))
		player_list.set_item_metadata(player_list.get_item_count() - 1, key)
		if key == Sync.me:
			player_list.set_item_custom_fg_color(player_list.get_item_count() - 1, Color("#87cef9"))
		else:
			player_list.set_item_custom_fg_color(player_list.get_item_count() - 1, Color("#ffffff"))

func _process(_delta):
	if Input.is_action_just_pressed("ui_menu"):
		lobby.toggle_menu()
		toggle_visibility()

	if Input.is_action_pressed("ui_tab"):
		player_list.visible = true
	elif not _game_ended:
		player_list.visible = false
		
func _end_timer(time):
	timer.visible = true
	if time > 0:
		var minutes = int(time / 60)
		timer.text = "%02d:%02d" % [minutes, int(time - minutes * 60)]
	elif time == -1:
		timer.text = "00:00"
		timer.visible = false
	else:
		timer.text = "00:00"
		Server.end_game()

remotesync func spawn_players():
	var spawn_point = 0
	
	for player_id in Players.keys():
		print("Game: Spawned " + str(player_id))
		spawn_player(int(player_id), spawn_point)
		spawn_point += 1
	
	map.truely_ready()

func spawn_player(id, spawn_point):
	var new_player = queue.get_resource(Players.get_car_res(id)).instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	
	new_player.set_position(spawn_points[spawn_point].translation,spawn_points[spawn_point].rotation)
	new_player.set_trackpath_node(map.get_node("Tracking/Trackpath"))
	map.get_node("Players").add_child(new_player)

	if id == get_tree().get_network_unique_id():
		map.get_node("cam").target = new_player.get_node("car/cam_target").get_path()
		new_player.connect("update_hud", self, "_update_hud")
		var _discart = Server.connect("game_ended", new_player, "game_ended")
		new_player.max_speed = speedometer.max_speed
		
func toggle_visibility():
	for child in get_children():
		if _game_ended and not child == speedometer and not child == place and not child == lap:
			child.visible = !child.visible
		elif _game_ended:
			speedometer.visible = false
			place.visible = false
			lap.visible = false
			boost_bar.visible = false
		elif not child == return_to_lobby:
			child.visible = !child.visible
			
		
func game_ended():
	var player_list_count = player_list.get_item_count()
	for i in player_list_count:
		var id = player_list.get_item_metadata(i)
		player_list.set_item_text(i, str(Players.get_place(id)) + ".  " + str(Players.get_nickname(id)))
	player_list.sort_items_by_text()
	
	player_list.rect_position.x = player_list.rect_position.x - (player_list.rect_size.x * 0.5) / 2
	player_list.rect_scale = Vector2(1.5, 1.5)
	player_list.visible = true
	speedometer.visible = false
	place.visible = false
	lap.visible = false
	boost_bar.visible = false
	return_to_lobby.visible = true
	_game_ended = true
	
func start_timer(seconds):
	wait_time = seconds
	timer.visible = true
	
func create_minimap(curve3d: Curve3D):
	var points3d: PoolVector3Array = curve3d.get_baked_points()
	var curve2d: Curve2D = Curve2D.new()
	var min_point: Vector2 = Vector2(10000000, 10000000)
	var max_point: Vector2 = Vector2(-10000000, -10000000)
	
	for point in points3d:
		var vec: Vector2 = Vector2(point.x, point.y)
		curve2d.add_point(vec)
		if vec.x < min_point.x: min_point.x = vec.x
		if vec.y < min_point.y: min_point.y = vec.y
		if vec.x > max_point.x: max_point.x = vec.x
		if vec.y > max_point.y: max_point.y = vec.y
	var w = max_point.x - min_point.x
	var h = max_point.y - min_point.y
	get_node("Minimap").set_curve(curve2d, w, h)

func _update_ui():
	if Players.size() > 0:
		# Handle place
		if not _game_ended:
			var player_place: int = Players.get_place()
			place.text = str(player_place) + "."
			if player_place == 1: place.add_color_override("font_color", Color.gold)
			elif player_place == 2: place.add_color_override("font_color", Color.silver)
			elif player_place == 3: place.add_color_override("font_color", Color.saddlebrown)
			else: place.add_color_override("font_color", Color.white)
	
			# Handle Lap
			lap.text = "Lap  " + str(Players.get_lap()) + " / " + str(Server.get_laps())


		# Handle PlayerList
		var player_list_count = player_list.get_item_count()
		for i in player_list_count:
			var id = player_list.get_item_metadata(i)
			
			if id == null: continue
			
			if not Players.has(id):
				player_list.remove_item(i)
				continue
				
			player_list.set_item_text(i, " " + str(Players.get_place(id)) + ".  " + str(Players.get_nickname(id)))
			if _game_ended:
				if id == Sync.me:
					player_list.set_item_custom_fg_color(i, Color("#87cef9"))
				elif Players.has_finished(id):
					player_list.set_item_custom_fg_color(i, Color.white)
				else:
					player_list.set_item_custom_fg_color(i, Color.gray.lightened(0.2))
		player_list.sort_items_by_text()

func _update_hud(speed_value, boost):
	speedometer.set_speed(speed_value)
	speedometer.set_boosting(boost.active)
	boost_bar.value = (boost.amount_left / boost.max_amount) * 100
	if boost.active:
		boost_bar.texture_progress.get_gradient().colors = boost_colors.active
		$CenterContainer/Speed_particles.emitting = true
	elif boost.recharge_cooldown:
		boost_bar.texture_progress.get_gradient().colors = boost_colors.recharge_cooldown
		
	else:
		boost_bar.texture_progress.get_gradient().colors = boost_colors.passive
		
	if speed_value < 185 and !boost.active:
		$CenterContainer/Speed_particles.emitting = false
	if speed_value > 150 and boost.active:
		$CenterContainer/Speed_particles.emitting = true
		
	boost_bar.texture_progress.get_gradient().offsets = boost_colors.offsets
	#print(str(boost.amount_left))
	

func _handle_checkpoints(_body_rid, body, _body_shape_index, _local_shape_index, cp_idx):
	var id: int = int(body.get_parent().get_parent().name)
	if (Players.is_me(id)):
		Players.past_checkpoint(cp_idx)


func _on_Return_to_Lobby_pressed():
	Server.close_client() 
