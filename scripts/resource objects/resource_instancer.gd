extends Node3D

#-------------------- Trees ---------------------------#
var birch_tree = [
	preload("res://scenes/resourceobjects/nature/trees/birch_tree_1.tscn"),
	preload("res://scenes/resourceobjects/nature/trees/birch_tree_2.tscn"),
	preload("res://scenes/resourceobjects/nature/trees/birch_tree_3.tscn"),
	preload("res://scenes/resourceobjects/nature/trees/birch_tree_4.tscn")
]
var pine_tree = [
	preload("res://scenes/resourceobjects/nature/trees/pine_tree_1.tscn"),
	preload("res://scenes/resourceobjects/nature/trees/pine_tree_2.tscn"),
	preload("res://scenes/resourceobjects/nature/trees/pine_tree_3.tscn"),
	preload("res://scenes/resourceobjects/nature/trees/pine_tree_4.tscn"),
]
var tall_pine_tree = [
	preload("res://scenes/resourceobjects/nature/trees/tall_pine_tree_1.tscn"),
	preload("res://scenes/resourceobjects/nature/trees/tall_pine_tree_2.tscn")
]
var trees = [
	birch_tree,
	pine_tree,
	tall_pine_tree
]

#-------------------- Grass Tufts ---------------------#



#------------------------------------------------------#

var weights : Dictionary = {
	birch_tree : 3,
	pine_tree : 0.5,
	tall_pine_tree : 10
}

var _is_initialized : bool = false
var _total_weight : float = 0
var _rng_base = RandomNumberGenerator.new()

func initiate_weight_system():
	if !_is_initialized:
		for resource in weights:
			_total_weight += weights[resource]
		_is_initialized = true

func instantiate_resource(height_seed : int) -> Node3D:
	initiate_weight_system()
	
	_rng_base.seed = height_seed
	var dice_roll = _rng_base.randf_range(0, _total_weight)
	
	for resource in weights:
		if weights[resource] >= dice_roll:
			var rand_resource = _rng_base.randi_range(0, resource.size()-1)
			var resource_instance = resource[rand_resource].instantiate()
			var resource_scale = _rng_base.randf_range(0.8, 2.0)
			resource_instance.scale = Vector3(resource_scale, resource_scale, resource_scale)
			resource_instance.rotation = Vector3(deg_to_rad(_rng_base.randi_range(-2, 2)), deg_to_rad(_rng_base.randi_range(0, 359)), deg_to_rad(_rng_base.randi_range(-2, 2)))
			
			if trees.has(resource):
				return tree_parameters(resource_instance)
			
			return resource_instance
		dice_roll -= weights[resource]
	
	printerr("failed to roll a resource")
	return null

func tree_parameters(tree) -> Node3D:
	var first_child = tree.get_child(0)
	var first_child_material = first_child.material_override
	var LOD_range = Global.RENDER_DISTANCE*6
	first_child_material = first_child_material.duplicate()
	first_child.lod_bias = 1
	var tree_shader = first_child_material
	for child in tree.get_children():
		child.lod_bias = 0.25
		child.show()
	tree_shader.set_shader_parameter("tree_base_height", _rng_base.randf_range(0.1, 1.2))
	tree_shader.set_shader_parameter("tree_base_darkness", _rng_base.randf_range(0.1, 0.2))
	tree_shader.set_shader_parameter("uv1_offset", Vector3(_rng_base.randf_range(1, 20),1 ,1))
	
	return tree
