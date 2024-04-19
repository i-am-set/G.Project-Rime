extends Control

@onready var fps_controller = $"../../.."
@onready var inventory_menu = $".."
@onready var held_item_preview = $"../held_item_preview"
@onready var tooltip = $"../Tooltip"
@onready var rmb_menu = $"../RmbMenu"
@onready var subinventories_container = $subinventories

var subinventories : Array = [] :
	get:
		subinventories.clear()
		return subinventories_container.get_children()

var held_item_reference = null
var held_item_subinventory : Control = null

var mouse_pos : Vector2

func _ready():
	HideTooltip()
	HideRmbMenu()
	Console.create_command("give", self.c_give_item, "Quick adds the given item by ID into if space is available; Does nothing if no space.")

func _input(event):
	if event.is_action_pressed("mouse_click"):
		handle_click(event, get_global_mouse_position() - global_position)

func _process(delta):
	mouse_pos = get_global_mouse_position()
	tooltip_follow_mouse()
	held_item_follow_mouse()
	queue_redraw()

func _draw():
	var circle_radius = 2  # Adjust as needed
	var circle_color = Color(1, 0, 0)  # Red color
	
	#draw_circle(get_closest_cell_position(held_item_preview.global_position - global_position), 5, Color.RED)
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
				if event.is_action_pressed("left_mouse_click"):
					if held_item_reference != null:
						var drop_cell_position = _subinventory.get_closest_cell_position(held_item_preview.position - _subinventory.global_position)
						var drop_cell = _subinventory.position_to_cell(drop_cell_position)
						if _subinventory.try_add_item(held_item_reference["item"], held_item_reference["item_rect"].current_stack, drop_cell):
							held_item_subinventory.remove_item(held_item_reference)
							HideHeldItemPreview()
						else:
							print_debug("Space occupied.")
					else:
						var closest_cell_position_to_click = _subinventory.get_closest_cell_position(_click_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
						var closest_cell_to_click = _subinventory.position_to_cell(closest_cell_position_to_click)
						print(_subinventory.name, closest_cell_to_click)
						
						if _subinventory.is_space_occupied(closest_cell_to_click, Vector2.ONE):
							var _item = _subinventory.get_item_in_cell(closest_cell_to_click)
							var _inv_item = _item["item"]
							print("Occupied! Picking up ", _inv_item.item_name, " ; Stack size is ", _item["item_rect"].current_stack)
							held_item_reference = _item
							held_item_subinventory = _subinventory
							held_item_preview.set_preview_size(Vector2(_inv_item.item_width, _inv_item.item_height))
							held_item_preview.show()
						else:
							print("Empty...")
				elif event.is_action_pressed("right_mouse_click"):
					var closest_cell_position_to_click = _subinventory.get_closest_cell_position(_click_pos - _subinventory.position - Global.INV_CELL_SIZE * 0.5)
					var closest_cell_to_click = _subinventory.position_to_cell(closest_cell_position_to_click)
					if _subinventory.is_space_occupied(closest_cell_to_click, Vector2.ONE):
						var _item = _subinventory.get_item_in_cell(closest_cell_to_click)
						ShowRmbMenu(_item)

func add_subinventory(_subinventory : Control):
	subinventories_container.add_child(_subinventory)

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
	rmb_menu.inv_item = _item["item"]
	rmb_menu.show()

func HideRmbMenu():
	rmb_menu.hide()

func held_item_follow_mouse():
	if held_item_reference != null:
		held_item_preview.position = get_global_mouse_position() - Vector2(held_item_reference["item"].item_width, held_item_reference["item"].item_height) * Global.INV_CELL_SIZE * 0.5 # Follow the mouse's x position

func tooltip_follow_mouse():
	tooltip.position = mouse_pos

func try_to_pick_up_item(_picked_up_item : InventoryItem, _stack_size : int) -> Control:
	for _subinventory in subinventories:
		if _subinventory.try_quick_add_item(_picked_up_item, _stack_size):
			return _subinventory
	
	return null

func c_give_item(item_id: String, number_of_item: int = 1) -> void:
	var new_item = StaticData.create_item_from_id(item_id)
	var items_added := 0
	var items_ignored := 0
	var inventory_destinations := {}
	
	for i in range(number_of_item):
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


