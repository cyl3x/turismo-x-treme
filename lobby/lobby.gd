extends Control

# Never change that
var version_from = "1645294429"

var url_encoded = null

var args = {}
var hostname = "godot.cyl3x.de:25600"
#var hostname = "localhost:25600"
var regex = RegEx.new()

var car_selected = 0
var cars_amount = 0
var cars = {}

onready var menuBild = $ViewportContainer/Viewport/Lobbymap
onready var viewport = $ViewportContainer/Viewport
onready var viewport_container = $ViewportContainer
onready var joinBtn = $HBox/main/joinBtn
onready var hostBtn = $HBox/main/hostBtn
onready var startBtn = $HBox/main/startBtn
onready var leaveBtn = $HBox/main/leaveBtn
onready var settingsBox = $HBox/main/settingsBox

onready var adminPanel = $AdminPanel
onready var server = $HBox/Server
onready var playerSettings = $HBox/VBoxContainer/PlayerSettings

onready var settingsPanel = $Settings

onready var car_selection = $HBox/VBoxContainer/CarSelect
onready var car_left = playerSettings.get_node("CarSelectLeft")
onready var car_right = playerSettings.get_node("CarSelectRight")
onready var car_name = playerSettings.get_node("CarName")

onready var loading_screen = $Loading_screen
onready var loading_screen_ani = $Loading_screen/Spinner/SpinAni
onready var loading_screen_spinner = $Loading_screen/Spinner
onready var loading_screen_label = $Loading_screen/process

onready var ext_ip = $AdminPanel/ips/ext_ip
onready var int_ip = $AdminPanel/ips/int_ip

func _ready():
	regex.compile("(([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})|(\\w*.\\w*.\\w*)):[0-9]{3,5}")
	var _discart1 = Server.connect("server_started", self, "_server_started")
	var _discart2 = Server.connect("connection_failed", self, "_connection_failed")
	var _discart3 = Server.connect("connection_pending", self, "_connection_pending")
	var _discart4 = Server.connect("connection_succeeded", self, "_connection_succeeded")
	var _discart5 = Server.connect("game_reset", self, "_reset")
	var _discart6 = Server.connect("game_started", self, "_game_started")
	var _discart7 = get_viewport().connect("size_changed", self, "_root_viewport_size_changed")
	var _discart8 = Server.connect("viewport_factor_changed", self, "_root_viewport_size_changed")
	
	$HBox/VBoxContainer.rect_size = Vector2($HBox/VBoxContainer.rect_size.x ,512)
	
	viewport.get_texture().flags = Texture.FLAG_FILTER
	viewport.size = get_viewport().size * Server.VIEWPORT_SCALE_FACTOR
	
	$HTTPRequest.request("https://api64.ipify.org")
	
	if ProjectSettings.get_setting("global/build_date") != "null":
		url_encoded = "\"Project\" is \"cyl3x/godot-racing-game\" and successful and \"Finish Date\" is since \"" + ProjectSettings.get_setting("global/build_date") + "\"".percent_encode()
	else:
		settingsBox.remove_child(settingsBox.get_node("updateBtn"))

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

func _root_viewport_size_changed():
	viewport.size = get_viewport().size * Server.VIEWPORT_SCALE_FACTOR
	if Server.VIEWPORT_SCALE_FACTOR == 1:
		viewport.sharpen_intensity = 0
	else:
		viewport.sharpen_intensity = 0.5

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

func _on_update_pressed():
	if url_encoded:
		$Update.request("https://git.cyl3x.de/api/builds?count=1&offset=0&query=" + url_encoded)

###############################
#       Signal Functions

func _reset():
	loading_screen.visible = false
	server.stop_spin()
	joinBtn.disabled = false
	hostBtn.disabled = false
	leaveBtn.disabled = false
	startBtn.disabled = true
	car_left.visible = true
	car_right.visible= true
	server.get_node("Hostname").editable = true
	server.get_node("Nickname").editable = true
	car_selection.disabled = false
	adminPanel.visible = false
	self.visible = true
	car_changed()
	leaveBtn.text = "Spiel verlassen"

func _game_started():
	server.stop_spin()
	loading_screen.visible = false
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	startBtn.disabled = true
	car_left.visible = false
	car_right.visible= false
	server.get_node("Hostname").editable = false
	server.get_node("Nickname").editable = false
	car_selection.disabled = true
	adminPanel.visible = false
	leaveBtn.text = "Zur Lobby"
	self.visible = false

func _server_started():
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	startBtn.disabled = false
	server.get_node("Hostname").editable = false
	server.get_node("Nickname").editable = false
	car_selection.disabled = false
	adminPanel.visible = true
	leaveBtn.text = "Server schließen"

func _connection_failed():
	_reset()
	
func _connection_pending():
	server.spin()
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	startBtn.disabled = true
	server.get_node("Hostname").editable = false
	server.get_node("Nickname").editable = false
	car_selection.disabled = true
	adminPanel.visible = false
	leaveBtn.text = "Verbinden stoppen"
	

func _connection_succeeded():
	server.stop_spin()
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	startBtn.disabled = true
	server.get_node("Hostname").editable = false
	server.get_node("Nickname").editable = false
	car_selection.disabled = false
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

func process_loading(process):
	if process > -1 and 0 < process and not loading_screen_ani.is_playing(): loading_screen_ani.play("spin")
	elif process == -1 and loading_screen_ani.is_playing(): loading_screen_ani.stop()
	
	if process <= -1:
		loading_screen_spinner.visible = false
		loading_screen_label.text = "Auf andere Spieler warten ..."
	elif process > -1:
		loading_screen.visible = true
		loading_screen_label.text = str(int(process * 100)) + "%"
		loading_screen_spinner.visible = true

func car_changed():
	Players.set_car(cars[car_selected])
	car_name.text = str(cars[car_selected])
	menuBild.car_changed(cars[car_selected])
	
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


func _on_update_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		if not json.error:
			var _discard = OS.shell_open("https://git.cyl3x.de/projects/" + str(json.result[0].projectId) + "/builds/" + str(json.result[0].number) + "/artifacts")
