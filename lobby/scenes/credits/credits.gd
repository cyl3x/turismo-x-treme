extends Control

signal switch(to)


func _on_Back_pressed():
	emit_signal("switch", "main")
