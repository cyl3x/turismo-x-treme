extends Node

var settings
var map_name
var map
var spawn_points
var _game_ended = false
var wait_time = 0
onready var viewport = get_node("ViewportContainer/viewport")
var viewport_scale_factor = 1.0

onready var lobby = get_node("/root/Lobby")

var boost_colors = {
	"active": PoolColorArray([Color.red.lightened(0.3), Color.orange, Color.yellow]),
	"passive": PoolColorArray([Color.blue.lightened(0.5), Color.cornflower, Color.aqua]),
	"recharge_cooldown": PoolColorArray([Color.gray.darkened(0.4), Color.gray.darkened(0.2), Color.gray]),
	"offsets": PoolRealArray([0, 0.2, 1])
}

const screen_margin: float = 15.0
onready var player_list = get_node("ui_ingame/player_list")
onready var speedometer = get_node("ui_ingame/Speedometer")
onready var place = get_node("ui_ingame/place")
onready var lap = get_node("ui_ingame/lap")
onready var timer = get_node("ui_ingame/timer")
onready var return_to_lobby = get_node("ui_ingame/ReturnLobby")
onready var boost_bar = get_node("ui_ingame/BoostBar")
onready var paus_button = get_node("paus_button")
onready var fps_count = get_node("FPS")

onready var touch_controls = get_node("ui_ingame/touch_controls")

onready var minimap = get_node("ui_ingame/Minimap")

onready var speed_part = get_node("ui_ingame/Speed_particals_container/Speed_particles")
onready var speed_part_container = get_node("ui_ingame/Speed_particals_container")

onready var ui_menu = get_node("ui_menu")
onready var infos = get_node("ui_menu/infos")
onready var ui_ingame = get_node("ui_ingame")

onready var lap_times = get_node("ui_ingame/lap_times/Panel/GridContainer")

var queue = Server.get_queue()

func _ready():
	var _discart1 = Players.connect("list_updated", self, "_update_ui")
	var _discart2 = Server.connect("game_ended", self, "game_ended")
	var _discart3 = Server.connect("end_timer", self, "_end_timer")
	var _discart4 = get_viewport().connect("size_changed", self, "_root_viewport_size_changed")
	var _discart5 = Server.connect("viewport_factor_changed", self, "_root_viewport_size_changed")
	
	ui_menu.visible = false
	
	if Players.touch_controls_active():
		touch_controls.show()
	else:
		touch_controls.hide()
	
	map_name = Server.get_map()
	if Server.is_server() && !Server.IS_STANDALONE_SERVER:
		print("Game: Loading " + map_name + " map with " + str(Server.get_laps()) + " laps")
	else:
		print("Game: Loading " + map_name + " map")
	 
	map = queue.get_resource(Server.make_map_res(map_name)).instance()
	map.name = "world"
	map.pause_mode = PAUSE_MODE_STOP
	#add_child(map)
	
	viewport.get_texture().flags = Texture.FLAG_FILTER
	viewport.add_child(map)
	
	viewport.size = get_viewport().size * Server.VIEWPORT_SCALE_FACTOR
	
	if Server.IS_STANDALONE_SERVER:
		map.visible = false

	spawn_points = map.get_node("Spawns").get_children()
	
	var spawnpoint = 0
	for id in Server.player_spawn_order:
		print("Game: Spawning player " + Players.get_nickname(id) + " (" + str(id) + ")")
		spawn_player(int(id), spawnpoint)
		spawnpoint += 1
	
	map.truely_ready()
		
	map.get_node("Tracking/Checkpoint0").connect("body_entered", self, "_handle_checkpoints", [0])
	map.get_node("Tracking/Checkpoint1").connect("body_entered", self, "_handle_checkpoints", [1])
	create_minimap(map.get_node("Tracking/Trackpath").get_curve())

func _root_viewport_size_changed():
	viewport.size = get_viewport().size * Server.VIEWPORT_SCALE_FACTOR

