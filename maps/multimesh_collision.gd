tool
extends Node

export var gen_collsion = false setget _get_nodes

export var collision_hight_fix = false
export var collision_hight = 1.8

func _get_nodes(_gen_collsion):
	if _gen_collsion and is_inside_tree():
		for scatter in get_children():
			for scatter_item in scatter.get_children():
				if scatter_item.name.match("*catter*"):
					if scatter_item.use_instancing:
						_generate_collision(scatter_item)

func _generate_collision(node):
	var multi_mesh_instance = node.get_node("MultiMeshInstance")
	var multi_mesh = multi_mesh_instance.get_multimesh()
	
	var shape = multi_mesh.mesh.create_convex_shape(true, true)
	var collisionNode = StaticBody.new()
	collisionNode.name = "collision"
	
	if multi_mesh_instance.has_node("collision"):
		multi_mesh_instance.remove_child(multi_mesh_instance.get_node("collision"))
	multi_mesh_instance.add_child(collisionNode)
	collisionNode.set_owner(get_tree().get_edited_scene_root())

	for mesh_index in range(multi_mesh.instance_count):
		var position = multi_mesh.get_instance_transform(mesh_index)

		# Create many collision shapes
		var collisionShape = CollisionShape.new()
		collisionShape.shape = shape
		
		if collision_hight_fix:
			position.origin.y -= collision_hight
		collisionShape.transform = position	
		collisionNode.add_child(collisionShape)
		collisionShape.set_owner(get_tree().get_edited_scene_root())
	collisionNode.scale.y = 5
	
