extends Control

func hide():
	visible = false
	$joystick.hide()
	$drive.hide()
	$left.hide()
	$right.hide()
	
func show():
	visible = true
	$joystick.show()
	$drive.show()
	
	if Players.touch_controls == Players.JoystickMode.ON:
		$joystick.show()
		$left.hide()
		$right.hide()
	elif Players.touch_controls == Players.JoystickMode.BUTTONS:
		$joystick.hide()
		$left.show()
		$right.show()

func _process(_delta):
	if visible:
		if Players.touch_controls == Players.JoystickMode.ON and not $joystick.visible:
			$joystick.show()
			$left.hide()
			$right.hide()
		elif Players.touch_controls == Players.JoystickMode.BUTTONS and not $joystick.visible:
			$joystick.hide()
			$left.show()
			$right.show()
