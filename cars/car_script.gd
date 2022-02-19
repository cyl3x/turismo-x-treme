extends Spatial
# Node references
var _game_ended = false
var inital_position = null
var inital_rotation = null

var trackpath = null
var trackpath_target = null

var aabb: AABB
var last_speed_pos = Vector3()
var wait_time_left = 0
var pop = false
var current_gear = 1
var max_speed = 220

onready var nametag = $car/nametag_sprite
onready var nametag_text = $car/nametag_sprite/nametag_viewport/nametag
onready var ball = $Ball
onready var car = $car_wrapper
onready var ground_ray = $car/GroundRay
onready var type_ray = $car/TypeRay
onready var car_mesh = $car/meshs/car/body
onready var right_wheel = $car/meshs/car/wheel_front_right
onready var left_wheel = $car/meshs/car/wheel_front_left
onready var back_right_wheel = $car/meshs/car/wheel_back_right
onready var back_left_wheel = $car/meshs/car/wheel_back_left
onready var particle1 = $car/Particles
onready var particle2 = $car/Particles2
onready var special_particle1 = $car/Particles_special
onready var special_particle2 = $car/Particles_special2
onready var sound = $car/Sound
onready var Idle_sound = $car/IdleSound
onready var special_sound = $car/SpecialSound

onready var init_rotate_right_wheel = right_wheel.rotation.y
onready var init_rotate_left_wheel = left_wheel.rotation.y
onready var init_transform_nametag = nametag.transform

# Auto aktiv oder nur zur schau in der Lobby
export var not_in_lobby = true

# Motorleistung
export(int) var acceleration = 60
export(int) var boost_max_amount = 2000

# Lenkung in Grad
export(float) var steering = 21

# Turngeschwindigkeit
export(float) var turn_speed = 3

# Minimum der Geschwindigkeit, um zu lenken 
export(float) var turn_stop_limit = 0.75

# Masse des Fahrzeugees
export(float) var mass = 1

# Wo wird das CarMesh relativ zur Sphere platziert
export var sphere_offset = Vector3(0, 0, 0)

export(float) var linear_damp = 0.4

export(float) var angular_damp = 5

export(float) var linear_damp_drift = 0.4

export(float) var angular_damp_drift = 5

export(int) var body_tilt = 300

export(float) var slipstream_multiplier = 0.1

export(float) var boost_multiplier = 0.2

export(Material) var _Material1
export(Material) var _Material2
export(Material) var _Material3
var ground_type = 2
var speed_multiplier = 1
var boost_active = false
var boost_recharge_cooldown = 0
var boost_amount = 0

var is_in_slipstream = false

var player_position = null
var speed = 0
# Input
var speed_input = 0
var rotate_input = 0

signal update_hud(speed, boost_data)

func _ready():
	ground_ray.add_exception(ball)
	ball.add_collision_exception_with($car/car_mesh_hitbox)
		
	aabb = car_mesh.get_transformed_aabb().merge(right_wheel.get_transformed_aabb()).merge(left_wheel.get_transformed_aabb()).merge(back_left_wheel.get_transformed_aabb()).merge(back_right_wheel.get_transformed_aabb())
	var vec: Vector3 = aabb.size / Vector3(2,2,2)
	get_node("car/car_mesh_hitbox/car_mesh_aabb").get_shape().set_extents(vec)
	
	nametag.texture = nametag.get_node("nametag_viewport").get_texture()
	
	ball.translation = inital_position
	car.rotation = inital_rotation
	ball.mass = mass
	ball.linear_damp = linear_damp
	ball.angular_damp = angular_damp
	
	player_position = {
		"ball": cut_transform(ball.transform), 
		"smoke_par": false, 
		"special_par": false, 
		"r_car": car.rotation_degrees,
		"m_r_car": car_mesh.rotation.x,
		"m_right": right_wheel.rotation.y,
		"m_left": left_wheel.rotation.y,
	}
	Players.set_car_position(int(name), player_position)
	
	nametag_text.text = Players.get_nickname(int(name))
	
	if is_network_master():
		nametag.visible = false
		pause_mode = Node.PAUSE_MODE_PROCESS

