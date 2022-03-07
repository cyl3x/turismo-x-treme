extends GridContainer

var players = {}
var game_ended = false

func _ready():
	var _discard1 = Players.connect("list_pos_updated", self, "update")
	var _discard2 = Players.connect("best_times_updated", self, "update")
	var _discard3 = Server.connect("game_ended", self, "update")
	var _discard4 = Server.connect("game_ended", self, "_game_ended")
	
	for id in Players.keys():
		_create_player(id)

func update():
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
			
		var place = Players.get_place(id)
		players[id].place.text = str(place) + "."
		
		if Players.best_times.has(id):
			players[id].best_time.text = str(Players.best_times[id])
			
		if game_ended and id != Sync.me:
			if Players.has_finished(id):
				_override_color(id, Color.white)
			else:
				_override_color(id, Color.gray.lightened(0.2))
			
		move_child(players[id].best_time, (place - 1) * 3)
		move_child(players[id].name, (place - 1) * 3)
		move_child(players[id].place, (place - 1) * 3)

func _create_player(id):
	players[id] = {
		"place": null,
		"name": null,
		"best_time": null
	}
	players[id].place = Label.new()
	players[id].place.text = str(Players.get_place(id)) + "."
	add_child(players[id].place)
	
	players[id].name = Label.new()
	players[id].name.text = str(Players.get_nickname(id))
	add_child(players[id].name)
	
	players[id].best_time = Label.new()
	players[id].best_time.align = Label.ALIGN_RIGHT
	players[id].best_time.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(players[id].best_time)
	
	if Players.best_times.has(id):
		players[id].best_time.text = str(Players.best_times[id])
		
	if id == Sync.me:
		_override_color(Sync.me, Color("#87cef9"))
		
func _override_color(id : int, color : Color):
		players[id].place.add_color_override("font_color", color)
		players[id].name.add_color_override("font_color", color)
		players[id].best_time.add_color_override("font_color", color)
		
func _game_ended():
	get_parent().rect_scale = Vector2(1.4, 1.4)
	game_ended = true

func _on_start_pressed():
	Server.server_startGame()
