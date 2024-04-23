extends Node

const MESH_TO_TEXTURE_TOOL = preload("res://scenes/utility/mesh_to_texture_tool.tscn")

var item_data
var item_data_file_path = "res://data/Item_Data.json"
var mesh_to_texture_tool
var has_processed_images : bool = false

const MISSING_MESH_MODEL = preload("res://meshes/utility/missing_mesh_model.obj")
const MISSING_IMAGE_TEXTURE = preload("res://textures/debug/error_null_texture.png")

func _ready():
	mesh_to_texture_tool = await MESH_TO_TEXTURE_TOOL.instantiate()
	add_child(mesh_to_texture_tool)
	await get_tree().create_timer(0.25).timeout
	
	item_data = import_json_file(item_data_file_path)
	await get_tree().create_timer(0.25).timeout
	
	await process_mesh_to_images()
	has_processed_images = true
	print_debug("Done processing images!")
	
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

func process_mesh_to_images():
	for _item in item_data.keys():
		var _item_mesh : ArrayMesh
		if item_data[_item]["item_mesh"] != null:
			_item_mesh = load(item_data[_item]["item_mesh"])
		else:
			_item_mesh = MISSING_MESH_MODEL
		var _item_width : int = item_data[_item]["item_width"]
		var _item_height : int = item_data[_item]["item_height"]
		var _item_name : String = item_data[_item]["item_name"]
		await mesh_to_texture_tool.process_image(_item_mesh, _item_name.to_lower().replace(" ", "_"), _item_width, _item_height)
		print_debug("Processed image for ", _item_name)
	
	mesh_to_texture_tool.queue_free()

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
	var new_item_image_path = "res://textures/items/%s_thumbnail.png" % new_item.item_name.to_lower().replace(" ", "_")
	if FileAccess.file_exists(new_item_image_path):
		new_item.item_image = load(new_item_image_path)
	else:
		new_item.item_image = MISSING_IMAGE_TEXTURE
	
	
	return new_item

func c_list_all_items() -> void:
	for item in item_data:
		Console.print_line("[color=MEDIUM_VIOLET_RED]name: [/color][color=SEA_GREEN]" + item_data[item]["item_name"] + "        " +"[/color][color=MEDIUM_VIOLET_RED]id: [/color][color=SEA_GREEN]" + item + "[/color]")
