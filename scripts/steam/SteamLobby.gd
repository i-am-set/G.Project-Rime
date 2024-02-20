extends Node

enum lobby_status {Private, Friends, Public, Invisible}
enum search_distance {Close, Default, Far, Worldwide}

@onready var steamName = $SteamName
@onready var lobbySetName = $CreateLobby/LobbySetName
@onready var lobbyGetName = $Chat/ChatName
@onready var lobbyChatOutput = $Chat/ChatOutput
@onready var lobbyPopup = $LobbyPopup
@onready var lobbyList = $LobbyPopup/Scroll/VBox
@onready var playerCount = $Players/PlayerCount
@onready var playerList = $Players/PlayerList
@onready var chatInput = $SendMessage/LineEdit
func _ready():
	# set steam name on screen
	steamName.text = Global.STEAM_NAME
	# Steamwork connections
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_message.connect(_on_lobby_message)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.join_requested.connect(_on_lobby_join_Requested)
	Steam.lobby_invite.connect(_on_lobby_invite)
	#Steam.persona_state_change.connect(_on_persona_change)
	
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	#Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
#
	## Check for command line arguments
	check_command_line()

func _physics_process(delta):
	# If the player is connected, read packets
	if Global.LOBBY_ID > 0:
		read_all_p2p_packets()
	
	if Global.GLOBAL_TICK % 40 == 0:
		get_lobby_members()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter"):
		send_chat_message()

#################
### Functions ###
#################

func create_lobby() -> void:
	# Make sure a lobby is not already set
	if lobbySetName.text != "":
		if Global.LOBBY_ID == 0:
			Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, Global.LOBBY_MAX_MEMBERS)


func join_lobby(this_lobby_id):
	#lobbyPopup.hide()
	var _name = Steam.getLobbyData(this_lobby_id, "name")
	display_message("Joining lobby " + str(_name) + "...")
	
	# Clear previous lobby members lists
	Global.LOBBY_MEMBERS.clear()
	
	# Steam join request
	Steam.joinLobby(this_lobby_id)


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


func send_chat_message():
	# Get chat input
	var this_message = chatInput.text
	# Pass message to steam
	if this_message != "":
		var is_sent = Steam.sendLobbyChatMsg(Global.LOBBY_ID, this_message)
	# Check message sent
		if not is_sent:
			display_message("ERROR: Chat message failed to send")
	# Clear chat input
	chatInput.text = ""


func leave_lobby():
	# If in a lobby, leave it
	if Global.LOBBY_ID != 0:
		display_message("Leaving lobby...")
		# Send leave request
		Steam.leaveLobby(Global.LOBBY_ID)
		
		lobbyGetName.text = "Lobby Name"
		playerCount.text = "Players (0)"
		playerList.clear()
		
		# Close session with all users
		for member in Global.LOBBY_MEMBERS:
			Steam.closeP2PSessionWithUser(member["steam_id"])
		await get_tree().process_frame
		
		# Wipe lobby data
		Global.leave_lobby()
		
		# Clear lobby list
		Global.LOBBY_MEMBERS.clear()


func generate_height_map(seed : int) -> NoiseTexture2D:
	var texture = NoiseTexture2D.new()
	var fastNoiseLite = FastNoiseLite.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	fastNoiseLite.seed = seed
	fastNoiseLite.frequency = 0.0075
	fastNoiseLite.fractal_octaves = 5
	texture.noise = fastNoiseLite
	
	return texture


func initialize_game(seed):
	var texture = generate_height_map(seed)
	# Cement changes
	Global.WORLD_SEED = seed
	Heightmap.set_height_map(texture)
	# Await processing
	await get_tree().process_frame


func display_message(message):
	if lobbyChatOutput.text == "":
		lobbyChatOutput.text += (str(message))
		return
	lobbyChatOutput.add_text("\n" + str(message))


func read_all_p2p_packets(read_count: int = 0):
	if read_count >= Global.PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)


