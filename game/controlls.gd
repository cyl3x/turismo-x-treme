extends Control

func _on_left_pressed():
	if visible:
		Input.action_press("steer_left")
	

func _on_right_pressed():
	if visible:
		Input.action_press("steer_right")
	

func _on_accelerate_pressed():
	if visible:
		Input.action_press("accelerate")
	

func _on_break_pressed():
	if visible:
		Input.action_press("break")


func _on_boost_pressed():
	if visible:
		Input.action_press("accelerate")
		Input.action_press("boost")


func _on_left_released():
	if visible:
		Input.action_release("steer_left")


func _on_right_released():
	if visible:
		Input.action_release("steer_right")


func _on_accelerate_released():
	if visible:
		Input.action_release("accelerate")


func _on_break_released():
	if visible:
		Input.action_release("break")


func _on_boost_released():
	if visible:
		Input.action_release("accelerate")
		Input.action_release("boost")
