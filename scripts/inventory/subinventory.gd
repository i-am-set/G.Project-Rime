extends Control
class_name Subinventory

const ITEM_RECT = preload("res://scenes/ui/item_rect.tscn")


@export var inventory : Control
@export var rows : int = 2
@export var columns : int = 2

var inventory_cells : Array = [] # Stores cell coordinate
var items : Array[Dictionary] = [] # Stores item data and positions

func _ready():
	Global.inv_cell_size_updated.connect(update_grid)
	set_up_cell_grid()
	update_grid()

func _draw():
	if Global.IS_IN_INVENTORY:
			# Fetch the inter-cell spacing from a global configuration or directly define here
		var cell_width = Global.INV_CELL_SIZE.x
		var cell_height = Global.INV_CELL_SIZE.y
		
		# Draw vertical lines for columns
		for i in range(columns + 1):
			var x = i * cell_width
			draw_line(Vector2(x, 0), Vector2(x, rows * cell_height), Color(1, 1, 1))
		
		# Draw horizontal lines for rows
		for j in range(rows + 1):
			var y = j * cell_height
			draw_line(Vector2(0, y), Vector2(columns * cell_width, y), Color(1, 1, 1))

		#var circle_radius = 2  # Adjust as needed
		#var circle_color = Color(1, 0, 0)  # Red color
		#
		#var closest_cell_position_to_preview = get_closest_cell_position(inventory.held_item_preview.global_position - global_position)
#
		#draw_circle(closest_cell_position_to_preview + (Global.INV_CELL_SIZE * 0.5), 5, Color.RED)
		#
		#draw_line(Vector2(0,0), Vector2(columns*Global.INV_CELL_SIZE.x, 0), circle_color, 4)
		#draw_line(Vector2(columns*Global.INV_CELL_SIZE.x, 0), Vector2(columns*Global.INV_CELL_SIZE.x, rows*Global.INV_CELL_SIZE.y), circle_color, 4)
		#draw_line(Vector2(columns*Global.INV_CELL_SIZE.x, rows*Global.INV_CELL_SIZE.y), Vector2(0, rows*Global.INV_CELL_SIZE.y), circle_color, 4)
		#draw_line(Vector2(0, rows*Global.INV_CELL_SIZE.y), Vector2(0,0), circle_color, 4)
		#
		#for _cell in inventory_cells:
			#draw_circle(cell_to_position(_cell) + (Global.INV_CELL_SIZE * 0.5), circle_radius, circle_color)

func update_grid():
	set_up_cell_grid()
	for _item in items:
		var _item_rect = _item["item_rect"]
		_item_rect.display.texture = _item["inv_item"].item_image
		_item_rect.position = cell_to_position(_item["cell"])
		if inventory.held_item_subinventory == self:
			if _item == inventory.held_item_reference:
				_item_rect.highlight_item_display(true)
		else:
			_item_rect.highlight_item_display(false)

func set_up_cell_grid():
	var cell_size = Global.INV_CELL_SIZE
	var cell_number = 1
	
	# Set up the grid based on the default cell size
	custom_minimum_size = Global.INV_CELL_SIZE * Vector2(columns, rows)
	
	# Set up the inventory size
	inventory_cells.clear()
	for i in range(rows):
		for j in range(columns):
			var _cell = Vector2(j, i)
			inventory_cells.append(_cell)

func get_closest_cell_position(input_position):
	var closest_distance = INF
	var closest_cell_position
	for _cell in inventory_cells:
		var distance = input_position.distance_squared_to(cell_to_position(_cell))
		if distance < closest_distance:
			closest_distance = distance
			closest_cell_position = cell_to_position(_cell)
	return closest_cell_position

func position_to_cell(_pos : Vector2) -> Vector2:
	return _pos / Global.INV_CELL_SIZE

func cell_to_position(_cell : Vector2) -> Vector2:
	return _cell * Global.INV_CELL_SIZE

