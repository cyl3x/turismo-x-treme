extends Spatial

onready var target = get_parent()

func _physics_process(_delta):
	rotation.z =- target.rotation.z
