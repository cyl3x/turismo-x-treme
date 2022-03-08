extends Control

signal switch(to, from)


func _on_Back_pressed():
	emit_signal("switch", "main", "credits")
