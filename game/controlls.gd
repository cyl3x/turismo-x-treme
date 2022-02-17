extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"




# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_left_pressed():
	Input.action_press("steer_left")
	

func _on_right_pressed():
	Input.action_press("steer_right")
	

func _on_accelerate_pressed():
	Input.action_press("accelerate")
	

func _on_break_pressed():
	Input.action_press("break")


func _on_boost_pressed():
	Input.action_press("accelerate")
	Input.action_press("boost")


func _on_left_released():
	Input.action_release("steer_left")


func _on_right_released():
	Input.action_release("steer_right")


func _on_accelerate_released():
	Input.action_release("accelerate")


func _on_break_released():
	Input.action_release("break")


func _on_boost_released():
	Input.action_release("accelerate")
	Input.action_release("boost")
