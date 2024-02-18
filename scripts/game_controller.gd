extends Node

var _player_node = preload("res://scenes/fps_controller.tscn")

func _ready():
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	
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
				add_child(player_instance)
				player_instance.global_transform.origin = Vector3(5, 10, 0)
	else:
		print("creating self alone")
		var player_instance = _player_node.instantiate()
		player_instance._steam_ID = Global.STEAM_ID
		player_instance._authorize_user()
		player_instance.VISOR.visible = false
		add_child(player_instance)
		player_instance.global_transform.origin = Vector3(5, 10, 0)
		print("self created")

func display_message(message):
	pass
	#lobbyOutput.add_text("\n" + str(message))

func _physics_process(delta):
	# If the player is connected, read packets
	if Global.LOBBY_ID > 0:
		read_all_p2p_packets()

func read_all_p2p_packets(read_count: int = 0):
	if read_count >= Global.PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

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
