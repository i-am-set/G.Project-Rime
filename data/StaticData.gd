extends Node

var item_data
var item_data_file_path = "res://data/Item_Data.json"

const MISSING_MESH_MODEL = preload("res://meshes/utility/missing_mesh_model.obj")

func _ready():
	item_data = import_json_file(item_data_file_path)
	await get_tree().create_timer(0.25).timeout
	
	Console.create_command("get_item_list", self.c_list_all_items, "Lists all items and their IDs.")



func import_json_file(path : String):
	if FileAccess.file_exists(path):
		
		var data_file = FileAccess.open(path, FileAccess.READ)
		var parsed_result = JSON.parse_string(data_file.get_as_text())
		
		if parsed_result is Dictionary:
			return parsed_result
		else:
			printerr("Error reading file!")
	else:
		printerr("File doesn't exist!")


func create_item_from_id(item_id : String) -> InventoryItem:
	var new_item = InventoryItem.new()
	new_item.item_id = item_id
	new_item.item_name = item_data[item_id]["item_name"]
	new_item.item_description = item_data[item_id]["item_description"]
	new_item.item_type = item_data[item_id]["item_description"]
	new_item.item_weight = round(randf_range(item_data[item_id]["item_weight_min"], item_data[item_id]["item_weight_max"]) * 100.0) / 100.0
	print(new_item.item_weight)
	
	
	return new_item

func c_list_all_items() -> void:
	for item in item_data:
		Console.print_line("[color=MEDIUM_VIOLET_RED]name: [/color][color=SEA_GREEN]" + item_data[item]["item_name"] + "        " +"[/color][color=MEDIUM_VIOLET_RED]id: [/color][color=SEA_GREEN]" + item + "[/color]")
