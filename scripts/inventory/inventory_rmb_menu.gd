extends Control

@onready var mesh_container = $SubViewport/MeshContainer
@onready var sub_viewport = $SubViewport

# Speed of rotation in degrees per second.
var rotation_speed = 90.0

var right_clicked_item_ref : Dictionary
var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_item_mesh()

func _ready():
	sub_viewport.own_world_3d = true
	hide()

func _process(delta):
	if visible:
		mesh_container.rotation_degrees.y += rotation_speed * delta

func move_position_within_bounds(new_position: Vector2, boundary_control: Control) -> void:
	var boundary_rect := boundary_control.get_rect()
	var own_rect := get_rect()
	
	var min_x = boundary_rect.position.x
	var max_x = boundary_rect.position.x + boundary_rect.size.x - own_rect.size.x
	var min_y = boundary_rect.position.y
	var max_y = boundary_rect.position.y + boundary_rect.size.y - own_rect.size.y
	
	var clamped_x = clamp(new_position.x, min_x, max_x)
	var clamped_y = clamp(new_position.y, min_y, max_y)
	
	position = Vector2(clamped_x, clamped_y)

func update_item_mesh():
	mesh_container.mesh = inv_item.item_mesh

func base_button_function():
	hide()

func _on_split_one_pressed():
	right_clicked_item_ref["subinventory"].split_item_one(right_clicked_item_ref)
	base_button_function()

func _on_split_half_pressed():
	right_clicked_item_ref["subinventory"].split_item_half(right_clicked_item_ref)
	base_button_function()

func _on_drop_one_pressed():
	right_clicked_item_ref["subinventory"].drop_item_one(right_clicked_item_ref)
	base_button_function()

func _on_drop_all_pressed():
	right_clicked_item_ref["subinventory"].drop_item_all(right_clicked_item_ref)
	base_button_function()

