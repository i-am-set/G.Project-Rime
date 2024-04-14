extends Control

@onready var inventories_container = $"../../.."
@onready var display = $ColorRect

var held_item_preview : Control
var subinventory_rects : Dictionary
var old_cells : Array[Vector2]
var new_cells : Array[Vector2]

var inv_item : InvItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		size = Vector2(inv_item.item_width * Global.INV_DEFAULT_CELL_SIZE, inv_item.item_height * Global.INV_DEFAULT_CELL_SIZE)
		display.position = -size * 0.5

var cached_position : Vector2
var item_center_offset : Vector2

func _ready():
	pass

func _process(delta):
	held_item_preview = inventories_container.held_item_preview
	item_center_offset = size * 0.5
	
	held_item_follow_mouse()

func _input(event):
	if event.is_action_pressed("mouse_click"):
		if held_item_preview.held_item != null:
			if held_item_preview.held_item == self:
				subinventory_rects = inventories_container.subinventory_rects
				inventories_container.set_subinventories()
				for subinventory in subinventory_rects.keys():
					if subinventory_rects[subinventory].has_point(held_item_preview.position + item_center_offset):
						subinventory.get_closest_cell_position_to_held_item()
						var _hovered_cell = subinventory.position_to_cell(subinventory.hovered_cell_position)
						if !subinventory.contents.has(_hovered_cell):
							if !try_to_drop_item(subinventory):
								print("Slot taken")
		elif get_global_rect().has_point(get_global_mouse_position()) :
			pick_up_item()

func pick_up_item():
	held_item_preview.held_item = self
	cached_position = position
	held_item_preview.size = size
	held_item_preview.DISPLAY.position = -held_item_preview.size * 0.5
	held_item_preview.position = get_global_mouse_position() - item_center_offset # Move the held_item_preview to the mouse's position
	held_item_preview.show()

func try_to_drop_item(subinventory : Control) -> bool:
	var half_of_rect = Vector2(int(size.x / Global.INV_DEFAULT_CELL_SIZE),int(size.y / Global.INV_DEFAULT_CELL_SIZE)) * 0.5
	var half_of_cell = Vector2(Global.INV_DEFAULT_CELL_SIZE, Global.INV_DEFAULT_CELL_SIZE) * 0.5
	var drop_position = held_item_preview.global_position - subinventory.global_position
	
	var top_left_cell_position : Vector2 = subinventory.get_closest_cell_position(drop_position - half_of_rect + half_of_cell)
	var top_left_cell : Vector2 = subinventory.position_to_cell(top_left_cell_position)
	
	var cells_to_occupy : Array[Vector2] = get_cells_to_occupy(top_left_cell)
	
	if are_cells_occupied(cells_to_occupy, subinventory):
		return false
	
	old_cells = new_cells
	new_cells.clear()
	
	for _cell_to_occupy in cells_to_occupy:
		var _occupied_cell_position = subinventory.cell_to_position(_cell_to_occupy)
		
		var new_cell = subinventory.get_closest_cell(_occupied_cell_position)
		new_cells.append(new_cell)
	
	held_item_preview.hide()
	subinventory.remove_item(old_cells)
	drop_position = top_left_cell_position - half_of_cell + half_of_rect
	subinventory.add_item(self.duplicate(), new_cells, drop_position)
	self.queue_free()
	return true

func get_cells_to_occupy(top_left_cell: Vector2) -> Array[Vector2]:
	var cells_to_occupy : Array[Vector2] = []
	var cell_width = int(size.x / Global.INV_DEFAULT_CELL_SIZE)
	var cell_height = int(size.y / Global.INV_DEFAULT_CELL_SIZE)
	for x in range(cell_width):
		for y in range(cell_height):
			cells_to_occupy.append(top_left_cell + Vector2(x, y))
	return cells_to_occupy

func are_cells_occupied(cells_to_occupy: Array, subinventory : Control) -> bool:
	var _contents : Dictionary = subinventory.contents
	for _cell in cells_to_occupy:
		for _contained_item in _contents:
			if _cell in _contents[_contained_item]:
				return true
	return false

func held_item_follow_mouse():
	if held_item_preview.held_item == self:
		held_item_preview.position = get_global_mouse_position()  # Follow the mouse's x position
