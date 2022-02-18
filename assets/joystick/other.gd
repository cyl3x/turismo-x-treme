extends Node

func _on_booster_button_down():
	Input.action_press("boost")

func _on_booster_button_up():
	Input.action_release("boost")
