extends Spatial

export(int) var ground_type = 0

func _ready():
	pass

func truely_ready():
	for player in $Players.get_children():
		player.update_ground_type(ground_type)