func get_rotation_vector(_item : InventoryItem, _rotated : bool) -> Vector2:
	if !_rotated:
		return Vector2(_item.item_width, _item.item_height)
	else:
		return Vector2(_item.item_height, _item.item_width)

func get_stackable_items(_dropped_item : InventoryItem, _stack_size : int, _drop_cell : Vector2, _item_size : Vector2):
	var cells_to_occupy = get_occupied_cells(_drop_cell, _item_size)
	
	# Check if space for an item is free
	for _item in items:
		if _item != inventory.held_item_reference:
			if _item["inv_item"].item_id == _dropped_item.item_id:
				for _cell in cells_to_occupy:
					var _occupied_cells = get_occupied_cells(_item["cell"], Vector2(_item["inv_item"].item_width, _item["inv_item"].item_height))
					if _cell in _occupied_cells:
						if _item["item_rect"].current_stack + _stack_size <= _item["inv_item"].stack_size:
							print_debug(_cell, " is stackable!")
							return _item
						else:
							print_debug(_cell, " is stackable, but full...")
							return null
	return null

func try_stack_transfer(_dropped_item : Dictionary, _dropped_stack_size : int, _drop_cell : Vector2, _item_size : Vector2):
	var cells_to_occupy = get_occupied_cells(_drop_cell, _item_size)
	
	# Check if space for an item is free
	for _item in items:
		if _item != _dropped_item:
			var _inv_item = _item["inv_item"]
			var _item_rect = _item["item_rect"]
			
			if _inv_item.item_id == _dropped_item["inv_item"].item_id:
				for _cell in cells_to_occupy:
					var _occupied_cells = get_occupied_cells(_item["cell"], Vector2(_inv_item.item_width, _inv_item.item_height))
					if _cell in _occupied_cells:
						var total_amount_transfering = _dropped_stack_size + _item_rect.current_stack
						
						if _item_rect.current_stack < _inv_item.stack_size && total_amount_transfering > _inv_item.stack_size && _dropped_stack_size >= _item_rect.current_stack:
							_dropped_item["item_rect"].current_stack = total_amount_transfering -_inv_item.stack_size
							_item_rect.current_stack = _inv_item.stack_size
							print_debug(_cell, " stack transfered!")
							return true
						else:
							printerr("Logic failed!")
	return false

func is_space_occupied(_drop_cell : Vector2, _item_shape : Vector2):
	var cells_to_occupy = get_occupied_cells(_drop_cell, _item_shape)
	
	# Check if any cell is outside the bounds of the inventory grid
	for cell in cells_to_occupy:
		if cell.x >= columns or cell.y >= rows or cell.x < 0 or cell.y < 0:
			print_debug("Exceeds the bounds of the inventory...")
			return true
	
	# Check if space for an item is free
	for _item in items:
		if _item != inventory.held_item_reference:
			for _cell in cells_to_occupy:
				var _item_rotation_vector : Vector2 = get_rotation_vector(_item["inv_item"], _item["rotated"])
				
				var _occupied_cells = get_occupied_cells(_item["cell"], _item_rotation_vector)
				if _cell in _occupied_cells:
					print_debug(_cell, " is occupied...")
					return true
	return false

func get_occupied_cells(_starting_cell : Vector2, _item_size : Vector2) -> Array:
	var occupied_cells = Array()
	for x in range(_item_size.x):
		for y in range(_item_size.y):
			occupied_cells.append(_starting_cell + Vector2(x, y))
	return occupied_cells

func get_item_in_cell(_cell : Vector2):
	for _item in items:
		var _item_rotation_vector : Vector2 = get_rotation_vector(_item["inv_item"], _item["rotated"])
		
		var _occupied_cells = get_occupied_cells(_item["cell"], _item_rotation_vector)
		if _cell in _occupied_cells:
			return _item
	
	return null

func can_add_item(_item : InventoryItem, _drop_cell : Vector2, _rotated : bool) -> bool:
	var _rotation_vector : Vector2 = get_rotation_vector(_item, _rotated)
	
	if is_space_occupied(_drop_cell, _rotation_vector):
		return false
	return true

