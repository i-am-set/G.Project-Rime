extends Control
class_name SubinventoryManager

const INV_ITEM_RECT = preload("res://scenes/ui/inv_item_rect.tscn")

@onready var inventory_manager: InventoryManager = $"../.."
@onready var header_button: TextureButton = $HeaderButton
@onready var items_container = $ItemsContainer
#@onready var subinventory_name_label = $HeaderButton/Label
#@onready var capacity_label = $HeaderButton/CapacityLabel

#@export var capacity_color_normal: Color = Color(1, 1, 1)
#@export var capacity_color_almost_full: Color = Color(1, 0.5, 0.5)
#@export var capacity_color_full: Color = Color(1, 0, 0)
#@export var full_capacity_threshhold : float = 0.8
#@export var subinventory_capacity : int = 10
#var subinventory_quantity_held : int = 0
var subinventory_slot_amount : int = 999

var subinventory_contents : Array[Dictionary] = []
var empty_slot : Dictionary = {"" : 0}
var item_rects : Array[Panel] = []

func _ready() -> void:
	await initialize_subinventory()

func initialize_subinventory():
	await initialize_subinventory_slots()
	await initialize_item_rects()
	await update_subinventory()
	#subinventory_name_label.text = name

func initialize_subinventory_slots():
	for child in items_container.get_children():
		child.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	
	for i in subinventory_slot_amount:
		subinventory_contents.append(empty_slot)
		var _new_inv_item_rect = INV_ITEM_RECT.instantiate()
		_new_inv_item_rect.hide()
		items_container.add_child(_new_inv_item_rect)

func initialize_item_rects():
	for child in items_container.get_children():
		if child is InvItemRect:
			item_rects.append(child)

func update_item_rects():
	for i in subinventory_slot_amount:
		var _item_in_slot = subinventory_contents[i]
		if _item_in_slot != empty_slot:
			var _item_rect = item_rects[i]
			var _item_id = _item_in_slot.keys()[0]
			_item_rect.set_inv_item_rect_variables(_item_id, _item_in_slot[_item_id])
			_item_rect.show()
		else:
			item_rects[i].hide()

func update_subinventory():
	#var is_empty : bool = check_if_subinventory_empty()
	#if is_empty && items_container.visible:
		#items_container.hide()
	#elif !is_empty && !items_container.visible:
		#items_container.show()
	#
	#capacity_label.text = "%d/%d" %[subinventory_quantity_held, subinventory_capacity]
	#
	#var capacity_used_percentage : float = float(subinventory_quantity_held) / float(subinventory_capacity)
	#if capacity_used_percentage >= 1.0:
		#capacity_label.modulate = capacity_color_full
	#elif capacity_used_percentage >= full_capacity_threshhold:
		#capacity_label.modulate = capacity_color_almost_full
	#else:
		#capacity_label.modulate = capacity_color_normal
	pass

func check_if_subinventory_empty() -> bool:
	for i in subinventory_slot_amount:
		if subinventory_contents[i] != empty_slot:
			return false
	
	return true

func add_item(_item_slot : int, _picked_up_item_id : String, _stack_size : int):
	var _new_item : Dictionary = {_picked_up_item_id : _stack_size}
	var _picked_up_item_weight : int = StaticData.item_data[_picked_up_item_id]["item_weight"] * _stack_size
	
	if subinventory_contents[_item_slot] == empty_slot:
		subinventory_contents[_item_slot] = _new_item
	elif subinventory_contents[_item_slot].has(_picked_up_item_id):
		var _cached_item_stack_size = subinventory_contents[_item_slot][_picked_up_item_id]
		subinventory_contents[_item_slot][_picked_up_item_id] = _cached_item_stack_size + _stack_size
	else:
		printerr("Item slot is already occupied. Item slot ", _item_slot, " in ", name, ".")
		return
	
	inventory_manager.update_weight(inventory_manager.weight_current + _picked_up_item_weight)
	
	update_item_rects()
	update_subinventory()
