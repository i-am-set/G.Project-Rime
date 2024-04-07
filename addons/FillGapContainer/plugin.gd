@tool
extends EditorPlugin


func _enter_tree() -> void:
	var script = load("res://addons/FillGapContainer/fill_gap_container.gd")
	var icon = load("res://addons/FillGapContainer/icon.png")
	add_custom_type("FillGapContainer", "Container", script, icon)


func _exit_tree() -> void:
	remove_custom_type("FillGapContainer")
