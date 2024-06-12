extends Node


var config = ConfigFile.new()
const CONFIG_FILE_PATH = "user://config.ini"

func _ready():
	if !FileAccess.file_exists(CONFIG_FILE_PATH):
		config.set_value("game", "fov", 75)
		config.set_value("game", "temperature_unit", 0)
		
		config.set_value("video", "display_mode", 0)
		config.set_value("video", "resolution", "1600x900")
		config.set_value("video", "upscaler", 100)
		config.set_value("video", "vsync", true)
		config.set_value("video", "screen_select", 0)
		config.set_value("video", "shadow_quality", 1)
		config.set_value("video", "shadow_filter", 1)
		config.set_value("video", "ssil_quality", 1)
		config.set_value("video", "ssao_quality", 1)
		config.set_value("video", "outline", true)
		
		config.set_value("controls", "mouse_sensitivity", 1.0)
		
		config.save(CONFIG_FILE_PATH)
	else:
		config.load(CONFIG_FILE_PATH)

func save_setting(type : String, key : String, value):
	config.set_value(type, key, value)
	config.save(CONFIG_FILE_PATH)

func load_settings(type : String):
	var loaded_settings = {}
	for key in config.get_section_keys(type):
		loaded_settings[key] = config.get_value(type, key)
	return loaded_settings