func can_stack_item(_item : Dictionary, _stack_size : int, _drop_cell : Vector2, _rotated : bool) -> bool:
	var _item_rotation_vector : Vector2 = get_rotation_vector(_item["inv_item"], _rotated)
	
	if get_stackable_items(_item["inv_item"], _stack_size, _drop_cell, _item_rotation_vector) != null:
		return true
	return false

func try_quick_stack_transfer_item(_item : Dictionary, _stack_size : int) -> bool:
	var _inv_item = _item["inv_item"]
	
	for _cell in inventory_cells:
		var _item_in_cell = get_item_in_cell(_cell)
		if _item_in_cell != null:
			if _item_in_cell != _item:
				if try_stack_transfer(_item, _stack_size, _cell, Vector2(_inv_item.item_width, _inv_item.item_height)):
					return true
	
	return false

func try_quick_add_item(_item : Dictionary, _stack_size : int) -> bool:
	var _inv_item = _item["inv_item"]
	
	for _cell in inventory_cells:
		if get_item_in_cell(_cell) != _item:
			if get_stackable_items(_inv_item, _stack_size, _cell, get_rotation_vector(_item["inv_item"], false)) != null: # not rotated
				try_add_item(_item, _stack_size, _cell, false)
				update_grid()
				return true
			if get_stackable_items(_inv_item, _stack_size, _cell, get_rotation_vector(_item["inv_item"], true)) != null: # rotated
				try_add_item(_item, _stack_size, _cell, true)
				update_grid()
				return true
	for _cell in inventory_cells:
		if !is_space_occupied(_cell, get_rotation_vector(_item["inv_item"], false)): # not rotated
			try_add_item(_item, _stack_size, _cell, false)
			update_grid()
			return true
		if !is_space_occupied(_cell, get_rotation_vector(_item["inv_item"], true)): # rotated
			try_add_item(_item, _stack_size, _cell, true)
			update_grid()
			return true
	
	return false

func try_quick_split_item_stack(_item : Dictionary, _new_stack_size : int) -> bool:
	var _inv_item = _item["inv_item"]
	
	for _cell in inventory_cells:
		if !is_space_occupied(_cell, get_rotation_vector(_item["inv_item"], false)): # not rotated
			add_new_item_backend(_inv_item, _new_stack_size, _cell, false)
			update_grid()
			return true
		if !is_space_occupied(_cell, get_rotation_vector(_item["inv_item"], true)): # rotated
			add_new_item_backend(_inv_item, _new_stack_size, _cell, true)
			update_grid()
			return true
	
	return false

func try_split_item_stack(_item : Dictionary, _new_stack_size : int, _drop_cell : Vector2, _rotated : bool) -> bool:
	var _inv_item = _item["inv_item"]
	
	if can_stack_item(_item, _new_stack_size, _drop_cell, _rotated):
		var _item_rotation_vector : Vector2 = get_rotation_vector(_item["inv_item"], _item["rotated"])
		
		var _stackable_item : Dictionary = get_stackable_items(_inv_item, _new_stack_size, _drop_cell, _item_rotation_vector)
		_stackable_item["item_rect"].current_stack += _new_stack_size
		return true
	
	if !can_add_item(_inv_item, _drop_cell, _rotated):
		return false
	
	add_new_item_backend(_inv_item, _new_stack_size, _drop_cell, _rotated)
	update_grid()
	return true
	
	return false