func _process(_delta):
	
	fps_count.visible = Players.show_fps
	
	infos.text = "\n" + str(Server.SERVER_IP) + ":" + str(Server.SERVER_PORT) + "\n" + str(Players.size()) + " Spieler"
	
	if Players.touch_controls_active() and not touch_controls.visible:
		touch_controls.show()
	elif not Players.touch_controls_active() and touch_controls.visible:
		touch_controls.hide()
	
	if Players.show_fps:
		fps_count.text = ("FPS: "+ str(Engine.get_frames_per_second()))
	
	if Input.is_action_just_pressed("ui_menu"):
		toggle()

	if Input.is_action_pressed("ui_tab"):
		player_list.visible = true
		player_list.get_node("Panel/GridContainer").update()
		place.visible = false
	elif not _game_ended:
		player_list.visible = false
		place.visible = true

func toggle(force = false):
	if not force:
		ui_menu.visible = !ui_menu.visible
		ui_ingame.visible = !ui_ingame.visible
		get_tree().paused = !get_tree().paused
	else:
		ui_menu.visible = force
		ui_ingame.visible = force
		get_tree().paused = force
		
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

func spawn_player(id, spawn_point):
	var new_player = queue.get_resource(Players.get_car_res(id)).instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	
	new_player.set_position(spawn_points[spawn_point].translation,spawn_points[spawn_point].rotation)
	new_player.set_trackpath_node(map.get_node("Tracking/Trackpath"))
	map.get_node("Players").add_child(new_player)

	if id == get_tree().get_network_unique_id():
		new_player.connect("update_hud", self, "_update_hud")
		var _discart = Server.connect("game_ended", new_player, "game_ended")
		new_player.max_speed = speedometer.max_speed
		
func game_ended():
	player_list.visible = true
	speedometer.visible = false
	place.visible = false
	minimap.visible = false
	touch_controls.hide()
	lap.visible = false
	boost_bar.visible = false
	return_to_lobby.visible = true
	speed_part_container.visible = false
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
	minimap.set_curve(curve2d, w, h)

func _update_ui():
	if Players.size() > 0:
		# Handle place
		if not _game_ended:
			var player_place: int = Players.get_place()
			place.text = str(player_place)
			if player_place == 1: place.add_color_override("font_color", Color.gold)
			elif player_place == 2: place.add_color_override("font_color", Color.silver)
			elif player_place == 3: place.add_color_override("font_color", Color.saddlebrown)
			else: place.add_color_override("font_color", Color.white)
	
			# Handle Lap
			lap.text = "Runde  " + str(Players.get_lap()) + " / " + str(Server.get_laps())

func _update_hud(speed_value, boost):
	speedometer.set_speed(speed_value)
	speedometer.set_boosting(boost.active)
	boost_bar.value = (boost.amount_left / boost.max_amount) * 100
	if boost.active:
		boost_bar.texture_progress.get_gradient().colors = boost_colors.active
		speed_part.emitting = true
	elif boost.recharge_cooldown:
		boost_bar.texture_progress.get_gradient().colors = boost_colors.recharge_cooldown
		
	else:
		boost_bar.texture_progress.get_gradient().colors = boost_colors.passive
		
	if speed_value < 185 and !boost.active:
		speed_part.emitting = false
	if speed_value > 150 and boost.active:
		speed_part.emitting = true
		
	boost_bar.texture_progress.get_gradient().offsets = boost_colors.offsets
	#print(str(boost.amount_left))
	

func _handle_checkpoints(body, cp_idx):
	var id: int = int(body.get_parent().get_parent().name)
	if (Players.is_me(id)):
		Players.past_checkpoint(cp_idx)


func _on_Return_to_Lobby_pressed():
	Server.close_client() 

func _on_paus_button_pressed():
	Input.action_press("ui_menu")

func _on_resumeBtn_pressed():
	toggle()

func _on_settingsBtn_pressed():
	lobby.show_settings()

func _on_leaveBtn_pressed():
	Server.close_client()
	
func _notification(what):
	if not OS.get_name() in [ "Android", "iOS" ]: return
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		pass
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		toggle()
