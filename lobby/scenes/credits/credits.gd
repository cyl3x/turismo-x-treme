extends Control

signal switch(to, from)
var audio = true

func _on_Back_pressed():
	emit_signal("switch", "main", "credits")


func _on_91_gui_input(event: InputEvent) -> void:
	
	if audio && event.is_pressed():
		$easteregg.stream = load("res://assets/audio/button-10.mp3")
		$easteregg.play()
		audio = false
	
	
	

func _on_easteregg_finished() -> void:
	audio = true


func _on_61_gui_input(event: InputEvent) -> void:
	
	if audio && event.is_pressed():
		$easteregg.stream = load("res://assets/audio/test.mp3")
		$easteregg.play()
		audio = false
