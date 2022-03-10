extends Control

onready var counter = $counter
var start_counter = false
var timer = 0
var last_timer = 0

func _ready():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("fx"), true)
	if Server.is_admin():
		var _discard1 = Server.connect("game_started", self, "_start_counter")
		timer = 6

func _process(delta):
	if start_counter:
		timer -= delta
		if int(timer) != last_timer:
			last_timer = int(timer)
			rpc("_recv_timer_from_server", last_timer)

func _start_counter():
	if Server.get_start_timer_active():
		start_counter = true
		timer = 6
	else:
		rpc("_recv_timer_from_server", 0)
	
remotesync func _recv_timer_from_server(new_timer):
	counter.text = str(new_timer)
	
	if new_timer <= 0:
		get_tree().paused = false
		counter.visible = false
		if Server.is_server():
			start_counter = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("fx"), false)
		
	if new_timer == 1: counter.add_color_override("font_color", Color.gold)
	elif new_timer == 2: counter.add_color_override("font_color", Color.silver)
	elif new_timer == 3: counter.add_color_override("font_color", Color.saddlebrown)
	else: counter.add_color_override("font_color", Color.white)
	
	Players.start_time_update(new_timer)
		
