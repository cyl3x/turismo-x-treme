
extends InterpolatedCamera


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _process(delta):
	Players.set_cam_pos(translation)

	var fps = Engine.get_frames_per_second()
	
	if fps >= 60 and !far > 500:
		far = far+1
	if fps < 60 and !far < 100: #!far < 100
		far = far-1
