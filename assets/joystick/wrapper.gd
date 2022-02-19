extends Control

func hide():
	visible = false
	$joystick.hide()
	$drive.hide()
	
func show():
	visible = true
	$joystick.show()
	$drive.show()
