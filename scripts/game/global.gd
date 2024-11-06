extends Node
class_name _Global

signal inv_cell_size_updated()

var debug # Reference to DebugPanel for debug property assignment
var player # Reference to PlayerController

const PACKET_READ_LIMIT: int = 32

# World Constants
const WORLD_PATH = "res://scenes/maingame/world.tscn"
const MAX_TEMPERATURE_C = -10 # celsius
const MIN_TEMPERATURE_C = -25 # celsius
const ITEM_ICONS : Dictionary = {
	"a000001" : preload("res://textures/items/icons/ico_flint.png"),
	"a000002" : preload("res://textures/items/icons/ico_stone.png"),
	"a000003" : preload("res://textures/items/icons/ico_pine_needles.png"),
	"a000004" : preload("res://textures/items/icons/ico_dead_pine_needles.png"),
	"a000005" : preload("res://textures/items/icons/ico_twigs.png"),
	"a000006" : preload("res://textures/items/icons/ico_stick.png"),
	"a000007" : preload("res://textures/items/icons/ico_log.png"),
	"a000008" : preload("res://textures/items/icons/ico_charcoal.png"),
	"a000009" : preload("res://textures/items/icons/ico_plant_fiber.png"),
	"a000010" : preload("res://textures/items/icons/ico_tree_bark.png"),
	"a000011" : preload("res://textures/items/icons/ico_cloth_fragment.png"),
	"a000012" : preload("res://textures/items/icons/ico_metal_scrap.png"),
	"a000013" : preload("res://textures/items/icons/ico_glass_shards.png"),
	"a000014" : preload("res://textures/items/icons/ico_loose_wires.png"),
	"a000015" : preload("res://textures/items/icons/ico_sharpened_flint.png")
}
const FILLER_MESH : Mesh = preload("res://meshes/items/resources/sack_item_model.obj")
const ITEM_MESHES : Dictionary = {
	"a000001" : preload("res://meshes/items/resources/flint_item_model.obj"),
	"a000002" : preload("res://meshes/items/resources/stone_item_model.obj"),
	"a000003" : FILLER_MESH,
	"a000004" : FILLER_MESH,
	"a000005" : preload("res://meshes/items/resources/twig_item_model.obj"),
	"a000006" : preload("res://meshes/items/resources/stick_item_model.obj"),
	"a000007" : preload("res://meshes/items/resources/log_item_model.obj"),
	"a000008" : preload("res://meshes/items/resources/flint_item_model.obj"),
	"a000009" : FILLER_MESH,
	"a000010" : FILLER_MESH,
	"a000011" : FILLER_MESH,
	"a000012" : FILLER_MESH,
	"a000013" : FILLER_MESH,
	"a000014" : FILLER_MESH,
	"a000015" : FILLER_MESH
}

# Player Constants
const INV_DEFAULT_CELL_SIZE = Vector2(30, 30)

# Options Constants
const DEFAULT_FOV = 75
const MIN_FOV = 60
const MAX_FOV = 90
const MIN_SENSITIVITY = 0.1
const MAX_SENSITIVITY = 3
const MIN_SPEED = 0
const MAX_SPEED = 1000
const Resolutions: Dictionary = {"3840x2160":Vector2i(3840,2160),
								"2560x1440":Vector2i(2560,1080),
								"1920x1080":Vector2i(1920,1080),
								"1600x900":Vector2i(1600,900),
								"1536x864":Vector2i(1536,864),
								"1440x900":Vector2i(1440,900),
								"1366x768":Vector2i(1366,768),
								"1280x720":Vector2i(1280,720),
								"1024x600":Vector2i(1024,600),
								"800x600": Vector2i(800,600)}

# Steam Variables
var OWNED := false
var ONLINE := false
var STEAM_ID : int = 0
var STEAM_NAME := ""

# Lobby Variables 
var DATA
var LOBBY_ID : int = 0
var LOBBY_MAX_MEMBERS : int = 4
var LOBBY_MEMBERS := []
var LOBBY_INVITE_ARG := false
var LOBBY_PEER_INSTANCES := {} 
var GLOBAL_TICK : int = 0

# World Variables
var WORLD_SEED : int = 0
var TIME_OF_DAY : float = 1200.0
var CURRENT_TEMPERATURE_C : float = (MAX_TEMPERATURE_C + MIN_TEMPERATURE_C) / 2
var TEMPERATURE_HIGH_C : float = MAX_TEMPERATURE_C
var TEMPERATURE_LOW_C : float = TEMPERATURE_HIGH_C - 3
var SUN_WARMTH_MULTIPLIER : float = 1.0
var SPAWN_POINT := Vector2.ZERO
var WIND_DIRECTION : Vector2 = Vector2.RIGHT

# Options Variables
var MOUSE_CAPTURED := false
var RENDER_DISTANCE = 2
var MOUSE_SENSITIVITY : float = 1.0
var IS_VSYNC_ENABLED := true
var FIELD_OF_VIEW : int = 75
var POSTP_OUTLINE_ON := true
var POSTP_DITHER_ON := true
var TEMPERATURE_UNIT : int = 0 # 0 is C; 1 is F

