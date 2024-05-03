extends Control
class_name InventoryManager

const SUBINVENTORY_RECT = preload("res://scenes/ui/subinventory_rect.tscn")

@onready var rmb_menu: Control = $"../../../../RmbMenu"
@onready var scroll_container = $ScrollContainer
@onready var subinventory_container = $ScrollContainer/SubinventoryContainer
@onready var weight_label: Label = $"../TopDivider/Weight"

var mouse_pos : Vector2

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
var empty_slot : Array = ["", 0]

func _ready():
	update_weight(0)

func _process(delta):
	mouse_pos = get_global_mouse_position()

func try_to_pick_up_item(_picked_up_item_id : String, _stack_size : int) -> bool:
	var _picked_up_item_size : int = StaticData.item_data[_picked_up_item_id]["item_size"] * _stack_size
	
	for i in subinventory_container.subinventory_slot_amount:
		if subinventory_container.subinventory_contents[i] == empty_slot || subinventory_container.subinventory_contents[i] == _picked_up_item_id:
			subinventory_container.add_item(i, _picked_up_item_id, _stack_size)
			return true
	
	return false

func ShowRmbMenu(_item_slot : int):
	rmb_menu.position = mouse_pos
	rmb_menu.right_clicked_item_ref = _item_slot
	rmb_menu.inv_item = subinventory_container.subinventory_contents[_item_slot]
	rmb_menu.show()

func HideRmbMenu():
	rmb_menu.hide()

func update_weight(_new_weight : int):
	weight_current = _new_weight
	weight_label.text = "%.2f/%.2f" %[weight_current,weight_capacity]
