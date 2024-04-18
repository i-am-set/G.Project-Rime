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

# Options Variables
var MOUSE_CAPTURED := false
var RENDER_DISTANCE = 2
var MOUSE_SENSITIVITY : float = 1
var LOD_BIAS : float = 0.25
var IS_VSYNC_ENABLED := true
var FIELD_OF_VIEW : int = 75
var POSTP_OUTLINE_ON := true
var POSTP_DITHER_ON := true
var RES_SCALE_PERCENT : int = 100
var DISPLAY_FARENHEIT = false

# Player Variables
var INV_CELL_SIZE = INV_DEFAULT_CELL_SIZE:
	set(new_value):
		INV_CELL_SIZE = new_value
		emit_signal("inv_cell_size_updated")
var IS_PAUSED := false
var IS_IN_INVENTORY := false
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
	IS_IN_INVENTORY = false
	IS_IN_GAME = false

func get_current_temperature_display() -> float:
	if DISPLAY_FARENHEIT:
		return snapped(CURRENT_TEMPERATURE_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(CURRENT_TEMPERATURE_C, 0.1)

func get_temperature_high_display() -> float:
	if DISPLAY_FARENHEIT:
		return snapped(TEMPERATURE_HIGH_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(TEMPERATURE_HIGH_C, 0.1)
	
func get_temperature_low_display() -> float:
	if DISPLAY_FARENHEIT:
		return snapped(TEMPERATURE_LOW_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(TEMPERATURE_LOW_C, 0.1)

func get_temperature_max_display() -> float:
	if DISPLAY_FARENHEIT:
		return snapped(MAX_TEMPERATURE_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(MAX_TEMPERATURE_C, 0.1)
	
func get_temperature_min_display() -> float:
	if DISPLAY_FARENHEIT:
		return snapped(MIN_TEMPERATURE_C * 9.0/5.0 + 32.0, 0.1)
	return snapped(MIN_TEMPERATURE_C, 0.1)

func get_temperature_sign_display() -> String:
	if DISPLAY_FARENHEIT:
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
