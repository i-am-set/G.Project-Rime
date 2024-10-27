extends Control
class_name InvItemRect

@onready var texture_rect: TextureRect = $TextureRect
const INVENTORY_SLOT_SELECTED = preload("res://textures/ui/Inventory/inventory_slot_selected.png")
const INVENTORY_SLOT_DESELECTED = [
	preload("res://textures/ui/Inventory/inventory_slot_0.png"),
	preload("res://textures/ui/Inventory/inventory_slot_1.png"),
	preload("res://textures/ui/Inventory/inventory_slot_2.png"),
	preload("res://textures/ui/Inventory/inventory_slot_3.png")
]

var inv_item : InventoryItem = null
var item_id : String = ""

var ItemType : Array = ["Junk", "Resource", "Weapon", "Garment", "Food", "Medical"]

func set_item_icon(item_icon : CompressedTexture2D):
	texture_rect = get_child(0)
	if item_icon == null:
		texture_rect.visible = false
		return
	texture_rect.visible = true
	texture_rect.texture = item_icon

func select_slot():
	self.texture = INVENTORY_SLOT_SELECTED

func deselect_slot():
	if self.texture == INVENTORY_SLOT_SELECTED:
		var random_index = randi_range(0, 3)
		self.texture = INVENTORY_SLOT_DESELECTED[random_index]
