extends Node3D

@onready var sub_viewport = $SubViewport
@onready var mesh_instance_3d = $SubViewport/Node3D/MeshInstance3D

var mesh_to_snapshot : ArrayMesh
var snapshot_name : String

func process_image(_mesh : ArrayMesh, _name : String):
	mesh_to_snapshot = _mesh
	snapshot_name = _name
	await get_tree().process_frame
	var img = sub_viewport.get_viewport().get_texture().get_image()
	var image_path = "textures/items/%s_thumbnail.png" % snapshot_name
	img.save_png(image_path)
