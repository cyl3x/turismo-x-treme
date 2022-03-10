extends InterpolatedCamera

func _process(_delta):
	rotation = Vector3(0, rotation.y, 0)
	
	var fps = Engine.get_frames_per_second()
	
	if Players.view_distance == 100:
		if fps >= 60 and !far > 300:
			far = far+1
		if fps >= 120 and !far > 800:
			far = far+1
		if fps < 60 and !far < 100:
			far = far-1
	else:
		far = Players.view_distance
