extends VBoxContainer

var regex = RegEx.new()

onready var hostname = $Hostname
onready var nickname = $Nickname

func _ready():
	regex.compile("(([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})|(\\w*.\\w*.\\w*)):[0-9]{3,5}")
	hostname.text = Server.get_hostname()
	nickname.text = Players.get_nickname()
	
	if Config.has_server_setting("hostname"):
		_on_Hostname_text_changed(Config.get_server_setting("hostname"))
	
	var _discart1 = Server.connect("connection_failed", self, "_reset")
	var _discart2 = Server.connect("connection_succeeded", self, "_connection_succeeded")
	var _discart3 = Server.connect("connection_pending", self, "_connection_succeeded")
	var _discart4 = Server.connect("game_reset", self, "_reset")

func _on_nickname_changed(text : String):
	if text.length() >= 3:
		Players.set_nickname(text)
		nickname.add_color_override("font_color", Color(0,0,0,1))
	else:
		nickname.add_color_override("font_color", Color(1,0,0,1))


func _on_Hostname_text_changed(text : String):
	if regex.search(text):
		Server.set_hostname(text)
		hostname.add_color_override("font_color", Color(0,0,0,1))
	else:
		hostname.add_color_override("font_color", Color(1,0,0,1))

func _reset():
	hostname.editable = true
	nickname.editable = true
	
func _connection_succeeded():
	hostname.editable = false
	nickname.editable = false
