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
	for subinventory in subinventory_rects:
		for occupied_cell in subinventory.occupied_cell_positions:
			draw_line(occupied_cell + subinventory.position, occupied_cell + subinventory.position - Vector2(0, 20), Color.AQUA, 4)

func set_subinventories():
	subinventory_rects.clear()
	for subinventory in subinventory_container.get_children():
		subinventory_rects[subinventory] = subinventory.get_global_rect()
