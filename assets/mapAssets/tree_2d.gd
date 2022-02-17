extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():

	randomize()
	var temp = rand_range(0,6)
	if temp < 3:
		$Tree1.visible = true
		$Tree1_1.visible = true
	else: 
		$Tree2.visible = true
		$Tree2_1.visible = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
