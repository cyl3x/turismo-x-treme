extends StaticBody

var lod_distance = 100
var dist

func _process(_delta):
	dist = abs((Players.get_cam_pos() - global_transform.origin).length())
	
	if dist < lod_distance:
		$M0.visible = true
		$M1.visible = false
	else:
		$M0.visible = false
		$M1.visible = true
