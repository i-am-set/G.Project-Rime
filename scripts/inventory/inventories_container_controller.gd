extends ScrollContainer

@onready var held_item_preview = $"../HeldItemPreview"
@onready var ghost_preview = $"../GhostPreview"

@onready var subinventory_container = $subinventory_container

var subinventory_rects : Dictionary

func _ready():
	held_item_preview.size = Vector2(Global.INV_DEFAULT_CELL_SIZE, Global.INV_DEFAULT_CELL_SIZE)
	ghost_preview.size = Vector2(Global.INV_DEFAULT_CELL_SIZE, Global.INV_DEFAULT_CELL_SIZE)

func _process(delta):
	queue_redraw()

func _draw():
	for _subinventory in subinventory_rects:
		var centents_cells = _subinventory.contents.values()
		for _occupied_cells in centents_cells:
			for _occupied_cell in _occupied_cells:
				var occupied_cell_position = _subinventory.cell_to_position(_occupied_cell)
				draw_line(occupied_cell_position + _subinventory.position, occupied_cell_position + _subinventory.position - Vector2(0, 20), Color.AQUA, 4)

func set_subinventories():
	subinventory_rects.clear()
	for subinventory in subinventory_container.get_children():
		subinventory_rects[subinventory] = subinventory.get_global_rect()
