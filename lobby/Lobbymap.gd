extends Spatial


var car = null


func _ready():
	var _discart = Players.connect("car_switched", self, "car_changed")

func car_changed(car_id):
	if car != null:
		car.queue_free()
	
	var new_car = load(Players.make_car_res(car_id)).instance(false)
	
	var sphere_offset = new_car.sphere_offset
	_set_stats(new_car)
	new_car.set_script(load("res://cars/car_dummy.gd"))
	new_car.sphere_offset = sphere_offset
	
	new_car.visible = false
	$Cars.add_child(new_car)
	new_car.force_position($carspawn.translation,$carspawn.rotation, Vector3(0.5,0.5,0.5))
	new_car.visible = true
	car = new_car
	
	
func _set_stats(node):
	Players.current_car_stats = {
		"acceleration": node.acceleration,
		"linear_damp": node.linear_damp,
		"angular_damp": node.angular_damp,
		"boost_multiplier": node.boost_multiplier,
		"steering": node.steering,
		"mass": node.mass,
		"slipstream_multiplier": node.slipstream_multiplier,
	}
