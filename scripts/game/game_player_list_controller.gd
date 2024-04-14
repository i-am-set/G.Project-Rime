extends Control

@onready var playerList = $Players/PlayerList
@onready var playerCount = $Players/PlayerCount
@onready var playerListPanel = $Players


func _input(event):
	if Global.IS_IN_GAME:
		if Input.is_action_just_pressed("playerlist") && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE:
			hold_display_player_list()
		if !Input.is_action_pressed("playerlist") || Global.IS_PAUSED || Global.IS_IN_CONSOLE:
			playerListPanel.visible = false

func hold_display_player_list():
	if !Input.is_action_pressed("playerlist"):
		playerListPanel.visible = false
		return
	playerListPanel.visible = true

func get_lobby_members() -> void:
	# Clear your previous lobby list
	Global.LOBBY_MEMBERS.clear()
	
	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(Global.LOBBY_ID)
	# Update player list count
	playerCount.set_text("Players (" + str(num_of_members) + ")")
	
	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(Global.LOBBY_ID, this_member)
		
		# Get the member's Steam name
		var member_steam_name: String
		while member_steam_name == "":
			member_steam_name =  Steam.getFriendPersonaName(member_steam_id)
		
		# Add them to the list
		add_player_list(member_steam_id, member_steam_name)

func add_player_list(this_steam_id, this_steam_name):
	# Add players to list
	Global.LOBBY_MEMBERS.append({"steam_id":this_steam_id, "steam_name":this_steam_name})
	# Ensure list is cleared
	playerList.clear()
	# Populate player list
	for member in Global.LOBBY_MEMBERS:
		playerList.add_text(str(member["steam_name"]) + "\n")

func leave_lobby():
	playerCount.text = "Players (0)"
	playerList.clear()
