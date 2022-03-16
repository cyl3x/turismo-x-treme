extends Path

var t := 0.0

var cooldown = 0

var paths = []

export(float, 0, 2700) var offset = 0

export(int) var train_length = 1

export(int) var trains = 1

const multiplier = 1800

func _ready():
	for child in get_children():
		if child is PathFollow:
			paths.append(child)
			child.get_child(0).connect("body_entered", self, "_on_train_body_entered", [child.get_child(0)])

func _process(delta: float) -> void:
	t += delta
	
	var i = 0
	var f = 0
	for path in paths:
		if i % 3 == 0:
			f += 1
		path.offset = t * (-75.0) + (i * 9) + (offset * f)
		i += 1
	
	if cooldown >= 0:
		cooldown -= delta


func _on_train_body_entered(body, train):
	if body.get_node("../..").name == str(Sync.me) and cooldown <= 0:
		cooldown = 2
		body.get_node("../../Ball").add_central_force(-train.global_transform.basis.z * multiplier)
