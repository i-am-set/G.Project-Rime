extends ColorRect

@onready var inventories_container = $"../../.."
@onready var subinventory : Control = get_parent()

var held_item_preview : Control
var subinventory_rects : Dictionary

var cached_position : Vector2
var item_center : Vector2

func _ready():
	pass

func _process(delta):
	held_item_preview = inventories_container.held_item_preview
	item_center = held_item_preview.size * 0.5
	
	held_item_follow_mouse()

func _input(event):
	if event.is_action_pressed("mouse_click"):
		if held_item_preview.held_item != null:
			if held_item_preview.held_item == self:
				subinventory_rects = inventories_container.subinventory_rects
				inventories_container.set_subinventories()
				for subinventory in subinventory_rects.keys():
					if subinventory_rects[subinventory].has_point(held_item_preview.position + item_center):
						subinventory.get_closest_cell_position_to_held_item()
						print(subinventory.hovered_cell_position, "   ", subinventory.occupied_cell_positions)
						if !subinventory.occupied_cell_positions.has(subinventory.hovered_cell_position):
							drop_item()
						else:
							print("Slot taken")
		elif get_global_rect().has_point(get_global_mouse_position()) :
			pick_up_item()

func pick_up_item():
	held_item_preview.held_item = self
	cached_position = position
	subinventory.remove_occupied_cell_position(position + size * 0.5)
	position.y = -1000  # Move the ColorRect out of sight
	held_item_preview.size = size
	held_item_preview.position = get_global_mouse_position() - item_center # Move the held_item_preview to the mouse's position
	held_item_preview.show()

func drop_item():
	subinventory_rects = inventories_container.subinventory_rects
	
	held_item_preview.hide()
	
	# Check if the held_item_preview is within one of the inventory_rects
	inventories_container.set_subinventories()
	for key in subinventory_rects.keys():
		if subinventory_rects[key].has_point(held_item_preview.global_position + item_center):
			drop_logic(key)
			return
	
	# failed to find an inventory_rect
	held_item_preview.held_item = null
	position = cached_position

func drop_logic(key : Control) -> void:
	var moved_item = self.duplicate()
	
	var drop_position = held_item_preview.global_position - key.global_position - item_center
	moved_item.position = drop_position
	# Snap the center of the ColorRect to the closest_cell_position
	var closest_cell_position = key.get_closest_cell_position(moved_item.position, moved_item.size)
	moved_item.position = closest_cell_position - item_center
	
	key.add_child(moved_item)
	held_item_preview.held_item = null
	
	# Ensure the ColorRect is within the parent's bounds
	if held_item_preview.position.x < subinventory_rects[key].position.x:
		moved_item.position.x = 0
	elif held_item_preview.position.x + held_item_preview.size.x > subinventory_rects[key].position.x + subinventory_rects[key].size.x:
		moved_item.position.x = subinventory_rects[key].size.x - moved_item.get_rect().size.x
	
	key.add_occupied_cell_position(moved_item.position + moved_item.size * 0.5)
	self.queue_free()

func held_item_follow_mouse():
	if held_item_preview.held_item == self:
		held_item_preview.position = get_global_mouse_position() - item_center  # Follow the mouse's x position
