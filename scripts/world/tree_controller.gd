extends Node3D

@export var bark_normal : Texture2D
@export var tree_mesh_1 : MeshInstance3D
@export var tree_mesh_2 : MeshInstance3D
@export var tree_mesh_3 : MeshInstance3D
@export var tree_mesh_4 : MeshInstance3D
@export var tree_mesh_5 : MeshInstance3D


func _ready():
	var rand_tree = randi_range(1, 5)
	if rand_tree == 1:
		tree_mesh_1.show()
		set_material_parameters(tree_mesh_1)
	elif rand_tree == 2:
		tree_mesh_2.show()
		set_material_parameters(tree_mesh_2)
	elif rand_tree == 3:
		tree_mesh_3.show()
		set_material_parameters(tree_mesh_3)
	elif rand_tree == 4:
		tree_mesh_4.show()
		set_material_parameters(tree_mesh_4)
	elif rand_tree == 5:
		tree_mesh_5.show()
		set_material_parameters(tree_mesh_5)


func set_material_parameters(tree_mesh : MeshInstance3D):
	tree_mesh.get_surface_override_material(0).next_pass = StandardMaterial3D.new()
	tree_mesh.get_surface_override_material(0).next_pass.normal_enabled = true
	tree_mesh.get_surface_override_material(0).next_pass.normal_texture = bark_normal
	tree_mesh.get_surface_override_material(0).next_pass.normal_scale = 0.25
	tree_mesh.get_surface_override_material(0).next_pass.albedo_color = Color(randf_range(0.09, 0.130), randf_range(0.07, 0.11), randf_range(0.03, 0.06))
	tree_mesh.get_surface_override_material(0).next_pass.distance_fade_mode = 3
	tree_mesh.get_surface_override_material(0).next_pass.distance_fade_min_distance = 95
	tree_mesh.get_surface_override_material(0).next_pass.distance_fade_max_distance = 75
