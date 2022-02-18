extends Control

var args = {}
#var hostname = "godot.cyl3x.de:25600"
var hostname = "localhost:25600"
var regex = RegEx.new()

var car_selected = 0
var cars_amount = 0
var cars = {}

onready var menuBild = $Lobbymap
onready var joinBtn = $main/joinBtn
onready var hostBtn = $main/hostBtn
onready var startBtn = $main/start/startBtn
onready var leaveBtn = $main/leaveBtn

onready var adminPanel = $AdminPanel
onready var server = $Server
onready var playerSettings = $PlayerSettings

onready var settingsPanel = $Settings

onready var car_selection = $PlayerSettings/CarSelection
onready var car_left = $PlayerSettings/CarSelectLeft
onready var car_right = $PlayerSettings/CarSelectRight
onready var car_name = $PlayerSettings/CarName

onready var loading_screen = $Loading_screen
onready var loading_screen_ani = $Loading_screen/Spinner/SpinAni
onready var loading_screen_label = $Loading_screen/process

onready var ext_ip = $AdminPanel/ips/ext_ip
onready var int_ip = $AdminPanel/ips/int_ip

func _ready():
	# Jitter fix
	Engine.target_fps = 60
	
	regex.compile("(([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})|(\\w*.\\w*.\\w*)):[0-9]{3,5}")
	var _discart1 = Server.connect("server_started", self, "_server_started")
	var _discart2 = Server.connect("connection_failed", self, "_connection_failed")
	var _discart3 = Server.connect("connection_pending", self, "_connection_pending")
	var _discart4 = Server.connect("connection_succeeded", self, "_connection_succeeded")
	var _discart5 = Server.connect("game_reset", self, "_reset")
	var _discart6 = Server.connect("game_started", self, "_game_started")
	
	$HTTPRequest.request("https://api64.ipify.org")

	parseCMDArgs()
	Server.checkCMDArgs(args)
	Sync.checkCMDArgs(args)
	
	## Init Lobby
	adminPanel.visible = false
	server.get_node("Hostname").text = hostname
	server.get_node("Nickname").text = Players.get_nickname()
	
	int_ip.text = Server.internal_ip()
	
	## Init cars
	cars = get_cars()
	for car in cars:
		car_selection.add_item(car)
		if car == Players.default_car:
			car_selection.select(cars.find(car, 0))
	cars_amount = cars.size()
	car_changed()
	
func _process(_delta):
	if Server.game_pre_configuring:
		process_loading(Server.pre_configure_game_finish())

func toggle_menu():
	self.visible = !self.visible

func _on_JoinBtn_pressed():
	var split = hostname.split(":")
	Server.connect_to_server(split[0], split[1])

func _on_hostBtn_pressed():
	Server.host_server(hostname.split(":")[1])

func _on_leaveBtn_pressed():
	Server.close_client()

func _on_startBtn_pressed():
	Server.server_startGame()
	
func enable_admin(enable):
	startBtn.disabled = !enable
	adminPanel.visible = true
	adminPanel.refresh()

func hide_buttons(invisib):
	hostBtn.visible = invisib
	joinBtn.visible = invisib
	adminPanel.visible = invisib

func visible_lobby(visib):
	visible = visib
	
func _on_hostname_changed(text):
	if regex.search(text):
		hostname = text
		server.get_node("Hostname").add_color_override("font_color", Color(0,0,0,1))
	else:
		server.get_node("Hostname").add_color_override("font_color", Color(1,0,0,1))

func _on_car_selected(index):
	var car = car_selection.get_item_text(index)
	Players.set_car(car)


func _on_nickname_changed(nickname : String):
	if nickname.length() >= 3:
		Players.set_nickname(nickname)
		server.get_node("Nickname").add_color_override("font_color", Color(0,0,0,1))
	else:
		server.get_node("Nickname").add_color_override("font_color", Color(1,0,0,1))

###############################
#       Signal Functions

func _reset():
	server.stop_spin()
	load_lobbymap()
	joinBtn.disabled = false
	hostBtn.disabled = false
	leaveBtn.disabled = false
	startBtn.disabled = true
	car_left.visible = true
	car_right.visible= true
	server.get_node("Hostname").editable = true
	server.get_node("Nickname").editable = true
	playerSettings.get_node("CarSelection").disabled = false
	adminPanel.visible = false
	self.visible = true
	car_changed()
	leaveBtn.text = "Spiel verlassen"

func _game_started():
	server.stop_spin()
	remove_lobbymap()
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	startBtn.disabled = true
	car_left.visible = false
	car_right.visible= false
	server.get_node("Hostname").editable = false
	server.get_node("Nickname").editable = false
	playerSettings.get_node("CarSelection").disabled = true
	adminPanel.visible = false
	leaveBtn.text = "Zur Lobby"
	self.visible = false

func _server_started():
	load_lobbymap()
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	startBtn.disabled = false
	server.get_node("Hostname").editable = false
	server.get_node("Nickname").editable = false
	playerSettings.get_node("CarSelection").disabled = false
	adminPanel.visible = false
	leaveBtn.text = "Server schließen"

func _connection_failed():
	_reset()
	
func _connection_pending():
	server.spin()
	load_lobbymap()
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	startBtn.disabled = true
	server.get_node("Hostname").editable = false
	server.get_node("Nickname").editable = false
	playerSettings.get_node("CarSelection").disabled = true
	adminPanel.visible = false
	leaveBtn.text = "Verbinden stoppen"
	

func _connection_succeeded():
	server.stop_spin()
	load_lobbymap()
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	startBtn.disabled = true
	server.get_node("Hostname").editable = false
	server.get_node("Nickname").editable = false
	playerSettings.get_node("CarSelection").disabled = false
	adminPanel.visible = false
	leaveBtn.text = "Server verlassen"

	
func get_cars():
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

func parseCMDArgs():
	for argument in OS.get_cmdline_args():
		if argument.find("--") > -1:
			var key_value = argument.lstrip("--")
			if key_value.find("=") > -1:
				key_value = key_value.split("=")
				args[key_value[0]] = key_value[1]
			else:
				args[key_value] = true

func load_lobbymap():
	if not has_node("Lobbymap"):
		var temp = load("res://lobby/Lobbymap.tscn").instance()
		add_child(temp)
		menuBild = temp

func process_loading(process):
	loading_screen.visible = process > -1
	loading_screen_label.text = str(int(process * 100)) + "%"
	if process > -1 and 0 < process and not loading_screen_ani.is_playing(): loading_screen_ani.play("spin")
	elif process == -1 and loading_screen_ani.is_playing(): loading_screen_ani.stop()

func remove_lobbymap():
	menuBild.queue_free()

func car_changed():
	Players.set_car(cars[car_selected])
	car_name.text = str(cars[car_selected])
	$Lobbymap.car_changed(cars[car_selected])
	
func _on_CarSelectLeft_pressed():
	if car_selected-1 >= 0:
		car_selected -=1
	else:
		car_selected = cars_amount-1
	car_changed()
	

func _on_CarSelectRight_pressed():
	if car_selected + 1 <= cars_amount - 1:
		car_selected += 1 
	else:
		car_selected = 0
	car_changed()

func _on_settingsBtn_pressed():
	settingsPanel.show()


func _on_external_ip_resolved(_result, _response_code, _headers, body):
	ext_ip.text = body.get_string_from_utf8()
