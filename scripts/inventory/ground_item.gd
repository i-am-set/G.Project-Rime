extends RigidBody3D

const HIGHLIGHT_MATERIAL = preload("res://materials/utility/highlight_material.tres")

@onready var mesh_instance = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D


var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_item_parameters()


func _ready():
	randomize_rotation()
	randomize_scale()
	DebugDraw3D.draw_box(position, Quaternion.IDENTITY, Vector3.ONE * 0.5, Color.GOLD, true, 0.5)

func update_item_parameters():
	if is_node_ready():
		set_mesh_parameters()
		mass = inv_item.item_weight
	else:
		await ready
		update_item_parameters()

func set_mesh_parameters():
	print_debug("updating item parameters")
	if !mesh_instance.mesh:
		print("Error: MeshInstance3D does not contain a mesh")
		return
	
	mesh_instance.mesh = inv_item.item_mesh
	
	if collision_shape.shape == null:
		print("Error: CollisionShape3D does not have a shape attached")
		return
	
	var aabb = mesh_instance.mesh.get_aabb()
	collision_shape.shape.size = (aabb.size*0.75)*scale

func toggle_highlight(toggle : bool):
	if toggle:
		mesh_instance.set_surface_override_material(0, HIGHLIGHT_MATERIAL)
	else:
		mesh_instance.set_surface_override_material(0, null)

func randomize_rotation():
	var random_x = randf() * 2.0 * PI  # Random angle between 0 and 2π radians
	var random_y = randf() * 2.0 * PI  # Random angle between 0 and 2π radians
	var random_z = randf() * 2.0 * PI  # Random angle between 0 and 2π radians
	rotation_degrees = Vector3(rad_to_deg(random_x), rad_to_deg(random_y), rad_to_deg(random_z))

func randomize_scale():
	var random_scale = randf_range(0.75, 1.25)
	scale = Vector3(random_scale, random_scale, random_scale)

func _on_body_entered(body):
	if body.collision_layer == 1:
		freeze = true
