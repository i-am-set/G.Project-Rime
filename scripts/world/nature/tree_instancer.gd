extends Node3D

var tree_paths = [
	preload("res://scenes/nature/trees/birch_tree_1.tscn"),
	preload("res://scenes/nature/trees/birch_tree_2.tscn"),
	preload("res://scenes/nature/trees/birch_tree_3.tscn"),
	preload("res://scenes/nature/trees/birch_tree_4.tscn"),
	preload("res://scenes/nature/trees/pine_tree_1.tscn")
]

func instantiate_tree() -> Node3D:
	var rand_tree = randi_range(0, tree_paths.size()-1)
	var tree = tree_paths[rand_tree].instantiate()
	var scale = randf_range(0.8, 2.0)
	tree.scale = Vector3(scale, scale, scale)
	tree.rotation = Vector3(deg_to_rad(randi_range(-2, 2)), deg_to_rad(randi_range(0, 359)), deg_to_rad(randi_range(-2, 2)))
	
	tree.get_child(0).material_override = tree.get_child(0).material_override.duplicate()
	var tree_shader = tree.get_child(0).material_override
	tree_shader.set_shader_parameter("tree_base_height", randf_range(0.1, 1.2))
	tree_shader.set_shader_parameter("tree_base_darkness", randf_range(0.1, 0.2))
	tree_shader.set_shader_parameter("uv1_offset", Vector3(randf_range(1, 20),1 ,1))
	
	
	return tree
