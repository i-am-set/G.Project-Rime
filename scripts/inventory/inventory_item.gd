extends Resource
class_name InventoryItem

# Item properties
@export var item_id: String
@export var item_name: String
@export var item_width: int
@export var item_height: int
@export var stack_size: int
@export var item_weight: int
@export var item_mesh: ArrayMesh

# Optional: Provide a function to display basic info
func _to_string() -> String:
	return "InvItem: %s (ID: %d)" % [item_name, item_id]
