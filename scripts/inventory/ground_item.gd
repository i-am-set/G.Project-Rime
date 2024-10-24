extends RigidBody3D

const HIGHLIGHT_MATERIAL = preload("res://materials/utility/highlight_material.tres")

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d = $Area3D/CollisionShape3D

var stack_amount : int = 1
var is_highlighted : bool = false

var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_item_parameters()


func _ready():
	DebugDraw3D.draw_box(position, Quaternion.IDENTITY, Vector3.ONE * 0.5, Color.GOLD, true, 0.5)

func _physics_process(delta: float) -> void:
	#mesh_instance_3d.global_position = global_position + Vector3(0, 0.25, 0)
	if is_highlighted:
		display_debug_cube()

func get_interact_label() -> String:
	return "[E] to pick up " + inv_item.get_item_name()

func in_range():
	toggle_highlight(true)

func not_in_range():
	toggle_highlight(false)

func update_item_parameters():
	if is_node_ready():
		set_texture()
		mass = inv_item.item_weight
	else:
		await ready
		update_item_parameters()

func set_texture():
	var new_material = mesh_instance_3d.material_override.duplicate()
	new_material.albedo_texture = Global.ITEM_ICONS[inv_item.item_id]
	mesh_instance_3d.material_override = new_material

func toggle_highlight(toggle : bool):
	if toggle:
		is_highlighted = true
		mesh_instance_3d.material_override.emission = Color.WHITE
	else:
		is_highlighted = false
		mesh_instance_3d.material_override.emission = Color.BLACK

func display_debug_cube():
	DebugDraw3D.draw_box(position, quaternion, Vector3(0.5,0.5,0.5), Color.WHITE, true, 0)

func randomize_rotation():
	var random_x = randf() * 2.0 * PI  # Random angle between 0 and 2π radians
	var random_y = randf() * 2.0 * PI  # Random angle between 0 and 2π radians
	var random_z = randf() * 2.0 * PI  # Random angle between 0 and 2π radians
	rotation_degrees = Vector3(rad_to_deg(random_x), rad_to_deg(random_y), rad_to_deg(random_z))

func randomize_scale():
	var random_scale = randf_range(0.75, 1.25)
	scale = Vector3(random_scale, random_scale, random_scale)

func _on_body_entered(body: Node) -> void:
	if body.collision_layer == 1:
		await get_tree().create_timer(0.5).timeout
		freeze = true
