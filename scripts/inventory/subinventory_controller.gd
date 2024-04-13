extends ColorRect

@onready var held_item_preview = $"../../../HeldItemPreview"
@onready var ghost_preview = $"../../../GhostPreview"

@export var inventory_width : int = 1
@export var inventory_height : int = 1
@export var contents : Dictionary = {}

var item_center : Vector2
var inventory_cells : Dictionary = {}
var hovered_cell_position : Vector2

func _ready():
	var cell_size = Global.INV_DEFAULT_CELL_SIZE
	var cell_number = 1
	set_custom_minimum_size(Vector2(inventory_width * cell_size, inventory_height * cell_size))
	
	for i in range(inventory_width):
		for j in range(inventory_height):
			var cell_center = Vector2(i * cell_size + cell_size / 2, j * cell_size + cell_size / 2)
			inventory_cells[cell_number] = cell_center
			cell_number += 1

func _process(delta):
	item_center = held_item_preview.size * 0.5
	
	if held_item_preview.held_item != null && hovered_cell_position != null:
		ghost_preview.global_position = hovered_cell_position + global_position - ghost_preview.size * 0.5 # todo - fix this part for the ghosting
	
	queue_redraw()

func _input(event):
	if event is InputEventMouseMotion && held_item_preview.visible && self.get_global_rect().has_point(held_item_preview.global_position + item_center):
		get_closest_cell_position_to_held_item()

func get_closest_cell_position_to_held_item():
	hovered_cell_position = get_closest_cell_position(held_item_preview.global_position - global_position, item_center)

func _draw():
	var circle_radius = 2  # Adjust as needed
	var circle_color = Color(1, 0, 0)  # Red color
	
	draw_circle(get_closest_cell_position(held_item_preview.global_position - global_position, item_center), 5, Color.RED)
	
	for pos in inventory_cells.values():
		draw_circle(pos, circle_radius, circle_color)

func get_closest_cell_position(input_position, input_size):
	var closest_distance = INF
	var closest_cell_position
	for cell_position in inventory_cells.values():
		var center = input_position + input_size
		var distance = center.distance_squared_to(cell_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_cell_position = cell_position
	return closest_cell_position

func position_to_cell(_pos : Vector2) -> Vector2:
	return _pos / Global.INV_DEFAULT_CELL_SIZE + Vector2(0.5, 0.5)

func cell_to_position(_cell : Vector2) -> Vector2:
	return (_cell - Vector2(0.5, 0.5)) * Global.INV_DEFAULT_CELL_SIZE

func add_item(item : ColorRect, _cell_positions : Array[Vector2]):
	for _cell_pos in _cell_positions:
		var _cell = position_to_cell(_cell_pos)
		if !contents.keys().has(_cell):
			contents[_cell] = item

func remove_item(_cell_positions : Array[Vector2]):
	for _cell_pos in _cell_positions:
		var _cell = position_to_cell(_cell_pos)
		if contents.keys().has(_cell):
			contents.erase(_cell)
