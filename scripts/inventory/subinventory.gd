extends Control

const ITEM_RECT = preload("res://scenes/ui/item_rect.tscn")

@onready var inventory = $"../.."
@onready var held_item_preview = $"../../../held_item_preview"

@export var rows : int = 2
@export var columns : int = 2

var inventory_cells : Array = [] # Stores cell coordinate
var items : Array[Dictionary] = [] # Stores item data and positions

func _ready():
	Global.inv_cell_size_updated.connect(update_grid)
	
	set_up_cell_grid()
	update_grid()

func _process(delta):
	queue_redraw()

func _draw():
	var circle_radius = 2  # Adjust as needed
	var circle_color = Color(1, 0, 0)  # Red color
	
	var closest_cell_to_preview = get_closest_cell_position(held_item_preview.global_position - global_position)

	draw_circle(closest_cell_to_preview + (Global.INV_CELL_SIZE * 0.5), 5, Color.RED)
	
	draw_line(Vector2(0,0), Vector2(columns*Global.INV_CELL_SIZE.x, 0), circle_color, 4)
	draw_line(Vector2(columns*Global.INV_CELL_SIZE.x, 0), Vector2(columns*Global.INV_CELL_SIZE.x, rows*Global.INV_CELL_SIZE.y), circle_color, 4)
	draw_line(Vector2(columns*Global.INV_CELL_SIZE.x, rows*Global.INV_CELL_SIZE.y), Vector2(0, rows*Global.INV_CELL_SIZE.y), circle_color, 4)
	draw_line(Vector2(0, rows*Global.INV_CELL_SIZE.y), Vector2(0,0), circle_color, 4)
	
	for _cell in inventory_cells:
		draw_circle(cell_to_position(_cell) + (Global.INV_CELL_SIZE * 0.5), circle_radius, circle_color)


func update_grid():
	for _item in items:
		_item["item_rect"].position = cell_to_position(_item["cell"])

func set_up_cell_grid():
	var cell_size = Global.INV_CELL_SIZE
	var cell_number = 1
	
	# Set up the grid based on the default cell size
	custom_minimum_size = Global.INV_CELL_SIZE * Vector2(columns, rows)
	
	# Set up the inventory size
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

func get_stackable_items(_dropped_item : InventoryItem, _stack_size : int, _drop_cell : Vector2, _item_size : Vector2):
	var cells_to_occupy = get_occupied_cells(_drop_cell, _item_size)
	
	# Check if space for an item is free
	for _item in items:
		if _item != inventory.held_item_reference:
			if _item["item"].item_id == _dropped_item.item_id:
				for _cell in cells_to_occupy:
					var _occupied_cells = get_occupied_cells(_item["cell"], Vector2(_item["item"].item_width, _item["item"].item_height))
					if _cell in _occupied_cells:
						if _item["item_rect"].current_stack + _stack_size <= _item["item"].stack_size:
							print_debug(_cell, " is stackable!")
							return _item
						else:
							print_debug(_cell, " is stackable, but full...")
							return null
	return null

func try_stack_transfer(_dropped_item : InventoryItem, _stack_size : int, _drop_cell : Vector2, _item_size : Vector2):
	var cells_to_occupy = get_occupied_cells(_drop_cell, _item_size)
	
	# Check if space for an item is free
	for _item in items:
		if _item != inventory.held_item_reference:
			if _item["item"].item_id == _dropped_item.item_id:
				for _cell in cells_to_occupy:
					var _occupied_cells = get_occupied_cells(_item["cell"], Vector2(_item["item"].item_width, _item["item"].item_height))
					if _cell in _occupied_cells:
						if _item["item_rect"].current_stack + _stack_size > _item["item"].stack_size && _stack_size > _item["item_rect"].current_stack:
							inventory.held_item_reference["item_rect"].current_stack = _item["item_rect"].current_stack
							_item["item_rect"].current_stack = _stack_size
							print_debug(_cell, " stack transfered!")
							return true
						else:
							printerr("Logic failed!")
							return false
	return false

func is_space_occupied(_drop_cell : Vector2, _item_size : Vector2):
	var cells_to_occupy = get_occupied_cells(_drop_cell, _item_size)
	
	# Check if any cell is outside the bounds of the inventory grid
	for cell in cells_to_occupy:
		if cell.x >= columns or cell.y >= rows or cell.x < 0 or cell.y < 0:
			print_debug("Exceeds the bounds of the inventory...")
			return true
	
	# Check if space for an item is free
	for _item in items:
		if _item != inventory.held_item_reference:
			for _cell in cells_to_occupy:
				var _occupied_cells = get_occupied_cells(_item["cell"], Vector2(_item["item"].item_width, _item["item"].item_height))
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
		var _occupied_cells = get_occupied_cells(_item["cell"], Vector2(_item["item"].item_width, _item["item"].item_height))
		if _cell in _occupied_cells:
			return _item
	
	return null

