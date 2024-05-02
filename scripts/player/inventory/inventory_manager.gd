extends Control
class_name InventoryManager

const SUBINVENTORY_RECT = preload("res://scenes/ui/subinventory_rect.tscn")

@onready var scroll_container = $ScrollContainer
@onready var subinventory_container = $ScrollContainer/SubinventoryContainer

var garment_head_id : String = ""
var garment_face_id : String = ""
var garment_shirt_id : String = ""
var garment_subshirt_id : String = ""
var garment_jacket_id : String = ""
var garment_pant_id : String = ""
var garment_subpant_id : String = ""
var garment_sock_id : String = ""
var garment_subsock_id : String = ""
var garment_shoe_id : String = ""
var garment_back_id : String = ""

var subinventories : Array[SubinventoryManager] = []
var empty_slot : Dictionary = {"" : 0}

func _ready():
	for child in subinventory_container.get_children():
		child.queue_free()
	
	for i in 3:
		add_subinventory(randi_range(2, 20))

func try_to_pick_up_item(_picked_up_item_id : String, _stack_size : int) -> bool:
	var _picked_up_item_size : int = StaticData.item_data[_picked_up_item_id]["item_size"] * _stack_size
	
	for _subinventory : SubinventoryManager in subinventories:
		if _subinventory.subinventory_quantity_held + _picked_up_item_size <= _subinventory.subinventory_capacity:
			for i in _subinventory.subinventory_slot_amount:
				if _subinventory.subinventory_contents[i] == empty_slot ||  _subinventory.subinventory_contents[i].has(_picked_up_item_id):
					_subinventory.add_item(i, _picked_up_item_id, _stack_size)
					return true
	
	return false

func add_subinventory(_subinventory_capacity : int):
	var _new_subinvnetory : SubinventoryManager = SUBINVENTORY_RECT.instantiate()
	_new_subinvnetory.subinventory_capacity = _subinventory_capacity
	subinventory_container.add_child(_new_subinvnetory)
	subinventories.append(_new_subinvnetory)

func remove_subinventory(_subinventory_to_remove : SubinventoryManager):
	if subinventories.has(_subinventory_to_remove):
		subinventory_container.remove_child(_subinventory_to_remove)
		subinventories.erase(_subinventory_to_remove)

func update_equipment():
	pass
