extends Control

@onready var node2d_polygon = $polygon_area
@onready var ui_element : Node = null
var original_polygon_points : PackedVector2Array

func _ready():
	var name_prefix = get_name().split("_")[0]
	var sibling = get_node("../silhouette_img")
	if sibling:
		for child in sibling.get_children():
			if child.get_name().begins_with(name_prefix):
				ui_element = child
				break
	
	ui_element.hide()
	original_polygon_points = convert_to_relative(node2d_polygon.polygon)
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _draw():
	draw_polygon(node2d_polygon.polygon, [ Color("478cbf") ])

func _input(event):
	if event is InputEventMouseMotion:
		if Geometry2D.is_point_in_polygon(get_global_mouse_position(), node2d_polygon.polygon):
			if !ui_element.visible:
				ui_element.show()
				print_debug("hovering over " + ui_element.name)
			return
		if ui_element.visible:
			ui_element.hide()
			print_debug("no longer hovering over " + ui_element.name)

func _on_viewport_size_changed():
	var rect = get_rect()
	var new_points = PackedVector2Array()
	var aspect_ratio = rect.size.x / rect.size.y
	for point in original_polygon_points:
		new_points.append(rect.position + Vector2(point.x * rect.size.x, point.y * rect.size.y * aspect_ratio))
	node2d_polygon.polygon = new_points
	_draw()

func convert_to_relative(points: PackedVector2Array) -> PackedVector2Array:
	var rect = get_rect()
	var relative_points = PackedVector2Array()
	var aspect_ratio = rect.size.x / rect.size.y
	for point in points:
		relative_points.append(Vector2((point.x - rect.position.x) / rect.size.x, (point.y - rect.position.y) / (rect.size.y * aspect_ratio)))
	return relative_points
