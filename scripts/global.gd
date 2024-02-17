extends Node

var debug # Reference to DebugPanel for debug property assignment
var player # Reference to PlayerController

const PACKET_READ_LIMIT: int = 32

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

func _ready():
	var INIT = Steam.steamInit()
	if INIT['status'] == 20:
		print("Steam is not running. Please run steam for this integration to work.")
		# Show an alert
		OS.alert("Initialization Status: " + str(INIT['status']) + "\n" + str(INIT['verbal']) + "\nPlease run steam for this integration to work.", "Steam not running.")
		# Quit the game
		get_tree().quit()
		return
	elif Steam.getSteamID() <= 0:
		print("Steam has not fully initualized and/or no valid Steam ID was found.")
		# Show an alert
		OS.alert("Steam has not fully initualized and/or no valid Steam ID was found.\nPlease wait for Steam to initualize and try again.", "Failure to find Steam ID")
		# Quit the game
		get_tree().quit()
		return
	elif INIT['status'] != 1:
		print("Steam is not running. Please run steam for this integration to work.")
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
		#print("User does not own this game.")
		#OS.alert("License not found.\nPlease purchase a copy of the game to proceed.", "Game is not owned.")
		#get_tree().quit()

func _process(delta):
	Steam.run_callbacks()
