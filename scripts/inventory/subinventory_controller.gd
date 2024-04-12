extends ColorRect

@onready var held_item_preview = $"../../../HeldItemPreview"
@onready var ghost_preview = $"../../../GhostPreview"

@export var inventory_width : int = 1
@export var inventory_height : int = 1

var item_center : Vector2
var cell_positions : Array[Vector2] = []
var contents : Dictionary = {}
var hovered_cell_position : Vector2

func _ready():
	var cell_size = Global.INV_DEFAULT_CELL_SIZE
	set_custom_minimum_size(Vector2(inventory_width * cell_size, inventory_height * cell_size))
	
	for i in range(inventory_width):
		for j in range(inventory_height):
			var cell_center = Vector2(i * cell_size + cell_size / 2, j * cell_size + cell_size / 2)
			cell_positions.append(cell_center)

	print(cell_positions)

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
	
	for pos in cell_positions:
		draw_circle(pos, circle_radius, circle_color)

func get_closest_cell_position(input_position, input_size):
	var closest_distance = INF
	var closest_cell_position
	for cell_position in cell_positions:
		var center = input_position + input_size
		var distance = center.distance_squared_to(cell_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_cell_position = cell_position
	return closest_cell_position

func add_item(item : ColorRect, _cell_positions : Array[Vector2]):
	for cell_pos in _cell_positions:
		if !contents.keys().has(cell_pos):
			contents[cell_pos] = item

func remove_item(_cell_positions : Array[Vector2]):
	for cell_pos in _cell_positions:
		if contents.keys().has(cell_pos):
			contents.erase(cell_pos)
