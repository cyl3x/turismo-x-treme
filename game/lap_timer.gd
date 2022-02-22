extends GridContainer

var start_time = 0
var last_time = 0
var last_lap = 0

var lap_labels = []
var time_labels = []

var best_time = 0
var game_ended = false

var font = DynamicFont.new()

func _ready():
	font.font_data = load("res://themes/Montserrat-Medium.otf")
	font.size = 14

func _process(_delta):
	if get_tree().paused:
		start_time += int(_delta * 1000)
		return
	
	if Sync.optimistic_lap != last_lap:
		if time_labels.size() >= 1:
			if Sync.optimistic_lap > Server.settings.laps: game_ended = true
			var new_time = last_time
			if best_time > new_time or best_time == 0:
				best_time = new_time
			rpc("_recv_best_times", Sync.me, _format_millis(best_time))
			
		if game_ended: return
			
		last_lap = Sync.optimistic_lap
		start_time = OS.get_ticks_msec()
		
		var time_label = Label.new()
		time_label.text = "00:00.000"
		time_label.align = Label.ALIGN_RIGHT
		time_label.size_flags_horizontal = SIZE_EXPAND_FILL
		time_label.add_font_override("font", font)
		add_child(time_label)
		move_child(time_label, 0)
		time_labels.append(time_label)
		
		var lap_label = Label.new()
		lap_label.text = "Runde " +  str(last_lap) + ":"
		lap_label.add_font_override("font", font)
		add_child(lap_label)
		move_child(lap_label, 0)
		lap_labels.append(lap_label)
		
		if time_labels.size() <= 3 and time_labels.size() != 1:
			get_parent().rect_size.y += time_label.rect_size.y + 4
		
	if Sync.optimistic_lap == last_lap and time_labels.size() > 0:
		last_time = OS.get_ticks_msec() - start_time
		time_labels[last_lap - 1].set_text(_format_millis(last_time))

func _format_millis(total_millis) -> String:
	var millis = (total_millis) % 1000
	var seconds = (total_millis / 1000) % 60
	var minutes = (total_millis / (1000 * 60)) % 60
	return "%02d:%02d.%03d" % [int(minutes), int(seconds), int(millis)]
	
remotesync func _recv_best_times(id, time_string):
	Players.best_times[id] = time_string
