extends VBoxContainer

signal update_request()

onready var joinBtn = $joinBtn
onready var hostBtn = $hostBtn
onready var leaveBtn = $leaveBtn

func _ready():
	var _discart1 = Server.connect("server_started", self, "_server_started")
	var _discart2 = Server.connect("connection_failed", self, "_connection_failed")
	var _discart3 = Server.connect("connection_pending", self, "_connection_pending")
	var _discart4 = Server.connect("connection_succeeded", self, "_connection_succeeded")
	var _discart5 = Server.connect("game_reset", self, "_reset")
	var _discart6 = Server.connect("game_started", self, "_game_started")

func _on_hostBtn_pressed():
	Server.host_server(Server.get_hostname().split(":")[1])

func _on_JoinBtn_pressed():
	var split = Server.get_hostname().split(":")
	Server.connect_to_server(split[0], split[1])

func _on_leaveBtn_pressed():
	Server.close_client()

func _on_settingsBtn_pressed():
	get_node("../../Settings").show()

func _on_updateBtn_pressed():
	emit_signal("update_request")
	
	###############################
#       Signal Functions

func _reset():
	joinBtn.disabled = false
	hostBtn.disabled = false
	leaveBtn.disabled = false
	leaveBtn.text = "Spiel verlassen"

func _game_started():
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false

func _server_started():
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	leaveBtn.text = "Server schließen"

func _connection_failed():
	_reset()
	
func _connection_pending():
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	leaveBtn.text = "Verbinden stoppen"
	

func _connection_succeeded():
	joinBtn.disabled = true
	hostBtn.disabled = true
	leaveBtn.disabled = false
	leaveBtn.text = "Server verlassen"
