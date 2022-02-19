extends Control

var _touch_index = -1

const default_color = Color(1.0,1.0,1.0,0.2)
const pressed_color = Color(1.0,1.0,1.0,0.3)
const double_click_interval = 200

var first_pressed_time = 0
var last_pressed_time = 0
var double_clicked = false

onready var texture = $texture
onready var texture_default_position = texture.rect_position

func _ready():
	modulate = default_color
	"accelerate"

func _input(event) -> void:
	if not visible or not event is InputEventScreenTouch: return
	
	if event.pressed:
		if _is_point_inside_area(event.position) and _touch_index == -1:
			_move_base(event.position)
			_touch_index = event.index
			first_pressed_time = OS.get_ticks_msec()
			texture.modulate = pressed_color
			Input.action_press("accelerate")
			
			if first_pressed_time - last_pressed_time <= double_click_interval:
				Input.action_press("boost")
				double_clicked = true
				
			get_tree().set_input_as_handled()
	elif event.index == _touch_index:
		Input.action_release("accelerate")
		texture.modulate = default_color
		_touch_index = -1
		Input.action_release("boost")
		double_clicked = false
		if OS.get_ticks_msec() - first_pressed_time <= double_click_interval:
			last_pressed_time = OS.get_ticks_msec()
		texture.rect_position = texture_default_position
		get_tree().set_input_as_handled()

func _move_base(new_position: Vector2) -> void:
	texture.rect_global_position = new_position - texture.rect_pivot_offset * get_global_transform_with_canvas().get_scale()

func _is_point_inside_area(point: Vector2) -> bool:
	var x: bool = point.x >= rect_global_position.x and point.x <= rect_global_position.x + (rect_size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= rect_global_position.y and point.y <= rect_global_position.y + (rect_size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y
