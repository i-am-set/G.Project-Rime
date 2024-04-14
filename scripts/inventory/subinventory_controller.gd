extends ColorRect

const INV_ITEM_RECT = preload("res://scenes/ui/inv_item_rect.tscn")

@onready var held_item_preview = $"../../../HeldItemPreview"
@onready var ghost_preview = $"../../../GhostPreview"

@export var inventory_width : int = 1
@export var inventory_height : int = 1
@export var contents : Dictionary = {} # cell : item

var item_center : Vector2
var inventory_cells : Dictionary = {}
var hovered_cell_position : Vector2

func _ready():
	var cell_size = Global.INV_DEFAULT_CELL_SIZE
	var cell_number = 1
	set_custom_minimum_size(Vector2(inventory_width * cell_size, inventory_height * cell_size))
	
	# Set up the inventory size
	for i in range(inventory_width):
		for j in range(inventory_height):
			var cell_center = Vector2(i * cell_size + cell_size * 0.5, j * cell_size + cell_size * 0.5)
			inventory_cells[cell_number] = cell_center
			cell_number += 1
	
	cell_number = 1
	
	# Populate inventory slots
	var rand = randi_range(1, 6)
	for i in range(rand):
		var new_item = InvItem.new()
		new_item.item_id = "a000001"
		new_item.item_name = StaticData.item_data[new_item.item_id]["item_name"]
		new_item.item_width = StaticData.item_data[new_item.item_id]["item_width"]
		new_item.item_height = StaticData.item_data[new_item.item_id]["item_height"]
		var child_item = INV_ITEM_RECT.instantiate()
		add_child(child_item)
		add_item(child_item.duplicate(), [Vector2(cell_number, 1)], cell_to_position(Vector2(cell_number, 1)))
		child_item.queue_free()
		if child_item.inv_item == null:
			child_item.inv_item = new_item
		cell_number += 1
	
	print(contents)

func _process(delta):
	item_center = held_item_preview.size * 0.5
	
	if held_item_preview.held_item != null && hovered_cell_position != null:
		ghost_preview.global_position = hovered_cell_position + global_position - ghost_preview.size * 0.5 # todo - fix this part for the ghosting
	
	queue_redraw()

func _input(event):
	if event is InputEventMouseMotion && held_item_preview.visible && self.get_global_rect().has_point(held_item_preview.global_position + item_center):
		get_closest_cell_position_to_held_item()

func get_closest_cell_position_to_held_item():
	hovered_cell_position = get_closest_cell_position(held_item_preview.global_position - global_position)

func _draw():
	var circle_radius = 2  # Adjust as needed
	var circle_color = Color(1, 0, 0)  # Red color
	
	draw_circle(get_closest_cell_position(held_item_preview.global_position - global_position), 5, Color.RED)
	draw_circle(held_item_preview.global_position - global_position, 3, Color.MEDIUM_PURPLE)
	
	var inventory_cell_positions = inventory_cells.values()
	for pos in inventory_cell_positions:
		draw_circle(pos, circle_radius, circle_color)

func get_closest_cell_position(input_position):
	var closest_distance = INF
	var closest_cell_position
	var inventory_cell_positions = inventory_cells.values()
	for cell_position in inventory_cell_positions:
		var distance = input_position.distance_squared_to(cell_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_cell_position = cell_position
	return closest_cell_position

func get_closest_cell(input_position):
	return position_to_cell(get_closest_cell_position(input_position))

func position_to_cell(_pos : Vector2) -> Vector2:
	return _pos / Global.INV_DEFAULT_CELL_SIZE

func cell_to_position(_cell : Vector2) -> Vector2:
	return _cell * Global.INV_DEFAULT_CELL_SIZE

func add_item(item_rect : Control, _cells : Array[Vector2], drop_position : Vector2) -> bool:
	item_rect.position = drop_position
	add_child(item_rect)
	held_item_preview.held_item = null
	
	contents[item_rect] = _cells
	return true

func remove_item(_cells : Array[Vector2]):
	for _cell in _cells:
		for item in contents:
			if _cell in contents[item]:
				var cached_item = item
				print_debug("Removing ", item, "...")
				contents.erase(item)
				cached_item.queue_free()
	printerr("Failed to find item to remove.")
