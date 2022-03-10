extends Node

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

const file_name = "history.db"

var history = SQLite.new()

var current_run_id = -1

var hist_remote = false
var api_key = null
var headers = null
var requester

const runs_table_dict = {
	"id": {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
	"name": {"data_type":"char(50)", "not_null": true},
	"map": {"data_type":"char(50)", "not_null": true},
	"laps": {"data_type":"int", "not_null": true},
	"player_count": {"data_type":"int", "not_null": true},
	"start_counter": {"data_type":"boolean", "not_null": true},
	"start_date": {"data_type":"int", "not_null": true},
	"end_date": {"data_type":"int", "not_null": false},
	"selfhost": {"data_type":"boolean", "not_null": true},
}

const players_table_dict = {
	"id": {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
	"run_id": {"data_type":"int", "foreign_key": "runs.id", "not_null": true},
	"net_id": {"data_type":"int", "not_null": true},
	"nickname": {"data_type":"char(50)", "not_null": true},
	"car_name": {"data_type":"char(50)", "not_null": true},
	"place": {"data_type":"int", "not_null": true},
	"best_lap_millis": {"data_type":"int", "not_null": false},
	"total_lap_millis": {"data_type":"int", "not_null": false},
	"left_before_end": {"data_type":"boolean", "not_null": true},
	"is_me": {"data_type":"boolean", "not_null": true},
}

func _ready():
	var _discart1 = self.connect("tree_exiting", self, "close_db")
	var _discart2 = Server.connect("game_reset", self, "_reset")
	var _discart3 = Server.connect("run_name_changed", self, "_reset_run_name")
	
	history.path = "user://" + file_name
	history.foreign_keys = true
	history.open_db()
	history.create_table("runs", runs_table_dict)
	history.create_table("players", players_table_dict)
	history.close_db()
		
	requester = preload("res://server/request_queue.gd").new()

func start_new_game(run_name, map_name, laps, start_counter_active, player_count, selfhost):
	history.open_db()
	if current_run_id > -1:
		print("ERROR: History: A Game is already running?")
		return
	
	var data = {
		"name": run_name,
		"map": map_name,
		"laps": laps,
		"player_count": player_count,
		"start_counter": start_counter_active,
		"start_date": OS.get_unix_time(),
		"selfhost": selfhost,
	}
	
	history.insert_row("runs", data)
	
	if hist_remote:
		_new_game_request(data)
	
	history.query("SELECT seq FROM sqlite_sequence where name='runs';")
	current_run_id = history.query_result[0].seq
	
	for id in Players.keys():
		history.insert_row("players", {
			"run_id": current_run_id,
			"net_id": id,
			"nickname": Players.get_nickname(id),
			"car_name": Players.get_car_name(id),
			"place": 99,
			"left_before_end": false,
			"is_me": Players.is_me(id),
		})
		
		if hist_remote:
			_new_player_request({
				"run_id": current_run_id,
				"net_id": id,
				"nickname": Players.get_nickname(id),
				"car_name": Players.get_car_name(id),
			})

func _reset_run_name(run_name):
	if current_run_id > 0:
		history.query_with_bindings("UPDATE runs SET name=? WHERE id=?", [run_name, current_run_id])

func close_db():
	history.close_db()

func _reset():
	current_run_id = -1
	history.close_db()


###########################
#       Getters/Setters

func get_runs(count = 100):
	history.open_db()
	history.query("SELECT id, name, map, laps, player_count, start_date, selfhost FROM runs ORDER BY id DESC LIMIT " + str(count))
	history.close_db()
	return history.query_result

func get_players(run_id : int):
	history.open_db()
	history.query("SELECT nickname, car_name, place, best_lap_millis, total_lap_millis, left_before_end, is_me FROM players WHERE run_id='" + str(run_id) + "' ORDER BY place")
	history.close_db()
	return history.query_result
	
func get_left_status(id : int):
	history.open_db()
	history.query_with_bindings("SELECT left_before_end FROM players WHERE run_id=? AND net_id=?", [current_run_id, id])
	history.close_db()
	return bool(history.query_result)

## runs
#func update_player_count(player_count : int):
#	history.query_with_bindings("UPDATE runs SET player_count=? WHERE id=?", [player_count, current_run_id])

#func update_run_name(run_name : String):
#	history.query_with_bindings("UPDATE runs SET name=? WHERE id=?", [run_name, current_run_id])
	
#func update_map(map : String):
#	history.query_with_bindings("UPDATE runs SET map=? WHERE id=?", [map, current_run_id])
	
#func update_laps(laps : int):
#	history.query_with_bindings("UPDATE runs SET laps=? WHERE id=?", [laps, current_run_id])
	
#func update_start_counter(start_counter : bool):
#	history.query_with_bindings("UPDATE runs SET start_counter=? WHERE id=?", [start_counter, current_run_id])

## players
#func update_car_name(id : int, car_name : String):
#	history.query_with_bindings("UPDATE players SET car_name=? WHERE run_id=? AND net_id=?", [car_name, current_run_id, id])
	
func update_place(id : int, place : int):
	history.query_with_bindings("UPDATE players SET place=? WHERE run_id=? AND net_id=?", [place, current_run_id, id])
	#if hist_remote:
		#_update_request(id, "place", { "place": place })
	
func update_best_lap_millis(id : int, best_lap_millis : int):
	history.query_with_bindings("UPDATE players SET best_lap_millis=? WHERE run_id=? AND net_id=?", [best_lap_millis, current_run_id, id])
	if hist_remote:
		_update_request(id, "best_lap_millis", { "best_lap_millis": best_lap_millis })
	
func update_total_lap_millis(id : int, total_lap_millis : int):
	history.query_with_bindings("UPDATE players SET total_lap_millis=? WHERE run_id=? AND net_id=?", [total_lap_millis, current_run_id, id])
	if hist_remote:
		_update_request(id, "total_lap_millis", { "total_lap_millis": total_lap_millis })

func update_left_status(id : int, mark : bool):
	history.query_with_bindings("UPDATE players SET left_before_end=? WHERE run_id=? AND net_id=?", [mark, current_run_id, id])
	update_place(id, 99)
	if hist_remote:
		_update_request(id, "left_before_end", { "left_before_end": mark })

## Remote

func _update_request(id : int, type : String, data):
	var query = JSON.print(data)
	requester.request(HTTPClient.METHOD_PUT, "/api/update/player/" + str(id) + "/" + type, headers, query)

func _new_game_request(data):
	var query = JSON.print(data)
	requester.request(HTTPClient.METHOD_POST, "/api/new/run", headers, query)
	
func _new_player_request(data):
	var query = JSON.print(data)
	requester.request(HTTPClient.METHOD_POST, "/api/new/player", headers, query)

## Other

func checkCMDArgs(args):
	var key = ProjectSettings.get_setting("global/api_key")
	if args.has("tunier") and not key in [ "", "null", "Null" ] and key.length() >= 10:
		api_key = key
		hist_remote = true
		headers = [
			"Content-Type: application/json",
			"Authorization: Bearer " + api_key
		]
		requester.start()
		print("!!! Tunier Modus !!!")
