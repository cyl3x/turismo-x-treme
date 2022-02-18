extends Control

var _touch_index = -1

func _input(event) -> void:
	if not visible: return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_area(event.position) and _touch_index == -1:
				_touch_index = event.index
				Input.action_press("boost")
				get_tree().set_input_as_handled()
		elif event.index == _touch_index:
			Input.action_release("boost")
			_touch_index = -1
			get_tree().set_input_as_handled()

func _is_point_inside_area(point: Vector2) -> bool:
	var x: bool = point.x >= rect_global_position.x and point.x <= rect_global_position.x + (rect_size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= rect_global_position.y and point.y <= rect_global_position.y + (rect_size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y
