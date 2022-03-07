extends Control

var args = {}

onready var lobbymap = $ViewportContainer/Viewport/Lobbymap
onready var viewport = $ViewportContainer/Viewport
onready var viewport_container = $ViewportContainer

onready var main = $main
onready var waiting_room = $waiting_room
onready var car_selector = $car_selector
onready var credits = $credits

onready var loading_screen = $Loading_screen
onready var loading_screen_ani = $Loading_screen/Spinner/SpinAni
onready var loading_screen_spinner = $Loading_screen/Spinner
onready var loading_screen_label = $Loading_screen/process

onready var lobbyPlayer1 = $music1
onready var lobbyPlayer2 = $music2
const lobby_switch_time = 60 # 60sek
var lobby_switch_timer = lobby_switch_time

var transition = {
	"duration": 300,
	"scene_from": null,
	"scene_to": null,
	"effect": ""
}

func _ready():
	var _discart1 = Server.connect("server_started", self, "_server_started")
	var _discart2 = Server.connect("connection_failed", self, "_connection_failed")
	var _discart3 = Server.connect("connection_pending", self, "_connection_pending")
	var _discart4 = Server.connect("connection_succeeded", self, "_connection_succeeded")
	var _discart5 = Server.connect("game_reset", self, "_reset")
	var _discart6 = Server.connect("game_started", self, "_game_started")
	var _discart7 = get_viewport().connect("size_changed", self, "_root_viewport_size_changed")
	var _discart8 = Server.connect("viewport_factor_changed", self, "_root_viewport_size_changed")
	
	var _discart9 = main.connect("switch", self, "_switch")
	var _discart10 = waiting_room.connect("switch", self, "_switch")
	var _discart11 = car_selector.connect("switch", self, "_switch")
	var _discart12 = credits.connect("switch", self, "_switch")
	
	#$HBox/VBoxContainer.rect_size = Vector2($HBox/VBoxContainer.rect_size.x ,512)
	
	lobbyPlayer1.play()
	lobbyPlayer2.stop()
	
	viewport.get_texture().flags = Texture.FLAG_FILTER
	viewport.size = get_viewport().size * Server.VIEWPORT_SCALE_FACTOR

	parseCMDArgs()
	Server.checkCMDArgs(args)
	Sync.checkCMDArgs(args)
	
	main.visible = true
	
func _process(delta):
	if Server.game_pre_configuring:
		process_loading(Server.pre_configure_game_finish())
	
	if not Server._game_running:
		switch_lobby_music(delta)
	else:
		lobbyPlayer1.stop()
		lobbyPlayer2.stop()
		
func switch_lobby_music(delta):
	lobby_switch_timer -= delta
	if lobby_switch_timer <= 0:
		lobby_switch_timer += lobby_switch_time
			
		var temp = lobbyPlayer1.playing
		lobbyPlayer1.playing = lobbyPlayer2.playing
		lobbyPlayer2.playing = temp
			
		lobbyPlayer1.volume_db = 0
		lobbyPlayer2.volume_db = 0

func _root_viewport_size_changed():
	viewport.size = get_viewport().size * Server.VIEWPORT_SCALE_FACTOR
	if Server.VIEWPORT_SCALE_FACTOR == 1:
		viewport.sharpen_intensity = 0
	else:
		viewport.sharpen_intensity = 0.5

func toggle_menu():
	self.visible = !self.visible

###############################
#       Signal Functions

func _reset():
	main.visible = true
	car_selector.visible = false
	waiting_room.visible = false
	credits.visible = false
	self.visible = true

func _game_started():
	main.visible = false
	car_selector.visible = false
	waiting_room.visible = false
	credits.visible = false
	self.visible = false

func _server_started():
	main.visible = false
	car_selector.visible = false
	waiting_room.visible = true
	credits.visible = false
	self.visible = true

func _connection_failed():
	_reset()
	
func _connection_pending():
	main.visible = false
	car_selector.visible = false
	waiting_room.visible = true
	credits.visible = false
	self.visible = true

func _connection_succeeded():
	main.visible = false
	car_selector.visible = false
	waiting_room.visible = true
	credits.visible = false
	self.visible = true
	
func show_settings():
	$main/Settings.show()

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

func _switch(to):
	if to == "car_selector":
		main.visible = false
		car_selector.visible = true
		waiting_room.visible = false
		credits.visible = false
	elif to == "main":
		main.visible = true
		car_selector.visible = false
		waiting_room.visible = false
		credits.visible = false
	elif to == "credits":
		main.visible = false
		car_selector.visible = false
		waiting_room.visible = false
		credits.visible = true

func _process_transition(delta):
	if transition.scene_from != null and transition.scene_to != null and transition.effect != "":
		if transition.duration <= 0: 
			transition.scene_from = null
			transition.scene_to = null
			return
			
		if transition.effect == "right-left":
			if transition.init:
				transition.length = get_viewport().size.x
				transition.scene_to.margin.left = transition.length
			transition.duration -= delta
			transition.scene_to
			

func _set_transition(duration : float, from : Node, to : Node, effect : String):
	transition = {
		"duration": duration,
		"init": true,
		"length": 0,
		"scene_from": from,
		"scene_to": to,
		"effect": effect
	}
