extends Control

@onready var fps_controller = $"../../.."
@onready var inventory_menu = $".."
@onready var held_item_preview = $"../held_item_preview"
@onready var tooltip = $"../Tooltip"
@onready var rmb_menu = $"../RmbMenu"
@onready var selector = $"../Selector"
@onready var subinventories_container = $subinventories

var subinventories : Array[Subinventory] = []

var held_item_reference = null
var held_item_subinventory : Control = null

var mouse_pos : Vector2

func _ready():
	HideHeldItemPreview()
	HideTooltip()
	HideRmbMenu()
	Console.create_command("give", self.c_give_item, "Quick adds the given item by ID into if space is available; Does nothing if no space.")

func _input(event):
	if Global.IS_IN_INVENTORY:
		if event is InputEventMouseMotion:
			ghost_preview_logic()
		
		if event.is_action_pressed("mouse_click"):
			handle_click(event, mouse_pos - global_position)
		
		if event.is_action_pressed("drop_item_one"):
			var _mouse_pos = mouse_pos - global_position
			for _subinventory in subinventories:
				if _subinventory.get_rect().has_point(_mouse_pos):
					var closest_cell_position_to_click = _subinventory.get_closest_cell_position(_mouse_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
					var closest_cell_to_click = _subinventory.position_to_cell(closest_cell_position_to_click)
					if _subinventory.is_space_occupied(closest_cell_to_click, Vector2.ONE):
						var _item = _subinventory.get_item_in_cell(closest_cell_to_click)
						_subinventory.drop_item_one(_item)
		elif event.is_action_pressed("drop_item_all"):
			var _mouse_pos = mouse_pos - global_position
			for _subinventory in subinventories:
				if _subinventory.get_rect().has_point(_mouse_pos):
					var closest_cell_position_to_click = _subinventory.get_closest_cell_position(_mouse_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
					var closest_cell_to_click = _subinventory.position_to_cell(closest_cell_position_to_click)
					if _subinventory.is_space_occupied(closest_cell_to_click, Vector2.ONE):
						var _item = _subinventory.get_item_in_cell(closest_cell_to_click)
						_subinventory.drop_item_all(_item)
		
		if event.is_action_pressed("rotate_held_item"):
			if held_item_preview.visible && held_item_reference != null:
				held_item_preview.is_rotated = !held_item_preview.is_rotated
				Input.warp_mouse(mouse_pos)

func _process(delta):
	mouse_pos = get_global_mouse_position()
	held_item_preview_follow_mouse()
	tooltip_follow_mouse()
	queue_redraw()

func _draw():
	var circle_radius = 2  # Adjust as needed
	var circle_color = Color(1, 0, 0)  # Red color
	
	#draw_circle(held_item_preview.global_position - global_position, 5, Color.PURPLE)
	draw_circle(get_global_mouse_position() - global_position, 3, Color.GREEN)
	
	#for _subinventory in subinventories:
		#var global_rect = _subinventory.get_rect()
		#var points = [
		#global_rect.position,
		#global_rect.position + Vector2(global_rect.size.x, 0),
		#global_rect.position + global_rect.size,
		#global_rect.position + Vector2(0, global_rect.size.y)
	#]
		#draw_polygon(points, [Color.PINK])

func handle_click(event, _click_pos : Vector2):
	if Global.IS_IN_INVENTORY:
		if event.is_action_pressed("left_mouse_click"):
			if rmb_menu.visible && !rmb_menu.get_rect().has_point(_click_pos + position):
				HideRmbMenu()
		elif event.is_action_pressed("right_mouse_click"):
			if rmb_menu.visible:
				HideRmbMenu()
		for _subinventory in subinventories:
			if _subinventory.get_rect().has_point(_click_pos):
				
				####################################################################################################
				if event.is_action_pressed("quick_move_item"):
					if held_item_reference != null:
						if _subinventory.try_quick_add_item(held_item_reference, held_item_reference["item_rect"].current_stack):
							held_item_subinventory.remove_item(held_item_reference)
							HideHeldItemPreview()
						else:
							print_debug("Subinventory full...")
					else:
						var closest_cell_position_to_click = _subinventory.get_closest_cell_position(_click_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
						var closest_cell_to_click = _subinventory.position_to_cell(closest_cell_position_to_click)
						
						if _subinventory.is_space_occupied(closest_cell_to_click, Vector2.ONE):
							var _item = _subinventory.get_item_in_cell(closest_cell_to_click)
							print_debug("Occupied! Trying to quick move ", _item["inv_item"].item_name, " ; Stack size is ", _item["item_rect"].current_stack)
							if _subinventory.try_quick_stack_transfer_item(_item, _item["item_rect"].current_stack):
								printerr("success")
							if _subinventory.try_quick_add_item(_item, _item["item_rect"].current_stack):
								_subinventory.remove_item(_item)
							else:
								print_debug("Failed... Subinventory full...")
						else:
							print_debug("Empty...")
				
				####################################################################################################
				elif event.is_action_pressed("left_mouse_click"):
					if held_item_reference != null:
						var drop_cell_position = _subinventory.get_closest_cell_position(held_item_preview.position - _subinventory.global_position)
						var drop_cell = _subinventory.position_to_cell(drop_cell_position)
						
						if _subinventory.try_add_item(held_item_reference, held_item_reference["item_rect"].current_stack, drop_cell, held_item_preview.is_rotated):
							held_item_subinventory.remove_item(held_item_reference)
							HideHeldItemPreview()
						else:
							print_debug("Space occupied.")
					else:
						var closest_cell_position_to_click = _subinventory.get_closest_cell_position(_click_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
						var closest_cell_to_click = _subinventory.position_to_cell(closest_cell_position_to_click)
						
						if _subinventory.is_space_occupied(closest_cell_to_click, Vector2.ONE):
							var _item = _subinventory.get_item_in_cell(closest_cell_to_click)
							var _inv_item = _item["inv_item"]
							print_debug("Occupied! Picking up ", _inv_item.item_name, " ; Stack size is ", _item["item_rect"].current_stack)
							held_item_reference = _item
							held_item_subinventory = _subinventory
							held_item_preview.set_preview_size(Vector2(_inv_item.item_width, _inv_item.item_height))
							held_item_preview.set_preview_stack_label(_item["item_rect"].current_stack)
							ShowHeldItemPreview()
						else:
							print_debug("Empty...")
				
				####################################################################################################
				elif event.is_action_pressed("right_mouse_click"):
					if held_item_reference != null:
						var _drop_cell_position = _subinventory.get_closest_cell_position(held_item_preview.position - _subinventory.global_position)
						var _drop_cell = _subinventory.position_to_cell(_drop_cell_position)
						if _subinventory.get_item_in_cell(_drop_cell) != held_item_reference:
							if held_item_reference["item_rect"].current_stack > 1:
									_subinventory.split_item_one(held_item_reference, _drop_cell, held_item_preview.is_rotated)
									held_item_preview.set_preview_stack_label(held_item_reference["item_rect"].current_stack)
							else:
								if _subinventory.try_add_item(held_item_reference, held_item_reference["item_rect"].current_stack, _drop_cell, held_item_preview.is_rotated):
									held_item_subinventory.remove_item(held_item_reference)
									HideHeldItemPreview()
								else:
									print_debug("Space occupied.")
					else:
						var closest_cell_position_to_click = _subinventory.get_closest_cell_position(_click_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
						var closest_cell_to_click = _subinventory.position_to_cell(closest_cell_position_to_click)
						if _subinventory.is_space_occupied(closest_cell_to_click, Vector2.ONE):
							var _item = _subinventory.get_item_in_cell(closest_cell_to_click)
							ShowRmbMenu(_item)
				
				####################################################################################################
				elif event.is_action_pressed("middle_mouse_click"):
					if held_item_reference != null:
						var _drop_cell_position = _subinventory.get_closest_cell_position(held_item_preview.position - _subinventory.global_position)
						var _drop_cell = _subinventory.position_to_cell(_drop_cell_position)
						if _subinventory.get_item_in_cell(_drop_cell) != held_item_reference:
							if held_item_reference["item_rect"].current_stack > 1:
									_subinventory.split_item_half(held_item_reference, _drop_cell, held_item_preview.is_rotated)
									held_item_preview.set_preview_stack_label(held_item_reference["item_rect"].current_stack)
							else:
								if _subinventory.try_add_item(held_item_reference, held_item_reference["item_rect"].current_stack, _drop_cell, held_item_preview.is_rotated):
									held_item_subinventory.remove_item(held_item_reference)
									HideHeldItemPreview()
								else:
									print_debug("Space occupied.")
					else:
						var closest_cell_position_to_click = _subinventory.get_closest_cell_position(_click_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
						var closest_cell_to_click = _subinventory.position_to_cell(closest_cell_position_to_click)
						
						if _subinventory.is_space_occupied(closest_cell_to_click, Vector2.ONE):
							var _item = _subinventory.get_item_in_cell(closest_cell_to_click)
							var _inv_item = _item["inv_item"]
							print_debug("Occupied! Picking up ", _inv_item.item_name, " ; Stack size is ", _item["item_rect"].current_stack)
							held_item_reference = _item
							held_item_subinventory = _subinventory
							held_item_preview.set_preview_size(Vector2(_inv_item.item_width, _inv_item.item_height))
							held_item_preview.set_preview_stack_label(_item["item_rect"].current_stack)
							ShowHeldItemPreview()
						else:
							print_debug("Empty...")
				
				####################################################################################################
				# Update grid of subinventory that was clicked in
				_subinventory.update_grid()

func set_subinventories():
	subinventories = get_subinventories()

func get_subinventories(node = null) -> Array[Subinventory]:
	if node == null:
		node = subinventories_container
	var _node_children = node.get_children()
	
	var _subinventories : Array[Subinventory] = []
	for child in _node_children:
		if child is Subinventory:
			_subinventories.append(child)
		else:
			_subinventories += get_subinventories(child)
	
	return _subinventories

func add_subinventory(_subinventory : Control):
	subinventories_container.add_child(_subinventory)

func ShowHeldItemPreview():
	held_item_preview.display.texture = held_item_reference["item_rect"].display.texture
	held_item_preview.is_rotated = held_item_reference["rotated"]
	held_item_preview.show()

func HideHeldItemPreview():
	held_item_preview.hide()
	held_item_reference = null
	held_item_subinventory = null

func ShowTooltip(_inv_item : InventoryItem):
	tooltip.inv_item = _inv_item
	tooltip.show()

func HideTooltip():
	tooltip.hide()

func ShowRmbMenu(_item : Dictionary):
	rmb_menu.position = mouse_pos
	rmb_menu.right_clicked_item_ref = _item
	rmb_menu.inv_item = _item["inv_item"]
	rmb_menu.show()

func HideRmbMenu():
	rmb_menu.hide()

func held_item_preview_follow_mouse():
	if held_item_reference != null:
		# Adjust pivot based on rotation
		var offset = Vector2()
		if !held_item_preview.is_rotated:
			offset = Vector2(held_item_reference["inv_item"].item_width, held_item_reference["inv_item"].item_height) * Global.INV_CELL_SIZE * 0.5
		else:
			offset = Vector2(held_item_reference["inv_item"].item_height, held_item_reference["inv_item"].item_width) * Global.INV_CELL_SIZE * 0.5
		held_item_preview.position = get_global_mouse_position() - offset

func tooltip_follow_mouse():
	tooltip.position = mouse_pos

func try_to_pick_up_item(_picked_up_item : InventoryItem, _stack_size : int) -> Control:
	var _new_item : Dictionary = {"inv_item" : _picked_up_item}
	
	for _subinventory in subinventories:
		if _subinventory.try_quick_add_item(_new_item, _stack_size):
			return _subinventory
	
	return null

func ghost_preview_logic():
	var _mouse_pos = mouse_pos - global_position
	for _subinventory in subinventories:
		if _subinventory.get_rect().has_point(_mouse_pos):
			if held_item_reference != null:
				var closest_cell_position = _subinventory.get_closest_cell_position(held_item_preview.position - _subinventory.global_position)
				var closest_cell = _subinventory.position_to_cell(closest_cell_position)
				selector.size = held_item_reference["item_rect"].size
				selector.get_child(0).rotation_degrees = held_item_preview.display.rotation_degrees
				selector.get_child(0).pivot_offset = held_item_preview.display.pivot_offset
				selector.position = closest_cell_position + _subinventory.global_position
			else:
				var closest_cell_position = _subinventory.get_closest_cell_position(_mouse_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
				var closest_cell = _subinventory.position_to_cell(closest_cell_position)
				if _subinventory.is_space_occupied(closest_cell, Vector2.ONE):
					var _item = _subinventory.get_item_in_cell(closest_cell)
					if _item != null:
						var _inv_item = _item["inv_item"]
						selector.size = _item["item_rect"].size
						selector.get_child(0).rotation_degrees = _item["item_rect"].display.rotation_degrees
						selector.get_child(0).pivot_offset = held_item_preview.get_correct_pivot(Vector2(_inv_item.item_width, _inv_item.item_height))
						selector.position = _subinventory.cell_to_position(_item["cell"]) + _subinventory.global_position
				else:
					selector.size = Global.INV_CELL_SIZE
					selector.rotation_degrees = 0
					selector.get_child(0).pivot_offset = Global.INV_CELL_SIZE * 0.5
					selector.position = closest_cell_position + _subinventory.global_position

func c_give_item(item_id: String, number_of_item: int = 1) -> void:
	var new_item = StaticData.create_item_from_id(item_id)
	var items_added := 0
	var items_ignored := 0
	var inventory_destinations := {}
	
	Console.print_line("Trying to give %d '[color=GOLD]%s[/color]'..." % [number_of_item, new_item.item_name])
	
	for i in range(number_of_item):
		await get_tree().process_frame
		var _inventory_destination = try_to_pick_up_item(new_item, 1)
		
		if _inventory_destination != null:
			items_added += 1
			if _inventory_destination.name in inventory_destinations:
				inventory_destinations[_inventory_destination.name] += 1
			else:
				inventory_destinations[_inventory_destination.name] = 1
		else:
			items_ignored += 1
	
	# Printing messages for items placed in inventories
	if items_added > 0:
		for key in inventory_destinations.keys():
			Console.print_line("Placed [color=LIGHT_GREEN]" + str(inventory_destinations[key]) + "[/color] '[color=GOLD]" + new_item.item_name + "[/color]' in [color=SKY_BLUE]'" + key + "'[/color].")
	
	# Printing message for dropped items
	if items_ignored > 0:
		Console.print_line("Ignored [color=LIGHT_CORAL]%d[/color] '[color=GOLD]%s[/color]'." % [items_ignored, new_item.item_name])

