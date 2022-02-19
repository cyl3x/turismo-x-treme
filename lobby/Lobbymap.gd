extends Spatial


var car = null


func _ready():
	pass 

func car_changed(car_id):
	if car != null:
		car.queue_free()
	
	var new_car = load(_make_car_res(car_id)).instance(false)
	
	var sphere_offset = new_car.sphere_offset
	new_car.set_script(load("res://cars/car_dummy.gd"))
	new_car.sphere_offset = sphere_offset
	
	new_car.visible = false
	$Cars.add_child(new_car)
	new_car.force_position($carspawn.translation,$carspawn.rotation, Vector3(0.5,0.5,0.5))
	new_car.visible = true
	car = new_car
	


func _make_car_res(car_name):
	return "res://cars/" + car_name + "/" + car_name + ".tscn"