func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")

	send_p2p_packet(0, {"message": "handshake", "from": Global.STEAM_ID})



#######################
### Steam Callbacks ###
#######################

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	if connect == 1:
		# Set the lobby ID
		Global.LOBBY_ID = this_lobby_id
		Steam.setLobbyData(this_lobby_id, "is_started", "false")
		display_message("Created lobby: " + lobbySetName.text)

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(this_lobby_id, true)

		# Set lobby data
		Steam.setLobbyData(this_lobby_id, "name", lobbySetName.text)
		var _name = Steam.getLobbyData(this_lobby_id, "name")
		lobbyGetName.text = str(_name)

		## Allow P2P connections to fallback to being relayed through Steam if needed
		#var set_relay: bool = Steam.allowP2PPacketRelay(true)on_lobbyon_lobby
		#print("Allowing Steam to be relay backup: %s" % set_relay)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var _name = Steam.getLobbyData(this_lobby_id, "name")
		
		# Display that you joined
		display_message("Successfully joined lobby %s..." % _name)
		
		# Set this lobby ID as your lobby ID
		Global.LOBBY_ID = this_lobby_id
		
		lobbyGetName.text = str(_name)
		
		# Get the lobby members
		get_lobby_members()
		
		# Make the initial handshake
		make_p2p_handshake()
		
		# Put player in game if game is started
		if Steam.getLobbyData(this_lobby_id, "is_started") == "true":
			await initialize_game(int(Steam.getLobbyData(this_lobby_id, "world_seed")))
			await get_tree().change_scene_to_file("res://levels/level_007.tscn")
		
	# Else it failed for some reason
	else:
		# Get the failure reason
		var fail_reason: String
		
		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

		print("Failed to join this chat room: %s" % fail_reason)

		#Reopen the lobby list
		lobbyPopup.show()


func _on_lobby_join_Requested(this_lobby_id: int, friend_id: int) -> void:
	# Get the lobby owner's name
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	
	display_message("Joining %s's lobby ..." % owner_name)
	
	# Attempt to join the lobby
	join_lobby(this_lobby_id)


func _on_lobby_data_update(success, this_lobby_id, this_member_id, key):
	print("Success: " + str(success) + ", Lobby ID: " + str(this_lobby_id) + ", Member ID: " + str(this_member_id) + ", Key: " + str(key))


func _on_lobby_chat_update(this_lobby_id, changed_id, making_change_id, chat_state):
	# User who made lobby change
	var changer = Steam.getFriendPersonaName(making_change_id)
	
	# chat_state change made
	if chat_state == 1:
		display_message(str(changer) + " has joined the lobby.")
	elif chat_state == 2:
		display_message(str(changer) + " has left the lobby.")
	elif chat_state == 3:
		display_message(str(changer) + " has disconnected.")
	elif chat_state == 8:
		display_message(str(changer) + " has been kicked from the lobby.")
	elif chat_state == 16:
		display_message(str(changer) + " has been banned from the lobby.")
	else:
		display_message(str(changer) + " made an unknown change.")


func _on_lobby_match_list(these_lobbies: Array) -> void:
	print("started list")
	for this_lobby in these_lobbies:
		print(this_lobby)
		# Pull lobby data from Steam
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")

		# Get the current number of members
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)

		# Create a button for the lobby
		var lobby_button_text: RichTextLabel = RichTextLabel.new()
		var lobby_button_margin_container : MarginContainer = MarginContainer.new()
		var lobby_button : Button = Button.new()
		
		lobby_button_text.add_child(lobby_button_margin_container)
		lobby_button_margin_container.add_child(lobby_button)
		
		lobby_button_text.bbcode_enabled = true
		lobby_button_text.custom_minimum_size = Vector2(900, 53)
		lobby_button_margin_container.custom_minimum_size = Vector2(900, 53)
		lobby_button.custom_minimum_size = Vector2(900, 53)
		lobby_button_text.text = ("[center]Lobby %s: %s - %s Player(s)" % [this_lobby, lobby_name, lobby_num_members])
		#lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.connect("pressed", Callable(self, "join_lobby").bind(this_lobby))

		# Add the new lobby to the list
		lobbyList.add_child(lobby_button_text)

