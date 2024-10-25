extends Control
class_name InvItemRect

@onready var texture_rect: TextureRect = $TextureRect
#@onready var subinventory_container: SubinventoryManager = $"../.."

var inv_item : InventoryItem = null
var item_id : String = ""

var ItemType : Array = ["Junk", "Resource", "Weapon", "Garment", "Food", "Medical"]

func set_item_icon(item_icon : CompressedTexture2D):
	texture_rect = get_child(0)
	texture_rect.texture = item_icon
