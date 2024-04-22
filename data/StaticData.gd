extends Node

const MESH_TO_TEXTURE_TOOL = preload("res://scenes/utility/mesh_to_texture_tool.tscn")

var item_data
var item_data_file_path = "res://data/Item_Data.json"
var mesh_to_texture_tool

const MISSING_MESH_MODEL = preload("res://meshes/utility/missing_mesh_model.obj")

func _ready():
	mesh_to_texture_tool = MESH_TO_TEXTURE_TOOL.instantiate()
	
	item_data = import_json_file(item_data_file_path)
	
	for _item in item_data.keys():
		var _item_mesh : ArrayMesh = load(_item["item_mesh"])
		var _item_name : String = _item["item_name"]
		mesh_to_texture_tool.process_image(_item_mesh, _item_name.replace(" ", "_"))
	
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
	new_item.item_width = item_data[item_id]["item_width"]
	new_item.item_height = item_data[item_id]["item_height"]
	new_item.stack_size = item_data[item_id]["stack_size"]
	new_item.item_weight = item_data[item_id]["item_weight"]
	if item_data[item_id]["item_mesh"] != null:
		new_item.item_mesh = load(item_data[item_id]["item_mesh"])
	else:
		new_item.item_mesh = MISSING_MESH_MODEL
	
	return new_item

func c_list_all_items() -> void:
	for item in item_data:
		Console.print_line("[color=MEDIUM_VIOLET_RED]name: [/color][color=SEA_GREEN]" + item_data[item]["item_name"] + "        " +"[/color][color=MEDIUM_VIOLET_RED]id: [/color][color=SEA_GREEN]" + item + "[/color]")
