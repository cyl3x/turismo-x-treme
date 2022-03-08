extends Control

signal switch(to, from)

func _on_start_pressed():
	Server.server_startGame()
	rpc("_hide")

remotesync func _hide():
	self.visible = false

func _on_return_pressed():
	if Server.is_server():
		Server.close_server()
	else:
		Server.close_client()

func _on_car_selector_pressed():
	emit_signal("switch", "car_selector", "waiting_room")
