extends Control
class_name InventoryManager

const SUBINVENTORY_RECT = preload("res://scenes/ui/subinventory_rect.tscn")

@onready var scroll_container = $ScrollContainer
@onready var subinventory_container = $ScrollContainer/SubinventoryContainer
@onready var weight_label: Label = $"../TopDivider/Weight"

#var garment_head_id : String = ""
#var garment_face_id : String = ""
#var garment_shirt_id : String = ""
#var garment_subshirt_id : String = ""
#var garment_jacket_id : String = ""
#var garment_pant_id : String = ""
#var garment_subpant_id : String = ""
#var garment_sock_id : String = ""
#var garment_subsock_id : String = ""
#var garment_shoe_id : String = ""
#var garment_back_id : String = ""

@export var weight_capacity : float = 100
var weight_current : float
var empty_slot : Dictionary = {"" : 0}

func _ready():
	update_weight(0)

func try_to_pick_up_item(_picked_up_item_id : String, _stack_size : int) -> bool:
	var _picked_up_item_size : int = StaticData.item_data[_picked_up_item_id]["item_size"] * _stack_size
	
	for i in subinventory_container.subinventory_slot_amount:
		if subinventory_container.subinventory_contents[i] == empty_slot ||  subinventory_container.subinventory_contents[i].has(_picked_up_item_id):
			subinventory_container.add_item(i, _picked_up_item_id, _stack_size)
			return true
	
	return false

func update_weight(_new_weight : int):
	weight_current = _new_weight
	weight_label.text = "%.2f/%.2f" %[weight_current,weight_capacity]
