extends Control
class_name InventoryManager

@onready var scroll_container = $ScrollContainer
@onready var v_box_container = $ScrollContainer/VBoxContainer

var subinventory_container : Array[SubinventoryManager] = []
var empty_slot : Dictionary = {"" : 0}

func _ready():
	pass

func try_to_pick_up_item(_picked_up_item_id : String, _stack_size : int) -> bool:
	for _subinventory : SubinventoryManager in subinventory_container:
		for i in range(0, 29):
			if _subinventory.subinventory_contents[i] == empty_slot ||  _subinventory.subinventory_contents[i].has(_picked_up_item_id):
				_subinventory.add_item(i, _picked_up_item_id, _stack_size)
				return true
	
	return false
