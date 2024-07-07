extends Control
class_name SubinventoryManager

const INV_ITEM_RECT = preload("res://scenes/ui/inv_item_rect.tscn")

@onready var inventory_manager: InventoryManager = $"../../.."
#@onready var subinventory_name_label = $HeaderButton/Label
#@onready var capacity_label = $HeaderButton/CapacityLabel

#@export var capacity_color_normal: Color = Color(1, 1, 1)
#@export var capacity_color_almost_full: Color = Color(1, 0.5, 0.5)
#@export var capacity_color_full: Color = Color(1, 0, 0)
#@export var full_capacity_threshhold : float = 0.8
#@export var subinventory_capacity : int = 10
#var subinventory_quantity_held : int = 0
var subinventory_slot_amount : int = 999

var subinventory_contents : Array[InventoryItem] = []
#var item_rects : Array[Panel] = []

func _ready() -> void:
	await initialize_subinventory()

func initialize_subinventory():
	await update_item_rects()
	await update_subinventory()
	#subinventory_name_label.text = name

func remove_all_item_rects():
	var _old_inv_children = get_children()
	for _old_inv_item in _old_inv_children:
		remove_child(_old_inv_item)
		_old_inv_item.queue_free()

#func initialize_item_rects():
	#for child in items_container.get_children():
		#if child is InvItemRect:
			#item_rects.append(child)

func update_item_rects():
	remove_all_item_rects()
	for _inv_item in subinventory_contents:
		create_inv_item_rect(_inv_item)

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

func drop_ground_item_backend(_dropped_item_id : String, _stack_amount : int):
	var player = inventory_manager.fps_controller
	player.drop_ground_item(_dropped_item_id, _stack_amount)

func check_if_subinventory_empty() -> bool:
	if get_child_count() == 0:
		return true
	else:
		return false

func create_inv_item_rect(_inv_item : InventoryItem):
	var _new_inv_item_rect = INV_ITEM_RECT.instantiate()
	_new_inv_item_rect.set_item_icon(Global.ITEM_ICONS[_inv_item.item_id])
	add_child(_new_inv_item_rect)

func add_item(_picked_up_item : InventoryItem):
	subinventory_contents.append(_picked_up_item)
	
	create_inv_item_rect(_picked_up_item)
	#var _picked_up_item_weight : int = _picked_up_item.get_item_weight()
	
	#inventory_manager.update_weight(inventory_manager.weight_current + _picked_up_item_weight)
	
	update_item_rects()
	update_subinventory()

#func remove_item(_item_slot : int, _remove_amount : int):
	#var _item_to_be_removed = subinventory_contents[_item_slot]
	#var _removed_item_weight : float = StaticData.item_data[_item_to_be_removed[0]]["item_weight"] * _remove_amount
	#
	#if _item_to_be_removed != empty_slot:
		#_item_to_be_removed[1] -= _remove_amount
	#else:
		#printerr("Item slot is empty, can't remove. Item slot ", _item_slot, " in ", name, ".")
		#return
	#
	#inventory_manager.update_weight(inventory_manager.weight_current - _removed_item_weight)
	#
	#if _item_to_be_removed[1] < 1:
		#subinventory_contents[_item_slot] = empty_slot
		#item_rects[_item_slot].hide()
	#
	#update_item_rects()
	#update_subinventory()

#func drop_item_one(_item_slot : int, _item : Array):
	#remove_item(_item_slot, 1)
	#
	#drop_ground_item_backend(_item[0], 1)
	#
	#update_item_rects()
	#update_subinventory()
#
#func drop_item_all(_item_slot : int, _item : Array):
	#var _cached_item_stack_amount : int = _item[1]
	#
	#remove_item(_item_slot, _cached_item_stack_amount)
	#
	#drop_ground_item_backend(_item[0], _cached_item_stack_amount)
	##
	##update_grid()
	#
	#update_item_rects()
	#update_subinventory()