# Player Variables
var INV_CELL_SIZE = INV_DEFAULT_CELL_SIZE:
	set(new_value):
		INV_CELL_SIZE = new_value
		emit_signal("inv_cell_size_updated")
var IS_PAUSED := false
var IS_IN_CONSOLE := false
var IS_IN_GAME := false

func _ready():
	var INIT = Steam.steamInit()
	if INIT['status'] == 20:
		print_debug("Steam is not running. Please run steam for this integration to work.")
		# Show an alert
		OS.alert("Initialization Status: " + str(INIT['status']) + "\n" + str(INIT['verbal']) + "\nPlease run steam for online play to work.", "Steam not running.")
		# Quit the game
		#get_tree().quit()
		return
	elif Steam.getSteamID() <= 0:
		print_debug("Steam has not fully initualized and/or no valid Steam ID was found.")
		# Show an alert
		OS.alert("Steam has not fully initualized and/or no valid Steam ID was found.\nPlease wait for Steam to initualize and try again.", "Failure to find Steam ID")
		# Quit the game
		#get_tree().quit()
		return
	elif INIT['status'] != 1:
		print_debug("Steam is not running. Please run steam for this integration to work.")
		# Show an alert
		OS.alert("Initialization Status: " + str(INIT['status']) + "\n" + str(INIT['verbal']), str(INIT['verbal']))
		# Quit the game
		#get_tree().quit()
		return
	
	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	OWNED = Steam.isSubscribed()
	
	#if OWNED == false:
		#print_debug("User does not own this game.")
		#OS.alert("License not found.\nPlease purchase a copy of the game to proceed.", "Game is not owned.")
		#get_tree().quit()

func _physics_process(_delta):
	Steam.run_callbacks()
	
	GLOBAL_TICK += 1
	if GLOBAL_TICK % 40 == 0:
		repair_globals()

func capture_mouse(captured : bool):
	if captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	MOUSE_CAPTURED = captured

func repair_globals():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		MOUSE_CAPTURED = true
	elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		MOUSE_CAPTURED = false

func get_render_distance() -> int:
	return RENDER_DISTANCE

func leave_lobby():
	# Lobby Variables 
	LOBBY_ID = 0
	LOBBY_MAX_MEMBERS = 4
	LOBBY_MEMBERS = []
	LOBBY_INVITE_ARG = false
	LOBBY_PEER_INSTANCES = {} 
	GLOBAL_TICK = 0
	# World Variables
	WORLD_SEED = 0
	SPAWN_POINT = Vector2.ZERO
	IS_PAUSED = false
	IS_IN_GAME = false

