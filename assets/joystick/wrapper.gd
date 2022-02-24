extends Control

func hide():
	visible = false
	$joystick.hide()
	$drive.hide()
	$left.hide()
	$right.hide()
	
func show():
	visible = true
	$drive.show()
	
	if Players.touch_controls == Players.JoystickMode.ON:
			_show_joystick()
	elif Players.touch_controls == Players.JoystickMode.BUTTONS:
			_show_buttons()

func _process(_delta):
	if visible:
		if Players.touch_controls == Players.JoystickMode.ON and not $joystick.visible:
			_show_joystick()
		elif Players.touch_controls == Players.JoystickMode.BUTTONS and not $joystick.visible:
			_show_buttons()
		else:
			_hide()

func _show_buttons():
	$joystick.hide()
	$left.show()
	$right.show()

func _show_joystick():
	$joystick.show()
	$left.hide()
	$right.hide()

func _hide():
	$joystick.hide()
	$left.hide()
	$right.hide()
