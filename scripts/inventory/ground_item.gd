extends RigidBody3D

const HIGHLIGHT_MATERIAL = preload("res://materials/utility/highlight_material.tres")

@onready var ground_item: RigidBody3D = $"."
@onready var mesh_instance = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

const ITEM_ICONS : Dictionary = {
	"a000001" : preload("res://textures/items/icons/ico_flint.png"),
	"a000002" : preload("res://textures/items/icons/ico_stone.png"),
	"a000003" : preload("res://textures/items/icons/ico_pine_needles.png"),
	"a000004" : preload("res://textures/items/icons/ico_dead_pine_needles.png"),
	"a000005" : preload("res://textures/items/icons/ico_twigs.png"),
	"a000006" : preload("res://textures/items/icons/ico_stick.png"),
	"a000007" : preload("res://textures/items/icons/ico_log.png"),
	"a000008" : preload("res://textures/items/icons/ico_charcoal.png"),
	"a000009" : preload("res://textures/items/icons/ico_plant_fiber.png"),
	"a000010" : preload("res://textures/items/icons/ico_tree_bark.png"),
	"a000011" : preload("res://textures/items/icons/ico_cloth_fragment.png"),
	"a000012" : preload("res://textures/items/icons/ico_metal_scrap.png"),
	"a000013" : preload("res://textures/items/icons/ico_glass_shards.png"),
	"a000014" : preload("res://textures/items/icons/ico_loose_wires.png"),
	"a000015" : preload("res://textures/items/icons/ico_sharpened_flint.png")
}


var stack_amount : int = 1

var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_item_parameters()


func _ready():
	DebugDraw3D.draw_box(position, Quaternion.IDENTITY, Vector3.ONE * 0.5, Color.GOLD, true, 0.5)

func _physics_process(delta: float) -> void:
	mesh_instance_3d.global_position = global_position + Vector3(0, 0.25, 0)

func update_item_parameters():
	if is_node_ready():
		set_texture()
		mass = inv_item.item_weight
	else:
		await ready
		update_item_parameters()

func set_texture():
	var new_material = mesh_instance_3d.material_override.duplicate()
	new_material.albedo_texture = ITEM_ICONS[inv_item.item_id]
	mesh_instance_3d.material_override = new_material

func toggle_highlight(toggle : bool):
	if toggle:
		mesh_instance_3d.material_override.emission = Color.WHITE
	else:
		mesh_instance_3d.material_override.emission = Color.BLACK

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
		await get_tree().create_timer(0.5).timeout
		freeze = true
