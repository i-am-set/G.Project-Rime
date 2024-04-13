extends Control

@onready var inventories_container = $"../../.."
@onready var subinventory : Control = get_parent()

var held_item_preview : Control
var subinventory_rects : Dictionary

var cached_position : Vector2
var item_center_offset : Vector2

func _ready():
	pass

func _process(delta):
	held_item_preview = inventories_container.held_item_preview
	item_center_offset = size * 0.5
	
	held_item_follow_mouse()

func _input(event):
	if event.is_action_pressed("mouse_click"):
		if held_item_preview.held_item != null:
			if held_item_preview.held_item == self:
				subinventory_rects = inventories_container.subinventory_rects
				inventories_container.set_subinventories()
				for subinventory in subinventory_rects.keys():
					if subinventory_rects[subinventory].has_point(held_item_preview.position + item_center_offset):
						subinventory.get_closest_cell_position_to_held_item()
						var _hovered_cell = subinventory.position_to_cell(subinventory.hovered_cell_position)
						if !subinventory.contents.has(_hovered_cell):
							drop_item()
						else:
							print("Slot taken")
		elif get_global_rect().has_point(get_global_mouse_position()) :
			pick_up_item()

func pick_up_item():
	held_item_preview.held_item = self
	cached_position = position
	held_item_preview.size = size
	held_item_preview.position = get_global_mouse_position() - item_center_offset # Move the held_item_preview to the mouse's position
	held_item_preview.show()

func drop_item():
	subinventory_rects = inventories_container.subinventory_rects
	
	held_item_preview.hide()
	
	# Check if the held_item_preview is within one of the inventory_rects
	inventories_container.set_subinventories()
	for key in subinventory_rects.keys():
		if subinventory_rects[key].has_point(held_item_preview.global_position + item_center_offset):
			drop_logic(key)
			return
	
	# failed to find an inventory_rect
	held_item_preview.held_item = null
	position = cached_position

func drop_logic(key : Control) -> void:
	var moved_item = self.duplicate()
	
	var drop_position = held_item_preview.global_position - key.global_position - item_center_offset
	moved_item.position = drop_position
	# Snap the center of the Control to the closest_cell_position
	var closest_cell_position = key.get_closest_cell_position(moved_item.position, moved_item.size)
	moved_item.position = closest_cell_position - item_center_offset
	
	key.add_child(moved_item)
	held_item_preview.held_item = null
	
	# Ensure the Control is within the parent's bounds
	if held_item_preview.position.x < subinventory_rects[key].position.x:
		moved_item.position.x = 0
	elif held_item_preview.position.x + held_item_preview.size.x > subinventory_rects[key].position.x + subinventory_rects[key].size.x:
		moved_item.position.x = subinventory_rects[key].size.x - moved_item.get_rect().size.x
	
	var previous_positions : Array[Vector2] = [position + item_center_offset]
	subinventory.remove_item(previous_positions)
	var new_positions : Array[Vector2] = [moved_item.position + moved_item.size * 0.5]
	key.add_item(moved_item, new_positions)
	self.queue_free()

func held_item_follow_mouse():
	if held_item_preview.held_item == self:
		held_item_preview.position = get_global_mouse_position() - item_center_offset  # Follow the mouse's x position
