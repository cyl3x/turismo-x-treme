extends Control

var _touch_index = -1

export(Color) var default_color = Color(1.0,1.0,1.0,0.2)
export(Color) var pressed_color = Color(1.0,1.0,1.0,0.3)
export(int, 50, 2000, 1) var double_click_interval = 200

var first_pressed_time = 0
var last_pressed_time = 0
var double_clicked = false

export(PoolStringArray) var on_single_click = PoolStringArray()
export(PoolStringArray) var on_double_click = PoolStringArray()

export(PoolRealArray) var single_click_strength = PoolRealArray()
export(PoolRealArray) var double_click_strength = PoolRealArray()

enum ButtonMode {FIXED, DYNAMIC}

export(ButtonMode) var button_mode := ButtonMode.FIXED

onready var texture = $texture
onready var texture_default_position = texture.rect_position

var reset_on_hide = false

func _ready():
	texture.modulate = default_color

func _input(event) -> void:
	if not visible or not Players.touch_controls_active():
		if not reset_on_hide:
			reset_on_hide = true
			_release_actions(on_single_click)
			texture.modulate = default_color
			_touch_index = -1
			_release_actions(on_double_click)
			double_clicked = false
			first_pressed_time = 0
			last_pressed_time = 0
			texture.rect_position = texture_default_position
			get_tree().set_input_as_handled()
		return
	elif visible and Players.touch_controls_active():
		if reset_on_hide: reset_on_hide = false
	
	if not event is InputEventScreenTouch: return
	if event.pressed:
		if _is_point_inside_area(event.position) and _touch_index == -1:
			if button_mode is ButtonMode.DYNAMIC:
				_move_base(event.position)
			_touch_index = event.index
			first_pressed_time = OS.get_ticks_msec()
			texture.modulate = pressed_color
			
			_press_actions(on_single_click, single_click_strength)
			
			if first_pressed_time - last_pressed_time <= double_click_interval:
				_press_actions(on_double_click, double_click_strength)
				double_clicked = true
				
			get_tree().set_input_as_handled()
	elif event.index == _touch_index:
		_release_actions(on_single_click)
		texture.modulate = default_color
		_touch_index = -1
		_release_actions(on_double_click)
		double_clicked = false
		if OS.get_ticks_msec() - first_pressed_time <= double_click_interval:
			last_pressed_time = OS.get_ticks_msec()
		if button_mode is ButtonMode.DYNAMIC:
			texture.rect_position = texture_default_position
		get_tree().set_input_as_handled()

func _move_base(new_position: Vector2) -> void:
	texture.rect_global_position = new_position - texture.rect_pivot_offset * get_global_transform_with_canvas().get_scale()
	
func _press_actions(buttons:PoolStringArray, strengths:PoolRealArray):
	for i in range(0, buttons.size()):
		var strength = 1.0
		if i < strengths.size():
			strength = strengths[i]
		Input.action_press(buttons[i], strength)
		
func _release_actions(buttons:PoolStringArray):
	for button in buttons:
		Input.action_release(button)

func _is_point_inside_area(point: Vector2) -> bool:
	var x: bool = point.x >= rect_global_position.x and point.x <= rect_global_position.x + (rect_size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= rect_global_position.y and point.y <= rect_global_position.y + (rect_size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y
