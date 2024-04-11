extends Node

var item_data
var item_data_file_path = "res://data/Item_Data.json"



func _ready():
	item_data = import_json_file(item_data_file_path)



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