func _physics_process(_delta):
	if get_tree().paused:
		Idle_sound.stop()
		sound.stop()
		return
	# Beschleunigung abhängig von der Richtung
	if is_network_master():
		# Vielleicht noch irgendwann notwending
		car.transform.origin.x = ball.transform.origin.x + sphere_offset.x
		car.transform.origin.z = ball.transform.origin.z + sphere_offset.z
		car.transform.origin.y = lerp(car.transform.origin.y, ball.transform.origin.y + sphere_offset.y, 10 * _delta)

		ball.add_central_force(-car.global_transform.basis.z * speed_input)

		player_position.ball = ball.transform
		
		player_position.r_car = Vector3(cut(car.rotation.x), cut(car.rotation.y), cut(car.rotation.z))
		
		player_position.m_r_car = cut(car_mesh.rotation.x)
		player_position.m_right = cut(right_wheel.rotation.y)
		player_position.m_left  = cut(left_wheel.rotation.y)
		
		player_position.smoke_particals = particle1.emitting and particle2.emitting
		player_position.special_particals = special_particle1.emitting and special_particle2.emitting
		
		trackpath_target.global_transform.origin = car.global_transform.origin
		Players.set_map_offset(cut(trackpath.get_curve().get_closest_offset(trackpath_target.get_translation()), 0.01))
		Players.set_cam_pos(ball.translation)
		Players.set_car_position(int(name), player_position)
		
		speed = cut(ball.linear_velocity.length() * 2)
	
		audioPitch()
	else:
		# check, maybe player left while updating
		if Players.has(int(name)):
			# update not local player with server data
			var pos = Players.get_car_position(int(name))
			
			if not pos.has("ball"):
				#print("Error: Player " + name + " missing ball transformation")
				return
			
			ball.transform = pos.ball
			car.rotation = pos.r_car
			
			car.transform.origin.x = ball.transform.origin.x + sphere_offset.x
			car.transform.origin.z = ball.transform.origin.z + sphere_offset.z
			car.transform.origin.y = lerp(car.transform.origin.y, ball.transform.origin.y + sphere_offset.y, 10 * _delta)
			
			# Mesh
			car_mesh.rotation.x = pos.m_r_car
			right_wheel.rotation.y = pos.m_right
			left_wheel.rotation.y  = pos.m_left
			
			emit_particles(pos.smoke_par)
			emit_special_particles(pos.special_par)
		else:
			print("Game: Player " + name + " getting deleted")
			self.queue_free()

func _process(delta):
	if _game_ended or (Server.is_network_active() and not is_network_master()):
		speed_input = 0
		rotate_input = 0
		return
		
	# Boost
	if not boost_active and boost_recharge_cooldown <= 0:
		boost_amount += cut(delta * 100, 0.01)
	else:
		boost_recharge_cooldown -= delta

	boost_amount = clamp(boost_amount, 0, boost_max_amount)
	
	if get_tree().paused:
		return

	# Every 1/10 second
	wait_time_left -= delta
	if wait_time_left < 0 and not _game_ended:
		wait_time_left += 0.1
		timed_process()
		
	if Input.is_action_pressed("cam_flip"):
		$car/target.rotation_degrees.y = 180
		
	else: 
		$car/target.rotation_degrees.y = 0

	# Abfrage ob man sich in der Luft befindet
	if ground_ray.is_colliding():
		if Input.is_action_just_pressed("print_coord"):
			print(" translation: " + str(ball.translation) + " rotation: " + str(car.rotation))
			
		speed_multiplier = 1
		
		# Input: Beschleunigung und Bremse
		speed_input = 0
		speed_input += Input.get_action_strength("accelerate")
		speed_input -= Input.get_action_strength("brake") * 0.5
		speed_input *= acceleration
		
		# Slipstream-Multiplier
		if is_in_slipstream:
			speed_multiplier += slipstream_multiplier
		
		# Negativbeschleunugung auf Gras
		if !type_ray.is_colliding():
			speed_multiplier -= 0.55
			emit_special_particles(ball.linear_velocity.length() > 5)
		else:
			emit_special_particles(false)
		
		#Input: Booster
		
		boost_active = Input.is_action_pressed("boost")
		if Input.is_action_pressed("boost") && boost_amount > 0:
			boost_active = true
			boost_amount -= 4
			if boost_amount <= 0:
				boost_recharge_cooldown = 5 # 5 Sekunden
			speed_multiplier += boost_multiplier
		else:
			boost_active = false
		if Input.is_action_just_released("boost"):
			boost_recharge_cooldown = 2 # 5 Sekunden
		
		speed_input *= speed_multiplier
	
		# Input: Lenken
		rotate_input = 0
		rotate_input += Input.get_action_strength("steer_left")
		rotate_input -= Input.get_action_strength("steer_right")
		rotate_input *= deg2rad(steering)
		
		# Rotieren der Räder
		right_wheel.rotation.y = init_rotate_right_wheel + rotate_input
		left_wheel.rotation.y = init_rotate_left_wheel + rotate_input
		
		# Particals
		if Input.is_action_pressed("drift"):
			ball.angular_damp = angular_damp_drift
			ball.linear_damp = linear_damp_drift
			
			emit_particles(Input.is_action_pressed("steer_left") or Input.is_action_pressed("steer_right"))
				
			speed_input *= 0.7
		else:
			ball.angular_damp = angular_damp
			ball.linear_damp = linear_damp
			emit_particles(false)
			
		var d = ball.linear_velocity.normalized().dot(-car.transform.basis.z)
		emit_particles(ball.linear_velocity.length() > 10.5 and d < 0.8)
		
		# Rotation des CarMeshs
		if ball.linear_velocity.length() > turn_stop_limit:
			var new_basis = car.global_transform.basis.rotated(car.global_transform.basis.y, rotate_input)
			car.global_transform.basis = car.global_transform.basis.slerp(new_basis, turn_speed * delta)
			car.global_transform = car.global_transform.orthonormalized()

			# Lehnen des Autos
			var t = -rotate_input * ball.linear_velocity.length() / body_tilt
			car_mesh.rotation.x = lerp(car_mesh.rotation.x, t, 5 * delta)
	
		var n = ground_ray.get_collision_normal()
		var xform = align_with_y(car.global_transform, n.normalized())
		car.global_transform = car.global_transform.interpolate_with(xform, 10 * delta)

