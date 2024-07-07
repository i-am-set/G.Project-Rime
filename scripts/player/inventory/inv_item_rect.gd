extends Control
class_name InvItemRect

@onready var inventory_manager: InventoryManager = $"../../../.."
@onready var texture_rect: TextureRect = $TextureRect
#@onready var subinventory_container: SubinventoryManager = $"../.."

var inv_item : InventoryItem = null
var item_id : String = ""

var ItemType : Array = ["Misc", "Resource", "Resource", "Resource", "Resource", "Resource", "Resource"]

func set_item_icon(item_icon : CompressedTexture2D):
	texture_rect = get_child(0)
	texture_rect.texture = item_icon

func _ready():
	pass
	#set_inv_item_rect_label()
#
#func set_inv_item_rect_variables(_item_id : String, _item_stack : int):
	#item_id = _item_id
	#item_stack = _item_stack
	#set_inv_item_rect_label()
#
#func set_inv_item_rect_label():
	#if item_id != "" && item_stack != 0:
		#var _item_data = StaticData.item_data[item_id]
		#var _item_data_item_type = _item_data["item_type"]
		#var _item_icon : String
		#var _item_type : String
		#var _item_weight : float
		#
		#if ItemIcon.has(_item_data_item_type):
			#_item_icon = ItemIcon[0]
		#else:
			#_item_icon = ItemIcon[_item_data_item_type]
		#
		#if ItemType.has(_item_data_item_type):
			#_item_type = ItemType[0]
		#else:
			#_item_type = ItemType[_item_data_item_type]
		#
		#_item_weight = _item_data["item_weight"]
		#var _stack_weight : float = float(_item_weight) * item_stack
		#
		#icon_label.text = _item_icon
		#name_label.text = "%s (%d)" %[_item_data["item_name"], item_stack]
		#weight_label.text = "%.2f" % _stack_weight
#
#func _on_item_pressed() -> void:
	#inventory_manager.ShowRmbMenu(item_slot)
