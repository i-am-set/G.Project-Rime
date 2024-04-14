extends Control

var subinventory : Control
var held_item_preview : Control
var old_cells : Array[Vector2]
var new_cells : Array[Vector2]

var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		size = Vector2(inv_item.item_width, inv_item.item_height) * Global.INV_DEFAULT_CELL_SIZE


func _ready():
	pass

func _process(delta):
	subinventory = get_parent()
	held_item_preview = subinventory.held_item_preview
