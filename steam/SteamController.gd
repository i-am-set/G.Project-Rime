extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	Steam.steamInit()
	
	var steamRunning = Steam.isSteamRunning()
	if !steamRunning:
		print("Steam is not running. Please run steam for this integration to work.")
		# Show an alert
		OS.alert("Steam is not running.\nPlease run steam for this integration to work.", "Steam not running.")
		# Quit the game
		get_tree().quit()
		return
	if Steam.getSteamID() <= 0:
		print("Steam has not fully initualized and/or no valid Steam ID was found.")
		# Show an alert
		OS.alert("Steam has not fully initualized and/or no valid Steam ID was found.", "Failure to find Steam ID")
		# Quit the game
		get_tree().quit()
		return
	
	var _userId = Steam.getSteamID()
	var _name = Steam.getFriendPersonaName(_userId)
	print("Your steam name is " + _name)
