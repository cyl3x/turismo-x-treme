extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var temp = rand_range(1,6)
	if temp < 3:
		$tree1.flip_h = true
	elif temp > 5: 
		$tree1.visible = false
		$tree4.visible = true
	else :
		$tree2.flip_h = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
