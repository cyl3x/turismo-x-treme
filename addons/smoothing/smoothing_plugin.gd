tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Smoothing", "Spatial", preload("smoothing.gd"), preload("smoothing.png"))
	pass


func _exit_tree():
	remove_custom_type("Smoothing")
