extends GridContainer

var players = {}

onready var startBtn = get_node("../../buttons/start")

func _ready():
	var _discart1 = Players.connect("list_data_updated", self, "refresh_players")
	var _discart2 = Server.connect("connection_failed", self, "_reset")
	var _discart3 = Server.connect("game_reset", self, "_reset")
	var _discart4 = Server.connect("game_started", self, "_reset")
	var _discart5 = Server.connect("admin_changed", self, "_admin_changed")
	
	for id in Players.keys():
		_create_player(id)

func refresh_players():
	if not get_parent().get_parent().visible: return
	
	for id in Players.keys():
		if not players.has(id):
			_create_player(id)
			
		if not Players.has(id):
			remove_child(players[id].best_time)
			remove_child(players[id].name)
			remove_child(players[id].place)
			players.erase(id)
			continue
			
		startBtn.visible = Server.is_admin()

func _create_player(id):
	players[id] = {
		"name": null
	}
	
	players[id].name = Label.new()
	players[id].name.text = str(Players.get_nickname(id))
	add_child(players[id].name)
		
	if id == Sync.me:
		_override_color(Sync.me, Color("#87cef9"))
	else:
		_override_color(id, Color(Players.get_color(id)))
		
func _admin_changed():
	if Server.is_admin():
		startBtn.visible = true
		
func _override_color(id : int, color : Color):
	players[id].name.add_color_override("font_color", color)

func _reset():
	for id in players:
		remove_child(players[id].name)
	players = {}