func get_current_temperature_display() -> float:
	if TEMPERATURE_UNIT == 1:
		return snapped(CURRENT_TEMPERATURE_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(CURRENT_TEMPERATURE_C, 0.1)

func get_temperature_high_display() -> float:
	if TEMPERATURE_UNIT == 1:
		return snapped(TEMPERATURE_HIGH_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(TEMPERATURE_HIGH_C, 0.1)
	
func get_temperature_low_display() -> float:
	if TEMPERATURE_UNIT == 1:
		return snapped(TEMPERATURE_LOW_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(TEMPERATURE_LOW_C, 0.1)

func get_temperature_max_display() -> float:
	if TEMPERATURE_UNIT == 1:
		return snapped(MAX_TEMPERATURE_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(MAX_TEMPERATURE_C, 0.1)
	
func get_temperature_min_display() -> float:
	if TEMPERATURE_UNIT == 1:
		return snapped(MIN_TEMPERATURE_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(MIN_TEMPERATURE_C, 0.1)

func get_temperature_sign_display() -> String:
	if TEMPERATURE_UNIT == 1:
		return "°F"
	return "°C"

func get_all_temperature_stats_debug() -> String:
	var sign_t := get_temperature_sign_display()
	var cur_t := get_current_temperature_display()
	var lo_t := get_temperature_low_display()
	var hi_t := get_temperature_high_display()
	var min_t := get_temperature_min_display()
	var max_t := get_temperature_max_display()
	
	return ("\nCurrent: %d%s\nLow: %d%s  High: %d%s\nMin: %d%s  Max: %d%s\n" % [cur_t, sign_t, lo_t, sign_t, hi_t, sign_t, min_t, sign_t, max_t, sign_t,])

func Convert_Percentage_To_Decibel(percentage : float):
	var scale : float = 20.0
	var divisor : float = 50.0
	
	return scale * (log(percentage / divisor) / log(10))

func Center_Window():
	var Center_Screen = DisplayServer.screen_get_position()+DisplayServer.screen_get_size()/2
	var Window_Size = get_window().get_size_with_decorations()
	get_window().set_position(Center_Screen-Window_Size/2)

func initialize_settings():
	var _current_game_settings = ConfigFileHandler.load_settings("game")
	var _current_video_settings = ConfigFileHandler.load_settings("video")
	var _current_control_settings = ConfigFileHandler.load_settings("controls")
	var _current_audio_settings = ConfigFileHandler.load_settings("audio")
	
	# game
	var fov : int = _current_game_settings["fov"]
	var temperature_unit : int = _current_game_settings["temperature_unit"]
	var display_fps : bool = _current_game_settings["display_fps"]
	# video
	var display_mode : int = _current_video_settings["display_mode"]
	var resolution : String = _current_video_settings["resolution"]
	var upscaler : int = _current_video_settings["upscaler"]
	var vsync : bool = _current_video_settings["vsync"]
	var screen_select : int = _current_video_settings["screen_select"]
	var shadow_quality : int = _current_video_settings["shadow_quality"]
	var shadow_filter : int = _current_video_settings["shadow_filter"]
	var ssil_quality : int = _current_video_settings["ssil_quality"]
	var ssao_quality : int = _current_video_settings["ssao_quality"]
	var outline : bool = _current_video_settings["outline"]
	# controls
	var mouse_sensitivity : float =  _current_control_settings["mouse_sensitivity"]
	# audio
	var master_audio = _current_audio_settings["master_audio"]
	var music_audio = _current_audio_settings["music_audio"]
	var sfx_audio = _current_audio_settings["sfx_audio"]
	var ambience_audio = _current_audio_settings["ambience_audio"]
	
	
	
############################################
	FIELD_OF_VIEW = fov
############################################
	TEMPERATURE_UNIT = temperature_unit
############################################
	DebugAutoloadCanvas.toggle_display_fps(display_fps)
############################################
	if display_mode == 0:
		get_window().set_mode(Window.MODE_WINDOWED)
		Center_Window()
	elif display_mode == 1:
		get_window().set_mode(Window.MODE_FULLSCREEN)
	elif display_mode == 2:
		get_window().set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
	else:
		get_window().set_mode(Window.MODE_WINDOWED)
		Center_Window()
############################################
	if display_mode == 0:
		if Resolutions.has(resolution):
			if (Resolutions[resolution].x >= DisplayServer.screen_get_size().x || Resolutions[resolution].y >= DisplayServer.screen_get_size().y):
				get_window().set_size(DisplayServer.screen_get_size())
			else:
				get_window().set_size(Resolutions[resolution])
		else:
			get_window().set_size(Vector2(1600, 900))
############################################
	var Resolution_Scale = upscaler/100.00
	get_viewport().set_scaling_3d_scale(Resolution_Scale)
############################################
	if vsync == true:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
############################################
	var _window = get_window()
	var _cached_mode = _window.get_mode()
	_window.set_mode(Window.MODE_WINDOWED)
	_window.set_current_screen(screen_select)
	if _cached_mode == Window.MODE_FULLSCREEN:
		_window.set_mode(Window.MODE_FULLSCREEN)
	elif _cached_mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		_window.set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
############################################
	if shadow_quality == 0:
		RenderingServer.directional_shadow_atlas_set_size(512, true)
	elif shadow_quality == 1:
		RenderingServer.directional_shadow_atlas_set_size(1024, true)
	elif shadow_quality == 2:
		RenderingServer.directional_shadow_atlas_set_size(4096, true)
	else:
		RenderingServer.directional_shadow_atlas_set_size(1024, true)
############################################
	if shadow_filter == 0:
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
	elif shadow_filter == 1:
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	elif shadow_filter == 2:
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
	else:
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
############################################
	if ssil_quality == 0:
		ProjectSettings.set("rendering/environment/ssil/quality", 0)
	elif ssil_quality == 1:
		ProjectSettings.set("rendering/environment/ssil/quality", 2)
	elif ssil_quality == 2:
		ProjectSettings.set("rendering/environment/ssil/quality", 3)
	else:
		ProjectSettings.set("rendering/environment/ssil/quality", 2)
	ProjectSettings.save()
############################################
	if ssao_quality == 0:
		ProjectSettings.set("rendering/environment/ssao/quality", 0)
	elif ssao_quality == 1:
		ProjectSettings.set("rendering/environment/ssao/quality", 2)
	elif ssao_quality == 2:
		ProjectSettings.set("rendering/environment/ssao/quality", 3)
	else:
		ProjectSettings.set("rendering/environment/ssao/quality", 2)
	ProjectSettings.save()
############################################
	POSTP_OUTLINE_ON = outline
############################################
	MOUSE_SENSITIVITY = mouse_sensitivity
############################################
	AudioServer.set_bus_volume_db(0, Convert_Percentage_To_Decibel(master_audio))
############################################
	AudioServer.set_bus_volume_db(1, Convert_Percentage_To_Decibel(music_audio))
############################################
	AudioServer.set_bus_volume_db(2, Convert_Percentage_To_Decibel(sfx_audio))
############################################
	AudioServer.set_bus_volume_db(3, Convert_Percentage_To_Decibel(ambience_audio))
