extends StaticBody

var t=0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) ->void:
	t+=delta
	$blade.rotation.z += 1.2*delta
	pass