func _on_lobby_message(result, user, message, type):
	# Sender and their message
	var sender = Steam.getFriendPersonaName(user)
	display_message(str(sender) + " : " + str(message))


func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)

	# Make the initial handshake
	make_p2p_handshake()


func _on_p2p_session_connect_fail(steam_id: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % steam_id)

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % steam_id)

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % steam_id)

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % steam_id)

	# Else no known error
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])

func _on_lobby_invite(inviter, lobby, game):
	display_message(str(inviter) + str(lobby) + str(game))

#func _on_open_lobby_list_pressed() -> void:
	## Set distance to worldwide
	#Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
#
	#print("Requesting a lobby list")
	#Steam.requestLobbyList()


## A user's information has changed
#func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	## Make sure you're in a lobby and this user is valid or Steam might spam your console log
	#if lobby_id > 0:
		#print("A user (%s) had information change, update the lobby list" % this_steam_id)
#
		## Update the player list
		#get_lobby_members()
#
#


###############################
### Button Signal Functions ###
###############################

func _on_create_lobby_pressed():
	create_lobby()


func _on_join_lobby_pressed():
	lobbyPopup.show()
	# Set server search distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(int(search_distance.Worldwide))
	display_message("Searching for lobbies...")
	
	Steam.requestLobbyList()


func _on_start_game_pressed():
	var seed = randi_range(1, 999999999999)
	Global.WORLD_SEED = seed
	Steam.setLobbyData(Global.LOBBY_ID, "world_seed", str(seed))
	await get_tree().process_frame
	send_p2p_packet(-1, {"message" : "start_game"})


func _on_leave_lobby_pressed():
	leave_lobby()


func _on_send_message_pressed():
	send_chat_message()


func _on_close_popup_pressed():
	lobbyPopup.hide()


#############################
### Command Line Arugment ###
#############################

func check_command_line() -> void:
	var ARGUMENTS: Array = OS.get_cmdline_args()

	# There are arguments to process
	if ARGUMENTS.size() > 0:
		for argument in ARGUMENTS:
			# Invite argument passed
			if Global.LOBBY_INVITE_ARG:
				join_lobby(int(argument))
			
			# Steam connection argument
			if argument == "connect_lobby":
				Global.LOBBY_INVITE_ARG = true

#---------------------------------------------------------------------------#

func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0

	# Create a data array to send the data through
	var this_data: PackedByteArray

	# Compress the PackedByteArray we create from our dictionary  using the GZIP compression method
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)
	
	# If sending a packet to everyone
	if target == -1:
		# Loop through all members that aren't you
		for this_member in Global.LOBBY_MEMBERS:
			Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)
	# If sending a packet to everyone but self
	if target == 0:
		# If there is more than one user, send packets
		if Global.LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for this_member in Global.LOBBY_MEMBERS:
				if this_member['steam_id'] != Global.STEAM_ID:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)

	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, this_data, send_type, channel)


func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)

	# There is a packet
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)

		if this_packet.is_empty() or this_packet == null:
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var packet_sender: int = this_packet['steam_id_remote']

		# Make the packet data readable
		var packet_code: PackedByteArray = this_packet['data']

		# Decompress the array before turning it into a useable dictionary
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))

		# Print the packet to output
		print("Packet: %s" % readable_data)

		# Append logic here to deal with packet data
		process_data(readable_data)


func process_data(packet_data : Dictionary):
	if packet_data.has("message"):
		if packet_data["message"] == "start_game":
			await initialize_game(int(Steam.getLobbyData(Global.LOBBY_ID, "world_seed")))
			Steam.setLobbyData(Global.LOBBY_ID, "is_started", "true")
			await get_tree().change_scene_to_file("res://levels/level_007.tscn")
