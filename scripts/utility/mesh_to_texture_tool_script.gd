extends Node3D

@onready var sub_viewport = $SubViewport
@onready var viewport_texture = $ViewportTexture
@onready var mesh_instance_3d = $SubViewport/Node3D/MeshInstance3D
@onready var camera_3d = $SubViewport/Node3D/Camera3D

var base_image_resolution : int = 128

func process_image(_mesh : ArrayMesh, _name : String, _width_multiplier : int, _height_multiplier : int):
	if sub_viewport == null:
		sub_viewport = $SubViewport
	if viewport_texture == null:
		viewport_texture = $ViewportTexture
	if mesh_instance_3d == null:
		mesh_instance_3d = $SubViewport/Node3D/MeshInstance3D
	
	sub_viewport.own_world_3d = true
	sub_viewport.transparent_bg = true
	
	sub_viewport.size = Vector2(base_image_resolution * _width_multiplier, base_image_resolution * _height_multiplier)
	camera_3d.size = 0.13*(_height_multiplier) + 0.24
	print_debug(_name, " ", camera_3d.size)
	print_debug(Vector2(base_image_resolution * _width_multiplier, base_image_resolution * _height_multiplier))
	
	mesh_instance_3d.mesh = _mesh
	await get_tree().create_timer(0.2).timeout
	var img = await viewport_texture.get_texture().get_image()
	await get_tree().create_timer(0.2).timeout
	var image_path = "textures/items/%s_thumbnail.png" % _name
	img.save_png(image_path)
