extends GridContainer

var stats_hash = {}.hash()
onready var acceleration = $acceleration_bar
onready var linear_damp = $linear_damp_bar
onready var mass = $mass_bar
onready var handling = $handling_bar
onready var boost = $boost_bar
onready var slipstream = $slipstream_bar

func _process(_delta):
	if stats_hash != Players.current_car_stats.hash():
		stats_hash = Players.current_car_stats.hash()
		_update(Players.current_car_stats)

func _update(stats):
	acceleration.value = stats.acceleration / stats.linear_damp
	linear_damp.value = stats.linear_damp
	mass.value = stats.mass
	handling.value = (stats.steering / stats.angular_damp) * 10
	handling.value = (stats.steering / stats.angular_damp) * 10
	boost.value = stats.boost_multiplier
	slipstream.value = stats.slipstream_multiplier
	
	#print(stats.steering / stats.angular_damp)
