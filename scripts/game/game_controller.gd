extends Node

var _player_node = preload("res://scenes/fps_controller.tscn")
var _chat = preload("res://scenes/game_chat_controller.tscn")
var _player_list = preload("res://scenes/game_player_list_controller.tscn")

@onready var _collision_map = $Terrain/Collisionmap
@onready var _clip_map = $Terrain/Clipmap
@onready var _resource_instancer = $ResourceInstancer

var _chat_instance : Control
var _player_list_instance : Control
var _authorized_player : Player

var noise : FastNoiseLite = preload('res://world/heightmap/resource_noise.tres')
var resource_data : Dictionary = {}
var is_generating_resources : bool = false
var generation_cycle : int

func _ready():
	# Steamwork connections
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_message.connect(_on_lobby_message)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	
	## Check for command line arguments
	check_command_line()
	
	# initialize game chat and player list
	_chat_instance = _chat.instantiate()
	add_child(_chat_instance)
	_player_list_instance = _player_list.instantiate()
	add_child(_player_list_instance)
	
	# initialize player
	if Global.LOBBY_MEMBERS.size() > 1:
		for this_member in Global.LOBBY_MEMBERS:
			if this_member['steam_id'] != Global.STEAM_ID:
				print("creating player %s" %this_member['steam_id'])
				var player_instance = _player_node.instantiate()
				player_instance._steam_ID = this_member['steam_id']
				player_instance._deauthorize_user()
				player_instance.strip_into_peer()
				Global.LOBBY_PEER_INSTANCES[this_member['steam_id']] = player_instance
				add_child(player_instance)
				player_instance.global_transform.origin = Vector3(-5, 10, 0)
			else:
				print("creating self with friends")
				var player_instance = _player_node.instantiate()
				player_instance._steam_ID = this_member['steam_id']
				player_instance._authorize_user()
				player_instance.VISOR.visible = false
				_authorized_player = player_instance
				attach_player_to_world(player_instance)
				add_child(player_instance)
				player_instance.global_transform.origin = Vector3(5, 10, 0)
	else:
		print("creating self alone")
		var player_instance = _player_node.instantiate()
		player_instance._steam_ID = Global.STEAM_ID
		player_instance._authorize_user()
		player_instance.VISOR.visible = false
		_authorized_player = player_instance
		attach_player_to_world(player_instance)
		add_child(player_instance)
		player_instance.global_transform.origin = Vector3(5, 10, 0)
		print("self created")
	
	noise.seed = Global.WORLD_SEED

func _physics_process(delta):
	# If the player is connected, read packets
	if Global.LOBBY_ID > 0:
		read_all_p2p_packets()
	
	# Do stuff every 40 global ticks
	if Global.GLOBAL_TICK % 40 == 0:
		get_lobby_members()
		if !is_generating_resources:
			is_generating_resources = true
			generate_local_resources()


func _input(event):
	if Input.is_action_just_pressed("ui_scroll_up"):
		pass

func display_message(message):
	_chat_instance.display_message(message)

func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")
	send_p2p_packet(0, {"message": "handshake", "from": Global.STEAM_ID})

func get_lobby_members() -> void:
	_player_list_instance.get_lobby_members()

func add_player_list(this_steam_id, this_steam_name):
	_player_list_instance.add_player_list(this_steam_id, this_steam_name)

func join_lobby(this_lobby_id):
	#lobbyPopup.hide()
	var _name = Steam.getLobbyData(this_lobby_id, "name")
	display_message("Joining lobby " + str(_name) + "...")
	
	# Clear previous lobby members lists
	Global.LOBBY_MEMBERS.clear()
	
	# Steam join request
	Steam.joinLobby(this_lobby_id)

func leave_lobby():
	# If in a lobby, leave it
	if Global.LOBBY_ID != 0:
		display_message("Leaving lobby...")
		# Send leave request
		Steam.leaveLobby(Global.LOBBY_ID)
		# Wipe LOBBY_ID
		Global.LOBBY_ID = 0
		
		_player_list_instance.leave_lobby()
		
		# Close session with all users
		for member in Global.LOBBY_MEMBERS:
			Steam.closeP2PSessionWithUser(member["steam_id"])
		
		# Clear lobby list
		Global.LOBBY_MEMBERS.clear()

func read_all_p2p_packets(read_count: int = 0):
	if read_count >= Global.PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

func attach_player_to_world(player_instance: Node3D):
	_collision_map.physics_body = player_instance
	_clip_map.player_character = player_instance

