extends ScrollContainer

@onready var held_item_preview = $"../HeldItemPreview"
@onready var subinventory_container = $subinventory_container

var subinventory_rects : Dictionary

func set_subinventories():
	subinventory_rects.clear()
	for subinventory in subinventory_container.get_children():
		subinventory_rects[subinventory] = subinventory.get_global_rect()
