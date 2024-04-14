extends Control

var subinventory : Control
var held_item_preview : Control
var old_cells : Array[Vector2]
var new_cells : Array[Vector2]

var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_item_size()


func _ready():
	Global.inv_cell_size_updated.connect(update_item_size)

func _process(delta):
	subinventory = get_parent()
	held_item_preview = subinventory.held_item_preview

func update_item_size():
	size = Vector2(inv_item.item_width, inv_item.item_height) * Global.INV_CELL_SIZE