func generate_local_resources():
	var _authorized_player_position = _authorized_player.position
	var _authorized_player_resource_spawn_radius = _authorized_player._resource_spawn_radius
	var _authorized_player_resource_spawn_radius_half = _authorized_player_resource_spawn_radius*0.5

	for x in range(_authorized_player_position.x-(_authorized_player_resource_spawn_radius_half), _authorized_player_position.x+(_authorized_player_resource_spawn_radius_half)):
		for z in range(_authorized_player_position.z-(_authorized_player_resource_spawn_radius_half), _authorized_player_position.z+(_authorized_player_resource_spawn_radius_half)):
			var height = noise.get_noise_2d(x, z) * 100
			if height > 0.4 && !resource_data.has(Vector3(x, Heightmap.get_height(x, z), z)):
				var tree = _resource_instancer.instantiate_resource(height*100)
				tree.position = Vector3(x, Heightmap.get_height(x, z), z)
				resource_data[tree.position] = tree
				generation_cycle += 1
				if generation_cycle >= 5:
					generation_cycle = 0
					await get_tree().process_frame
	
	for resource_location in resource_data:
		if resource_data[resource_location] == null:
			continue
		var distance = Vector2(resource_location.x, resource_location.z).distance_to(Vector2(_authorized_player_position.x, _authorized_player_position.z))
		if distance < _authorized_player_resource_spawn_radius and resource_data[resource_location].get_parent() == null:
			add_child(resource_data[resource_location])
		elif distance >= _authorized_player_resource_spawn_radius and resource_data[resource_location].get_parent() != null:
			remove_child(resource_data[resource_location])
		
	
	is_generating_resources = false


func replenish_resources():
	var tempNode
	for node in resource_data:
		if resource_data.has(tempNode):
			resource_data.erase(tempNode)
		remove_child(resource_data[node])
		resource_data[node].queue_free()
		tempNode = node
	if resource_data.has(tempNode):
		resource_data.erase(tempNode)

#######################
### Steam Callbacks ###
#######################

func _on_lobby_chat_update(this_lobby_id, changed_id, making_change_id, chat_state):
	# User who made lobby change
	var changer = Steam.getFriendPersonaName(making_change_id)
	
	# chat_state change made
	if chat_state == 1:
		if making_change_id != Global.STEAM_ID:
				print("creating player %s" %making_change_id)
				var player_instance = _player_node.instantiate()
				player_instance._steam_ID = making_change_id
				player_instance._deauthorize_user()
				player_instance.strip_into_peer()
				Global.LOBBY_PEER_INSTANCES[making_change_id] = player_instance
				add_child(player_instance)
				player_instance.global_transform.origin = Vector3(-5, 10, 0)
		display_message(str(changer) + " has joined the lobby.")
	elif chat_state == 2:
		remove_child(Global.LOBBY_PEER_INSTANCES[making_change_id])
		Global.LOBBY_PEER_INSTANCES[making_change_id].queue_free()
		display_message(str(changer) + " has left the lobby.")
	elif chat_state == 3:
		remove_child(Global.LOBBY_PEER_INSTANCES[making_change_id])
		Global.LOBBY_PEER_INSTANCES[making_change_id].queue_free()
		display_message(str(changer) + " has disconnected.")
	elif chat_state == 8:
		remove_child(Global.LOBBY_PEER_INSTANCES[making_change_id])
		Global.LOBBY_PEER_INSTANCES[making_change_id].queue_free()
		display_message(str(changer) + " has been kicked from the lobby.")
	elif chat_state == 16:
		remove_child(Global.LOBBY_PEER_INSTANCES[making_change_id])
		Global.LOBBY_PEER_INSTANCES[making_change_id].queue_free()
		display_message(str(changer) + " has been banned from the lobby.")
	else:
		display_message(str(changer) + " made an unknown change.")

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var _name = Steam.getLobbyData(this_lobby_id, "name")
		
		# Set this lobby ID as your lobby ID
		Global.LOBBY_ID = this_lobby_id
		
		# Get the lobby members
		get_lobby_members()
		
		## Make the initial handshake
		make_p2p_handshake()
		
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

		print("Failed to join lobby: %s" % fail_reason)

func _on_lobby_message(result, user, message, type):
	# Sender and their message
	var sender = Steam.getFriendPersonaName(user)
	display_message(str(sender) + " : " + str(message))

func _on_lobby_data_update(success, this_lobby_id, this_member_id, key):
	print("Success: " + str(success) + ", Lobby ID: " + str(this_lobby_id) + ", Member ID: " + str(this_member_id) + ", Key: " + str(key))


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

#------------------------------------------------------------------#

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
		if packet_data["message"] == "move":
			if packet_data.has("steam_id") && Global.LOBBY_PEER_INSTANCES.has(packet_data["steam_id"]):
				var player_instance = Global.LOBBY_PEER_INSTANCES[packet_data["steam_id"]]
				if packet_data.has("player_position"):
					player_instance.global_position = packet_data["player_position"]
				if packet_data.has("player_rotation"):
					player_instance.rotation = packet_data["player_rotation"]
