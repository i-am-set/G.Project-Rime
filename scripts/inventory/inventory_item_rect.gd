extends ColorRect


@onready var inventories_container = $"../../.."
var held_item_preview : Control
var held_item_preview_center : Vector2

var base_speed = 50  # Base speed in pixels per second
var acceleration = 2000  # Acceleration in pixels per second per second
var speed = base_speed  # Current speed
var is_held = false  # Whether the ColorRect is being held
var cached_position : Vector2

func _ready():
	pass

func _input(event):
	if event.is_action_pressed("mouse_click") and get_global_rect().has_point(get_global_mouse_position()):
		is_held = true
		cached_position = position
		position.y = -1000  # Move the ColorRect out of sight
		held_item_preview.show()
		held_item_preview.position = get_global_mouse_position() - held_item_preview_center # Move the held_item_preview to the mouse's position
	if event.is_action_released("mouse_click") && is_held:
		var subinventory_rects = inventories_container.subinventory_rects
		var held_item_preview_center_global_pos = held_item_preview.get_rect().position - held_item_preview_center
		held_item_preview.hide()
		
		# Check if the held_item_preview is within one of the inventory_rects
		inventories_container.set_subinventories()
		for key in subinventory_rects.keys():
			if subinventory_rects[key].has_point(held_item_preview.global_position + held_item_preview_center):
				var moved_item = self.duplicate()
				var drop_position = held_item_preview.global_position - key.global_position
				moved_item.position = drop_position
				key.add_child(moved_item)
				
				moved_item.is_held = false
				# Ensure the ColorRect is within the parent's bounds
				if held_item_preview.position.x < subinventory_rects[key].position.x:
					moved_item.position.x = 0
				elif held_item_preview.position.x + held_item_preview.size.x > subinventory_rects[key].position.x + subinventory_rects[key].size.x:
					moved_item.position.x = subinventory_rects[key].position.x + subinventory_rects[key].size.x - moved_item.get_rect().size.x
				get_parent().remove_child(self)
				self.queue_free()
				return
		# failed to find an inventory
		is_held = false
		position = cached_position

func _process(delta):
	print(position)
	held_item_preview = inventories_container.held_item_preview
	held_item_preview_center = held_item_preview.get_rect().size * 0.5
	
	if is_held:
		held_item_preview.position = get_global_mouse_position() - held_item_preview_center  # Follow the mouse's x position
	else:
		var new_position = position
		new_position.y += speed * delta  # Move down

		# Don't move past parent's bottom bound
		if new_position.y > get_parent().get_rect().size.y - get_rect().size.y:
			new_position.y = get_parent().get_rect().size.y - get_rect().size.y
			speed = base_speed  # Reset speed

		for sibling in get_parent().get_children():
			if sibling == self:
				continue
			if new_position.y < sibling.position.y + sibling.get_rect().size.y and new_position.y + get_rect().size.y > sibling.position.y:
				if new_position.x < sibling.position.x + sibling.get_rect().size.x and new_position.x + get_rect().size.x > sibling.position.x:
					new_position.y = sibling.position.y - get_rect().size.y
					speed = base_speed  # Reset speed

		position = new_position

		# Accelerate
		speed += acceleration * delta
