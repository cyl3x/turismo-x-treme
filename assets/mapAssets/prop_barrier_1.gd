extends StaticBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var lod_distance = 80

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _process(_delta):
	var dist_vect: Vector3 =  Players.get_cam_pos() - global_transform.origin
	
	if abs(dist_vect.length()) < lod_distance:
		$M0.visible = true
		$M1.visible = false
	else:
		$M0.visible = false
		$M1.visible = true
		
