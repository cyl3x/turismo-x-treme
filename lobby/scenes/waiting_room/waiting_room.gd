extends Control

signal switch(to)

func _on_start_pressed():
	Server.server_startGame()
	visible = false


func _on_return_pressed():
	if Server.is_server():
		Server.close_server()
	else:
		Server.close_client()