func can_add_item(_item : InventoryItem, _drop_cell : Vector2) -> bool:
	if is_space_occupied(_drop_cell, Vector2(_item.item_width, _item.item_height)):
		return false
	return true

func can_stack_item(_item : InventoryItem, _stack_size : int, _drop_cell : Vector2) -> bool:
	if get_stackable_items(_item, _stack_size, _drop_cell, Vector2(_item.item_width, _item.item_height)) != null:
		return true
	return false

func try_quick_add_item(_item : InventoryItem, _stack_size : int) -> bool:
	for _cell in inventory_cells:
		if get_stackable_items(_item, _stack_size, _cell, Vector2(_item.item_width, _item.item_height)) != null:
			try_add_item(_item, _stack_size, _cell)
			return true
	for _cell in inventory_cells:
		if !is_space_occupied(_cell, Vector2(_item.item_width, _item.item_height)):
			try_add_item(_item, _stack_size, _cell)
			return true
	
	return false

func try_split_item_stack(_item : InventoryItem, _new_stack_size : int) -> bool:
	for _cell in inventory_cells:
		if !is_space_occupied(_cell, Vector2(_item.item_width, _item.item_height)):
			var new_item = ITEM_RECT.instantiate()
			new_item.inv_item = _item
			new_item.position = cell_to_position(_cell)
			new_item.current_stack = _new_stack_size
			add_child(new_item)
			items.append({"item" : _item, "item_rect" : new_item, "cell" : _cell, "subinventory" : self})
			update_grid()
			return true
	
	return false

func try_add_item(_item : InventoryItem, _stack_size : int, _drop_cell : Vector2) -> bool:
	if can_stack_item(_item, _stack_size, _drop_cell):
		var _stackable_item : Dictionary = get_stackable_items(_item, _stack_size, _drop_cell, Vector2(_item.item_width, _item.item_height))
		_stackable_item["item_rect"].current_stack += _stack_size
		print_debug(_stackable_item["item_rect"].current_stack)
		return true
	
	if try_stack_transfer(_item, _stack_size, _drop_cell, Vector2(_item.item_width, _item.item_height)):
		inventory.HideHeldItemPreview()
		return false
	
	if !can_add_item(_item, _drop_cell):
		return false
	
	var new_item = ITEM_RECT.instantiate()
	new_item.inv_item = _item
	new_item.position = cell_to_position(_drop_cell)
	new_item.current_stack = _stack_size
	add_child(new_item)
	items.append({"item" : _item, "item_rect" : new_item, "cell" : _drop_cell, "subinventory" : self})
	update_grid()
	return true

func drop_ground_item_backend(_dropped_item : InventoryItem, _stack_amount : int):
	var player = inventory.fps_controller
	player.world.instance_ground_item(_dropped_item, _stack_amount, player.drop_position.global_position)

func split_item_one(_item : Dictionary):
	var _cached_item : InventoryItem = _item["item"]
	var _cached_stack_size : int = _item["item_rect"].current_stack
	
	var old_stack_size: int = _cached_stack_size - 1
	var new_stack_size: int = 1
	
	if try_split_item_stack(_cached_item, new_stack_size):
		_item["item_rect"].current_stack = old_stack_size
	
	update_grid()

func split_item_half(_item : Dictionary):
	var _cached_item : InventoryItem = _item["item"]
	var _cached_stack_size : int = _item["item_rect"].current_stack
	
	var old_stack_size: int = _cached_stack_size / 2 + _cached_stack_size % 2
	var new_stack_size: int = _cached_stack_size - old_stack_size
	
	if try_split_item_stack(_cached_item, new_stack_size):
		_item["item_rect"].current_stack = old_stack_size
	
	update_grid()

func drop_item_one(_item : Dictionary):
	var _cached_item : InventoryItem = _item["item"]
	
	if _item["item_rect"].current_stack > 1:
		_item["item_rect"].current_stack -= 1
	else:
		remove_item(_item)
	
	drop_ground_item_backend(_cached_item, 1)
	
	update_grid()

func drop_item_all(_item : Dictionary):
	var _cached_item_stack_amount : int = _item["item_rect"].current_stack
	var _cached_item : InventoryItem = _item["item"]
	
	remove_item(_item)
	
	drop_ground_item_backend(_cached_item, _cached_item_stack_amount)
	
	update_grid()

func remove_item(_item : Dictionary):
	items.erase(_item)
	_item["item_rect"].queue_free()
	update_grid()
