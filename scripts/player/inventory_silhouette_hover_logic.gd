extends Area2D

@onready var ui_element : Node = null

func _ready():
	var name_prefix = get_name().split("_")[0]
	var sibling = get_node("../silhouette_img")
	if sibling:
		for child in sibling.get_children():
			if child.get_name().begins_with(name_prefix):
				ui_element = child
				break

#func _process(delta):
	#var mouse_position = get_viewport().get_mouse_position()
	#var space_state = get_world_2d().direct_space_state
	#var result = space_state.intersect_point(mouse_position, 32, [], self.collision_mask, false, true)
#
	#if result.size() > 0:
		#print("Mouse is colliding with the Area2D")
	#else:
		#print("Mouse is not colliding with the Area2D")

func _on_mouse_entered():
	print(".")
	print(ui_element)
