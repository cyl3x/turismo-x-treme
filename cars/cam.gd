extends InterpolatedCamera

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	
	if fps >= 60 and !far > 500:
		far = far+1
	if fps < 60 and !far < 100: #!far < 100
		far = far-1