func try_add_item(_item : Dictionary, _stack_size : int, _drop_cell : Vector2, _rotated : bool) -> bool:
	var _inv_item = _item["inv_item"]
	var _item_rotation_vector : Vector2 = get_rotation_vector(_item["inv_item"], _rotated)
	
	if can_stack_item(_item, _stack_size, _drop_cell, _rotated):
		var _stackable_item : Dictionary = get_stackable_items(_inv_item, _stack_size, _drop_cell, _item_rotation_vector)
		_stackable_item["item_rect"].current_stack += _stack_size
		return true
	
	if try_stack_transfer(_item, _stack_size, _drop_cell, _item_rotation_vector):
		inventory.held_item_preview.set_preview_stack_label(inventory.held_item_reference["item_rect"].current_stack)
		return false
	
	if !can_add_item(_inv_item, _drop_cell, _rotated):
		return false
	
	add_new_item_backend(_inv_item, _stack_size, _drop_cell, _rotated)
	update_grid()
	return true

func add_new_item_backend(_inv_item : InventoryItem, _stack_size : int, _cell : Vector2, _rotated : bool):
	var new_item = ITEM_RECT.instantiate()
	new_item.inv_item = _inv_item
	new_item.current_stack = _stack_size
	new_item.position = cell_to_position(_cell)
	new_item.is_rotated = _rotated
	add_child(new_item)
	append_item_to_items(_inv_item, new_item, _cell, self, _rotated)

func drop_ground_item_backend(_dropped_item : InventoryItem, _stack_amount : int):
	var player = inventory.fps_controller
	player.world.instance_ground_item(_dropped_item, _stack_amount, player.drop_position.global_position)

func split_item_one(_item : Dictionary, _drop_cell : Vector2, _rotated : bool):
	var _cached_stack_size : int = _item["item_rect"].current_stack
	
	var old_stack_size: int = _cached_stack_size - 1
	var new_stack_size: int = 1
	
	if try_split_item_stack(_item, new_stack_size, _drop_cell, _rotated):
		_item["item_rect"].current_stack = old_stack_size
	
	update_grid()

func split_item_half(_item : Dictionary, _drop_cell : Vector2, _rotated : bool):
	var _cached_stack_size : int = _item["item_rect"].current_stack
	
	var old_stack_size: int = _cached_stack_size / 2 + _cached_stack_size % 2
	var new_stack_size: int = _cached_stack_size - old_stack_size
	
	if try_split_item_stack(_item, new_stack_size, _drop_cell, _rotated):
		_item["item_rect"].current_stack = old_stack_size
	
	update_grid()

func quick_split_item_one(_item : Dictionary):
	var _cached_stack_size : int = _item["item_rect"].current_stack
	
	var old_stack_size: int = _cached_stack_size - 1
	var new_stack_size: int = 1
	
	if try_quick_split_item_stack(_item, new_stack_size):
		_item["item_rect"].current_stack = old_stack_size
	
	update_grid()

func quick_split_item_half(_item : Dictionary):
	var _cached_stack_size : int = _item["item_rect"].current_stack
	
	var old_stack_size: int = _cached_stack_size / 2 + _cached_stack_size % 2
	var new_stack_size: int = _cached_stack_size - old_stack_size
	
	if try_quick_split_item_stack(_item, new_stack_size):
		_item["item_rect"].current_stack = old_stack_size
	
	update_grid()

func drop_item_one(_item : Dictionary):
	var _cached_item : InventoryItem = _item["inv_item"]
	
	if _item["item_rect"].current_stack > 1:
		_item["item_rect"].current_stack -= 1
	else:
		remove_item(_item)
	
	drop_ground_item_backend(_cached_item, 1)
	
	update_grid()

func drop_item_all(_item : Dictionary):
	var _cached_item_stack_amount : int = _item["item_rect"].current_stack
	var _cached_item : InventoryItem = _item["inv_item"]
	
	remove_item(_item)
	
	drop_ground_item_backend(_cached_item, _cached_item_stack_amount)
	
	update_grid()

func remove_item(_item : Dictionary):
	items.erase(_item)
	_item["item_rect"].queue_free()
	update_grid()

func append_item_to_items(_item : InventoryItem, _item_rect : Control, _cell : Vector2, _sub_inventory : Control, _rotated : bool):
	items.append({"inv_item" : _item, "item_rect" : _item_rect, "cell" : _cell, "subinventory" : _sub_inventory, "rotated" : _rotated})
