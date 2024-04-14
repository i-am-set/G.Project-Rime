extends Control

const ITEM_RECT = preload("res://scenes/ui/item_rect.tscn")

@onready var inventory = $"../.."
@onready var held_item_preview = $"../../../held_item_preview"

@export var rows : int = 2
@export var columns : int = 2

var inventory_cells : Array = [] # Stores cell coordinate
var items : Array[Dictionary] = [] # Stores item data and positions

func _ready():
	# Set up the grid based on the default cell size
	custom_minimum_size = Global.INV_DEFAULT_CELL_SIZE * Vector2(columns, rows)
	
	var cell_size = Global.INV_DEFAULT_CELL_SIZE
	var cell_number = 1
	
	# Set up the inventory size
	for i in range(rows):
		for j in range(columns):
			var _cell = Vector2(j, i)
			inventory_cells.append(_cell)
	
	update_grid()

func _process(delta):
	queue_redraw()

func _draw():
	var circle_radius = 2  # Adjust as needed
	var circle_color = Color(1, 0, 0)  # Red color
	
	var closest_cell_to_preview = get_closest_cell_position(held_item_preview.global_position - global_position)

	draw_circle(closest_cell_to_preview + (Global.INV_DEFAULT_CELL_SIZE * 0.5), 5, Color.RED)
	
	draw_line(Vector2(0,0), Vector2(columns*Global.INV_DEFAULT_CELL_SIZE.x, 0), circle_color, 4)
	draw_line(Vector2(columns*Global.INV_DEFAULT_CELL_SIZE.x, 0), Vector2(columns*Global.INV_DEFAULT_CELL_SIZE.x, rows*Global.INV_DEFAULT_CELL_SIZE.y), circle_color, 4)
	draw_line(Vector2(columns*Global.INV_DEFAULT_CELL_SIZE.x, rows*Global.INV_DEFAULT_CELL_SIZE.y), Vector2(0, rows*Global.INV_DEFAULT_CELL_SIZE.y), circle_color, 4)
	draw_line(Vector2(0, rows*Global.INV_DEFAULT_CELL_SIZE.y), Vector2(0,0), circle_color, 4)
	
	for _cell in inventory_cells:
		draw_circle(cell_to_position(_cell) + (Global.INV_DEFAULT_CELL_SIZE * 0.5), circle_radius, circle_color)


func update_grid():
	# Reset and redraw grid visualizations or GUI elements here if needed
	pass

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
	return _pos / Global.INV_DEFAULT_CELL_SIZE

func cell_to_position(_cell : Vector2) -> Vector2:
	return _cell * Global.INV_DEFAULT_CELL_SIZE

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

func try_quick_add_item(_item : InventoryItem):
	for _cell in inventory_cells:
		if !is_space_occupied(_cell, Vector2(_item.item_width, _item.item_height)):
			try_add_item(_item, _cell)
			return true
	return false

func try_add_item(_item : InventoryItem, _drop_cell : Vector2) -> bool:
	if is_space_occupied(_drop_cell, Vector2(_item.item_width, _item.item_height)):
		return false
	
	var new_item = ITEM_RECT.instantiate()
	new_item.inv_item = _item
	new_item.position = cell_to_position(_drop_cell)
	add_child(new_item)
	items.append({"item" : _item, "item_rect" : new_item, "cell" : _drop_cell})
	update_grid()
	return true

func remove_item(_item : Dictionary):
	items.erase(_item)
	_item["item_rect"].queue_free()
	update_grid()