func game_ended():
	_game_ended = true

func timed_process():
	var boost = {
		"active": boost_active,
		"amount_left": boost_amount,
		"max_amount": boost_max_amount,
		"recharge_cooldown": boost_recharge_cooldown > 0,
	}
	emit_signal("update_hud", speed, boost)

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func set_position(position, rotation):
	inital_position = position
	inital_rotation = rotation
	
func set_trackpath_node(trackpath_node):
	trackpath = trackpath_node
	trackpath_target = trackpath_node.get_node("target")
	
func _on_slipstream_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if body.name == "Ball":
		is_in_slipstream = true

func _on_slipstream_exited(_body_rid, _body, _body_shape_index, _local_shape_index):
	is_in_slipstream = false
	
func _on_SlipStream_body_entered(body):
	if body.name == "Ball":
		is_in_slipstream = true

func _on_SlipStream_body_exited(_body):
	is_in_slipstream = false

func emit_particles(on):
	if !special_particle1.emitting:
		particle1.emitting = on
		particle2.emitting = on
	
func emit_special_particles(on):
	special_particle1.emitting = on
	special_particle2.emitting = on
	
func update_ground_type(gt):
	ground_type = gt
	var mat = null
	if gt == 1:
		mat = _Material1
	if gt == 2:
		mat = _Material2
	if gt == 3:
		mat = _Material3
		
	special_particle1.draw_pass_1.surface_set_material(0,mat)
	special_particle2.draw_pass_1.surface_set_material(0,mat)
	
func audioPitch():
	if speed > 152: current_gear = 3.3
	if speed < 132: current_gear = 2.8
	if speed < 90: current_gear = 2
	if speed < 60: current_gear = 1.8
	if speed < 30: current_gear = 1.3
	if speed < 20: current_gear = 1
	
	if current_gear == 0 and not Idle_sound.playing: Idle_sound.play()
	elif current_gear != 0 and Idle_sound.playing: Idle_sound.stop()
			
	if current_gear != 0 and not sound.playing: sound.play()
	elif current_gear == 0 and sound.playing: sound.stop()
			
	sound.pitch_scale = 0.5 + (speed / 100) / current_gear
	#Idle_sound.pitch_scale = 2 + (speed / 20) / current_gear
	
	#print(str(sound.pitch_scale))

func cut(to_round, cut_float = 0.001):
	return stepify(to_round, cut_float)
	
func cut_transform(transform: Transform):
	var new_transform = Transform(
		Vector3(cut(transform.basis.x.x), cut(transform.basis.x.y), cut(transform.basis.x.z)),
		Vector3(cut(transform.basis.y.x), cut(transform.basis.y.y), cut(transform.basis.y.z)),
		Vector3(cut(transform.basis.z.x), cut(transform.basis.z.y), cut(transform.basis.z.z)),
		Vector3(cut(transform.origin.x), cut(transform.origin.y), cut(transform.origin.z))
	)
	return new_transform
