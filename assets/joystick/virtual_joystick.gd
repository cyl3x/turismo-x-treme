class_name VirtualJoystick

extends Control

# https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot

#### EXPORTED VARIABLE ####

# The color of the button when the joystick is in use.
export(Color) var pressed_color := Color.white

# If the input is inside this range, the output is zero.
export(float, 0, 200, 1) var deadzone_size : float = 10

# The max distance the tip can reach.
export(float, 0, 500, 1) var clampzone_size : float = 75
export(float, 0, 500, 1) var onezone_size : float = 60

# FIXED: The joystick doesn't move.
# DYNAMIC: Every time the joystick area is pressed, the joystick position is set on the touched position.
enum JoystickMode {FIXED, DYNAMIC}

export(JoystickMode) var joystick_mode := JoystickMode.FIXED

# VISIBILITY_ALWAYS = Always visible.
# VISIBILITY_TOUCHSCREEN_ONLY = Visible on touch screens only.
enum VisibilityMode {ALWAYS , TOUCHSCREEN_ONLY }

export(VisibilityMode) var visibility_mode := VisibilityMode.ALWAYS

# Use Input Actions
export var use_input_actions := true

# Project -> Project Settings -> Input Map
export var action_left := "ui_left"
export var action_right := "ui_right"
export var action_up := "ui_up"
export var action_down := "ui_down"

#### PUBLIC VARIABLES ####

# If the joystick is receiving inputs.
var _pressed := false setget , is_pressed

func is_pressed() -> bool:
	return _pressed

# The joystick output.
var _output := Vector2.ZERO setget , get_output

func get_output() -> Vector2:
	return _output

#### PRIVATE VARIABLES ####

var _touch_index : int = -1

onready var _base := $Base
onready var _tip := $Base/Tip

onready var _base_radius = _base.rect_size * _base.get_global_transform_with_canvas().get_scale() / 2

onready var _base_default_position : Vector2 = _base.rect_position
onready var _tip_default_position : Vector2 = _tip.rect_position

onready var _default_color : Color = Color(1.0,1.0,1.0,1)#_tip.modulate


var reset_on_hide = false
#### FUNCTIONS ####

func _ready() -> void:
	if not OS.has_touchscreen_ui_hint() and visibility_mode == VisibilityMode.TOUCHSCREEN_ONLY:
		hide()
	_base.modulate = Color(1.0,1.0,1.0,0.2)

func _input(event: InputEvent) -> void:
	if not visible or not Players.touch_controls == Players.JoystickMode.ON:
		if not reset_on_hide:
			reset_on_hide = true
			_reset()
		return
	elif visible and Players.touch_controls == Players.JoystickMode.ON:
		if reset_on_hide: reset_on_hide = false
	
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_joystick_area(event.position) and _touch_index == -1:
				if joystick_mode == JoystickMode.DYNAMIC or (joystick_mode == JoystickMode.FIXED and _is_point_inside_base(event.position)):
					if joystick_mode == JoystickMode.DYNAMIC:
						_move_base(event.position)
					_touch_index = event.index
					_tip.modulate = pressed_color
					_update_joystick(event.position)
					get_tree().set_input_as_handled()
		elif event.index == _touch_index:
			_reset()
			get_tree().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_joystick(event.position)
			get_tree().set_input_as_handled()

func _move_base(new_position: Vector2) -> void:
	_base.rect_global_position = new_position - _base.rect_pivot_offset * get_global_transform_with_canvas().get_scale()

func _move_tip(new_position: Vector2) -> void:
	_tip.rect_global_position = new_position - _tip.rect_pivot_offset * _base.get_global_transform_with_canvas().get_scale()

func _is_point_inside_joystick_area(point: Vector2) -> bool:
	var x: bool = point.x >= rect_global_position.x and point.x <= rect_global_position.x + (rect_size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= rect_global_position.y and point.y <= rect_global_position.y + (rect_size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y

func _is_point_inside_base(point: Vector2) -> bool:
	var center : Vector2 = _base.rect_global_position + _base_radius
	var vector : Vector2 = point - center
	if vector.length_squared() <= _base_radius.x * _base_radius.x:
		return true
	else:
		return false

func _update_joystick(touch_position: Vector2) -> void:
	var center : Vector2 = _base.rect_global_position + _base_radius
	var vector : Vector2 = touch_position - center
	vector = vector.clamped(clampzone_size)
	
	_move_tip(center + vector)
	
	if vector.length_squared() > deadzone_size * deadzone_size:
		_pressed = true
		_output = (vector - (vector.normalized() * deadzone_size)) / (onezone_size - deadzone_size)
		_output.x = clamp(_output.x, -1.0, 1.0)
		_output.y = clamp(_output.y, -1.0, 1.0)
	else:
		_pressed = false
		_output = Vector2.ZERO
	
	if use_input_actions:
		_update_input_actions()

func _update_input_actions():
	if action_left != null and action_left != "":
		if _output.x < 0:
			Input.action_press(action_left, -_output.x)
		elif Input.is_action_pressed(action_left):
			Input.action_release(action_left)
		
	if action_right != null and action_right != "":
		if _output.x > 0:
			Input.action_press(action_right, _output.x)
		elif Input.is_action_pressed(action_right):
			Input.action_release(action_right)
		
	if action_up != null and action_up != "":
		if _output.y < 0:
			Input.action_press(action_up, -_output.y)
		elif Input.is_action_pressed(action_up):
			Input.action_release(action_up)
	
	if action_down != null and action_down != "":
		if _output.y > 0:
			Input.action_press(action_down, _output.y)
		elif Input.is_action_pressed(action_down):
			Input.action_release(action_down)

func _reset():
	_pressed = false
	_output = Vector2.ZERO
	_touch_index = -1
	_tip.modulate = _default_color
	_base.rect_position = _base_default_position
	_tip.rect_position = _tip_default_position
	if use_input_actions:
		if action_left != null and action_left != "":
			if Input.is_action_pressed(action_left) or Input.is_action_just_pressed(action_left):
				Input.action_release(action_left)
			
		if action_right != null and action_right != "":
			if Input.is_action_pressed(action_right) or Input.is_action_just_pressed(action_right):
				Input.action_release(action_right)
			
		if action_down != null and action_down != "":
			if Input.is_action_pressed(action_down) or Input.is_action_just_pressed(action_down):
				Input.action_release(action_down)
			
		if action_up != null and action_up != "":
			if Input.is_action_pressed(action_up) or Input.is_action_just_pressed(action_up):
				Input.action_release(action_up)
