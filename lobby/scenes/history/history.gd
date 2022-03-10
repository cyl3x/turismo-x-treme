extends VBoxContainer

onready var body = $scroller/body

var mode = 0 # 0 - local, 1 - global

var player_nodes = []
var run_nodes = []

signal switch(to, from)

func init():
	if run_nodes.size() > 0:
		for run in run_nodes:
			body.remove_child(run)
		run_nodes.clear()
	_build_runs()

func _build_runs():
	var runs = History.get_runs()
	for run in runs:
		var temp = load("res://lobby/scenes/history/run_item.tscn").instance()
		body.add_child(temp)
		temp.init(run.id, run.name, run.map, run.laps, run.player_count, run.start_date, run.selfhost)
		temp.connect("pressed", self, "_on_run_pressed")
		run_nodes.append(temp)

func _build_players(run_id):
	var players = History.get_players(run_id)
	
	for player in players:
		var temp = load("res://lobby/scenes/history/player_item.tscn").instance()
		body.add_child(temp)
		temp.init(player.nickname, player.car_name, player.place, player.best_lap_millis, player.total_lap_millis, player.left_before_end, player.is_me)
		player_nodes.append(temp)

func is_local():
	return mode == 0
	
func is_global():
	return mode == 1

func _on_run_pressed(id):
	for run in run_nodes:
		body.remove_child(run)
	_build_players(id)

func _on_Back_pressed():
	if player_nodes.size() > 0:
		for player in player_nodes:
			body.remove_child(player)
		for run in run_nodes:
			body.add_child(run)
		player_nodes.clear()
	else:
		emit_signal("switch", "main", "history")


func _on_tunier_pressed():
	OS.shell_open("https://tunier.cyl3x.de")


func _on_history_pressed():
	mode = 0

func _on_maps_pressed():
	mode = 1
