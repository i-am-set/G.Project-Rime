extends Node
class_name _Global

var debug # Reference to DebugPanel for debug property assignment
var player # Reference to PlayerController

const PACKET_READ_LIMIT: int = 32

# Options Constants
const DEFAULT_FOV = 75
const MIN_FOV = 60
const MAX_FOV = 100
const MIN_SPEED = 0
const MAX_SPEED = 1000

# Steam Variables
var OWNED = false
var ONLINE = false
var STEAM_ID = 0
var STEAM_NAME = ""
# Lobby Variables 
var DATA
var LOBBY_ID = 0
var LOBBY_MAX_MEMBERS = 4
var LOBBY_MEMBERS = []
var LOBBY_INVITE_ARG = false
var LOBBY_PEER_INSTANCES = {} 
var GLOBAL_TICK = 0
# World Variables
var WORLD_SEED = 0
var SPAWN_POINT = Vector2.ZERO
var IS_PAUSED = false
var IS_IN_INVENTORY = false
# Options Variables
var MOUSE_CAPTURED = false
var RENDER_DISTANCE = 10
var LOD_BIAS = 0.25
var IS_VSYNC_ENABLED = true
var FIELD_OF_VIEW = 75
var POSTP_OUTLINE_ON = true
var POSTP_DITHER_ON = true
var RES_SCALE_PERCENT = 100

func _ready():
	var INIT = Steam.steamInit()
	if INIT['status'] == 20:
		print_debug("Steam is not running. Please run steam for this integration to work.")
		# Show an alert
		OS.alert("Initialization Status: " + str(INIT['status']) + "\n" + str(INIT['verbal']) + "\nPlease run steam for this integration to work.", "Steam not running.")
		# Quit the game
		get_tree().quit()
		return
	elif Steam.getSteamID() <= 0:
		print_debug("Steam has not fully initualized and/or no valid Steam ID was found.")
		# Show an alert
		OS.alert("Steam has not fully initualized and/or no valid Steam ID was found.\nPlease wait for Steam to initualize and try again.", "Failure to find Steam ID")
		# Quit the game
		get_tree().quit()
		return
	elif INIT['status'] != 1:
		print_debug("Steam is not running. Please run steam for this integration to work.")
		# Show an alert
		OS.alert("Initialization Status: " + str(INIT['status']) + "\n" + str(INIT['verbal']), str(INIT['verbal']))
		# Quit the game
		get_tree().quit()
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

func remove_lobby_data():
	# Lobby Variables
	LOBBY_ID = 0
	LOBBY_MEMBERS = []
	LOBBY_PEER_INSTANCES = {}
	GLOBAL_TICK = 0
	# World Variables
	WORLD_SEED = 0

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
