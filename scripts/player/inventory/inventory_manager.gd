extends Control
class_name InventoryManager

const INV_ITEM_RECT = preload("res://scenes/ui/inv_item_rect.tscn")

@onready var scroll_container = $ScrollContainer
@onready var v_box_container = $ScrollContainer/VBoxContainer

var subinventory_container : Array[Array] = []
var subinventory : Array[Dictionary] = []
var empty_slot : Dictionary = {"" : 0}
var item_rects : Array[Panel] = []

func _ready():
	await initialize_subinventory_slots()
	await initialize_item_rects()

func initialize_subinventory_slots():
	for child in v_box_container.get_children():
		child.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	
	for i in range(1, 30):
		subinventory.append(empty_slot)
		var _new_inv_item_rect = INV_ITEM_RECT.instantiate()
		_new_inv_item_rect.hide()
		v_box_container.add_child(_new_inv_item_rect)

func initialize_item_rects():
	for child in v_box_container.get_children():
		if child is Panel:
			item_rects.append(child)

func update_item_rects():
	for i in subinventory.size():
		var _item_in_slot = subinventory[i]
		if _item_in_slot != empty_slot:
			var _item_rect = item_rects[i]
			var _item_id = _item_in_slot.keys()[0]
			_item_rect.set_inv_item_rect_variables(_item_id, _item_in_slot[_item_id])
			_item_rect.show()
		else:
			item_rects[i].hide()

func add_item(_item_slot : int, _picked_up_item_id : String, _stack_size : int):
	var _new_item : Dictionary = {_picked_up_item_id : _stack_size}
	
	if subinventory[_item_slot] == empty_slot:
		subinventory[_item_slot] = _new_item
	elif subinventory[_item_slot].has(_picked_up_item_id):
		var _cached_item_stack_size = subinventory[_item_slot][_picked_up_item_id]
		subinventory[_item_slot][_picked_up_item_id] = _cached_item_stack_size + _stack_size
	
	update_item_rects()

func try_to_pick_up_item(_picked_up_item_id : String, _stack_size : int) -> bool:
	for i in range(0, 29):
		if subinventory[i] == empty_slot || subinventory[i].has(_picked_up_item_id):
			add_item(i, _picked_up_item_id, _stack_size)
			return true
	
	return false
