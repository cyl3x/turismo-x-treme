extends Node
onready var ball = $Ball
onready var car = $car
onready var ground_ray = $car/GroundRay
onready var nametag = $car/nametag_sprite
var sphere_offset = Vector3(0, -1, 0)

func _ready():
	ground_ray.add_exception(ball)
	ball.add_collision_exception_with($car/car_mesh_hitbox)
	nametag.visible = false

func force_position(position, rot, scale):
		ball.translation = position
		ball.rotation = rot
		scale = scale

func _physics_process(_delta):
	car.transform.origin = ball.transform.origin + sphere_offset
	car.rotation = ball.rotation
	
func _on_SlipStream_body_entered(_body):
	pass
	
func _on_SlipStream_body_exited(_body):
	pass
