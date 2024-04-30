extends Control
class_name SubinventoryManager

const INV_ITEM_RECT = preload("res://scenes/ui/inv_item_rect.tscn")

@onready var inventory_manager: InventoryManager = $"../../.."
@onready var header_button: TextureButton = $HeaderButton

var subinventory_contents : Array[Dictionary] = []
var empty_slot : Dictionary = {"" : 0}
var item_rects : Array[Panel] = []

func _ready() -> void:
	inventory_manager.subinventory_container.append(self)
	await initialize_subinventory_slots()
	await initialize_item_rects()
	await update_subinventory()

func initialize_subinventory_slots():
	for child in get_children():
		if child != header_button:
			child.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	
	for i in range(1, 30):
		subinventory_contents.append(empty_slot)
		var _new_inv_item_rect = INV_ITEM_RECT.instantiate()
		_new_inv_item_rect.hide()
		add_child(_new_inv_item_rect)

func initialize_item_rects():
	for child in get_children():
		if child is Panel:
			item_rects.append(child)

func update_item_rects():
	for i in subinventory_contents.size():
		var _item_in_slot = subinventory_contents[i]
		if _item_in_slot != empty_slot:
			var _item_rect = item_rects[i]
			var _item_id = _item_in_slot.keys()[0]
			_item_rect.set_inv_item_rect_variables(_item_id, _item_in_slot[_item_id])
			_item_rect.show()
		else:
			item_rects[i].hide()

func update_subinventory():
	if check_if_subinventory_empty():
		hide()
	else:
		show()

func check_if_subinventory_empty() -> bool:
	for i in subinventory_contents.size():
		if subinventory_contents[i] != empty_slot:
			return false
	
	return true

func add_item(_item_slot : int, _picked_up_item_id : String, _stack_size : int):
	var _new_item : Dictionary = {_picked_up_item_id : _stack_size}
	
	if subinventory_contents[_item_slot] == empty_slot:
		subinventory_contents[_item_slot] = _new_item
	elif subinventory_contents[_item_slot].has(_picked_up_item_id):
		var _cached_item_stack_size = subinventory_contents[_item_slot][_picked_up_item_id]
		subinventory_contents[_item_slot][_picked_up_item_id] = _cached_item_stack_size + _stack_size
	
	update_item_rects()
	update_subinventory()
