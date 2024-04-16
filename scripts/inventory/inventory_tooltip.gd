extends Control

@onready var tooltip = $"."
@onready var mesh_container = $SubViewport/MeshContainer
@onready var sub_viewport = $SubViewport

# Speed of rotation in degrees per second.
var rotation_speed = 90.0

var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_item_mesh()

func _ready():
	sub_viewport.own_world_3d = true

func _process(delta):
	if tooltip.visible:
		mesh_container.rotation_degrees.y += rotation_speed * delta

func update_item_mesh():
	mesh_container.mesh = inv_item.item_mesh
