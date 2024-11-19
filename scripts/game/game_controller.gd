extends Node

const GROUND_ITEM = preload("res://scenes/maingame/ground_item.tscn")

@onready var sky_box = $SkyBox
@onready var entities = $Entities
@onready var ground_objects = $GroundObjects

var _player_node = preload("res://scenes/fps_controller.tscn")

@export var generated_terrain : Node3D

var _game_chat_controller : Control = DebugAutoloadCanvas.game_chat_controller
var _game_player_list_controller : Control = DebugAutoloadCanvas.game_player_list_controller
var _authorized_player : Player
var _is_server_host : bool = false # hack - if the host leaves, the server persists which is good, but there is then no "server host". Need to set one of the players in game to be next in line to be server host.

# wind variable
var raw_wind_direction : Vector2 = Vector2.RIGHT
var wind_speed : float = 0.01
var wind_acceleration : float = 0.001
var wind_acceleration_current_step : int = 0
var wind_acceleration_change_step : int = 120

func _ready():
	# misc signals
	sky_box.temperature_set.connect(_on_skybox_temperature_set)
	
	# Steamwork connections
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_message.connect(_on_lobby_message)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	
	## Check for command line arguments
	check_command_line()
	
	## Check server host
	check_if_server_host()
	
	# initialize player
	Global.IS_IN_GAME = true
	if Global.LOBBY_MEMBERS.size() > 1:
		for this_member in Global.LOBBY_MEMBERS:
			print_debug(this_member)
			if this_member['steam_id'] != Global.STEAM_ID:
				print_debug("creating player %s" %this_member['steam_id'])
				var player_instance = _player_node.instantiate()
				player_instance._steam_ID = this_member['steam_id']
				player_instance._deauthorize_user()
				player_instance.strip_into_peer()
				Global.LOBBY_PEER_INSTANCES[this_member['steam_id']] = player_instance
				entities.add_child(player_instance)
				player_instance.global_transform.origin = Vector3(Global.SPAWN_POINT.x, 100, Global.SPAWN_POINT.y)
			else:
				print_debug("creating self with friends")
				var player_instance = _player_node.instantiate()
				player_instance._steam_ID = this_member['steam_id']
				player_instance._authorize_user()
				_authorized_player = player_instance
				HyperLog.camera_3d = player_instance.CAMERA_CONTROLLER
				entities.add_child(player_instance)
				player_instance.global_transform.origin = Vector3(Global.SPAWN_POINT.x, 100, Global.SPAWN_POINT.y)
	else:
		print_debug("creating self alone")
		var player_instance = _player_node.instantiate()
		player_instance._steam_ID = Global.STEAM_ID
		player_instance._authorize_user()
		_authorized_player = player_instance
		HyperLog.camera_3d = player_instance.CAMERA_CONTROLLER
		entities.add_child(player_instance)
		player_instance.global_transform.origin = Vector3(Global.SPAWN_POINT.x, 100, Global.SPAWN_POINT.y)
		print_debug("self created")
	
	generated_terrain.viewer = _authorized_player;
	
	initialize()
	
	# Set console commands
	Console.create_command("time_set", self.c_set_time, "Sets the current world time. 0/2399 is midnight; 1200 is noon")
	Console.create_command("get_current_time", self.c_get_current_time, "Returns the current time.")
	Console.create_command("simulate_time", self.c_simulate_time, "Toggles whether or not the day cycle is simulated; Default is true")
	Console.create_command("get_current_temperature", self.c_get_current_temperature, "Returns the expected high for the day; the expected low for the day; and the current temperature")
	Console.create_command("graphics_enable_sdfgi", self.c_enable_enviroment_sdfgi, "Toggles the graphical setting 'SDFGI'; Default is true")
	Console.create_command("graphics_enable_glow", self.c_enable_enviroment_glow, "Toggles the graphical setting 'GLOW'; Default is true")
	Console.create_command("graphics_enable_fog", self.c_enable_enviroment_fog, "Toggles the graphical setting 'VOLUMETRIC FOG'; Default is true")

func _physics_process(delta: float) -> void:
	var _authorized_player_position = _authorized_player.position
	
	# If the player is connected, read packets
	if Global.LOBBY_ID != 0:
		read_all_p2p_packets()
	
	# Do stuff every 40 global ticks
	if Global.GLOBAL_TICK % 40 == 0:
		get_lobby_members()
	
	if _is_server_host: # server host only
		update_wind_direction(delta)
		if Global.GLOBAL_TICK % 450 == 0: # every 7.5 seconds of global ticks
			set_current_wind_direction()
		elif Global.GLOBAL_TICK % 18000 == 0: # every 5 minutes of global ticks
			sync_players()

func _input(_event):
	if Input.is_action_just_pressed("ui_scroll_up"):
		pass

func initialize():
	raw_wind_direction = Vector2.RIGHT.rotated(randf() * 2 * PI)
	set_current_wind_direction()

func display_message(message):
	_game_chat_controller.display_message(message)

func make_p2p_handshake() -> void:
	print_debug("Sending P2P handshake to the lobby")
	send_p2p_packet(0, {"message": "handshake", "from": Global.STEAM_ID})

func _on_skybox_temperature_set():
	send_p2p_packet(0, {"message": "temperature_set", "temperature_high": Global.TEMPERATURE_HIGH_C, "temperature_low": Global.TEMPERATURE_LOW_C})

func get_lobby_members() -> void:
	_game_player_list_controller.get_lobby_members()

func add_player_list(this_steam_id, this_steam_name):
	_game_player_list_controller.add_player_list(this_steam_id, this_steam_name)

func join_lobby(this_lobby_id):
	#lobbyPopup.hide()
	var _name = Steam.getLobbyData(this_lobby_id, "name")
	display_message("Joining lobby " + str(_name) + "...")
	
	# Clear previous lobby members lists
	Global.LOBBY_MEMBERS.clear()
	
	# Steam join request
	Steam.joinLobby(this_lobby_id)

func disconnect_from_game():
	await leave_lobby()
	await get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")

func leave_lobby():
	# If in a lobby, leave it
	if Global.LOBBY_ID != 0:
		display_message("Leaving lobby...")
		# Send leave request
		Steam.leaveLobby(Global.LOBBY_ID)
		# Wipe LOBBY_ID
		Global.LOBBY_ID = 0
		
		_game_player_list_controller.leave_lobby()
		
		# Close session with all users
		for member in Global.LOBBY_MEMBERS:
			Steam.closeP2PSessionWithUser(member["steam_id"])
		
		# Clear lobby list
		Global.LOBBY_MEMBERS.clear()

func sync_players(): # todo - make an icon that appears at the top of the screen when syncing hat fades out
	if _is_server_host:
		set_time(sky_box.timeOfDay)
		_on_skybox_temperature_set()

func set_time(set_time : int) -> int:
	send_p2p_packet(0, {"message": "time_set", "time": set_time})
	set_time %= 2400
	sky_box.timeOfDay = set_time
	
	return set_time

func recieve_set_time_request(set_time : int) -> void:
	set_time %= 2400
	sky_box.timeOfDay = set_time

func get_current_time() -> int:
	return sky_box.timeOfDay

func update_wind_direction(delta : float):
	if _is_server_host:
		wind_acceleration_current_step += 1
		if wind_acceleration_current_step >= wind_acceleration_change_step:
			wind_acceleration_current_step = 0
			wind_acceleration = randf_range(-0.05, 0.05)
		
		
		wind_speed += wind_acceleration * delta
		wind_speed = clamp(wind_speed, -0.05, 0.05)
		
		raw_wind_direction = raw_wind_direction.rotated(wind_speed * delta)

func set_current_wind_direction():
	Global.WIND_DIRECTION = raw_wind_direction
	send_p2p_packet(0, {"message": "set_wind_direction", "wind_direction": Global.WIND_DIRECTION})

func instance_combined_item(_combined_item_position : Vector3, _ground_inv_item : InventoryItem, _held_inv_item : InventoryItem):
	var combined_items_instance = Global.COMBINED_ITEMS_SCENE.instantiate()
	ground_objects.add_child(combined_items_instance)
	combined_items_instance.position = _combined_item_position
	
	combined_items_instance.create_combined_items(_ground_inv_item, _held_inv_item)

func instance_ground_item(_dropped_inv_item : InventoryItem, _stack_amount : int, _drop_position : Vector3, look_dir : Vector3):
	var _new_ground_item = GROUND_ITEM.instantiate()
	_new_ground_item.inv_item = _dropped_inv_item
	_new_ground_item.stack_amount = _stack_amount
	
	ground_objects.add_child(_new_ground_item)
	_new_ground_item.position = _drop_position
	_new_ground_item.rotation = Vector3(randf() * 2 * PI, randf() * 2 * PI, randf() * 2 * PI)
	
	if look_dir != Vector3.ZERO:
		var rigid_body = _new_ground_item as RigidBody3D
		if rigid_body:
			var throw_velocity = look_dir.normalized() * 3
			rigid_body.linear_velocity = throw_velocity

func check_if_server_host():
	var _lobby_id = Global.LOBBY_ID
	if _lobby_id != 0:
		if Steam.getLobbyData(_lobby_id, "owner_id") == str(Global.STEAM_ID) || _lobby_id == -1:
			_is_server_host = true
		else:
			_is_server_host = false
	else:
		printerr("No lobby id found...")

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
			print_debug("creating player %s" %making_change_id)
			var player_instance = _player_node.instantiate()
			player_instance._steam_ID = making_change_id
			player_instance._deauthorize_user()
			player_instance.strip_into_peer()
			Global.LOBBY_PEER_INSTANCES[making_change_id] = player_instance
			entities.add_child(player_instance)
			player_instance.global_transform.origin = Vector3(-5, 10, 0)
			await get_tree().process_frame
			sync_players()
			# send move packet to update position
			_authorized_player.send_move_packet()
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

		print_debug("Failed to join lobby: %s" % fail_reason)

func _on_lobby_message(result, user, message, type):
	# Sender and their message
	var sender = Steam.getFriendPersonaName(user)
	display_message(str(sender) + " : " + str(message))

func _on_lobby_data_update(success, this_lobby_id, this_member_id, key):
	print_debug("Success: " + str(success) + ", Lobby ID: " + str(this_lobby_id) + ", Member ID: " + str(this_member_id) + ", Key: " + str(key))


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
			print_debug("WARNING: read an empty packet with non-zero size!")
		# Get the remote user's ID
		var packet_sender: int = this_packet['steam_id_remote']
		# Make the packet data readable
		var packet_code: PackedByteArray = this_packet['data']
		# Decompress the array before turning it into a useable dictionary
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
		# Print the packet to output
		print_debug("Packet: %s" % readable_data)

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
				if packet_data.has("player_animation_value"):
					player_instance.player_animation_tree.set("parameters/MovementAnimBlend/blend_position", packet_data["player_animation_value"])
					player_instance.player_animation_tree.set("parameters/CrouchMovementAnimBlend/blend_position", packet_data["player_animation_value"])
				if packet_data.has("player_head_animation_value"):
					player_instance.player_animation_tree.set("parameters/looking_blend/blend_amount", packet_data["player_head_animation_value"])
				if packet_data.has("player_crouch_animation_value"):
					player_instance.player_animation_tree.set("parameters/CrouchAnimBlend/blend_amount", packet_data["player_crouch_animation_value"])
				if packet_data.has("player_crouch_animation_value"):
					player_instance.player_animation_tree.set("parameters/IsCrouching/blend_amount", packet_data["player_crouch_animation_value"])
		elif packet_data["message"] == "time_set":
			recieve_set_time_request(packet_data["time"])
		elif packet_data["message"] == "set_wind_direction":
			Global.WIND_DIRECTION = packet_data["wind_direction"]
		elif packet_data["message"] == "footstep":
			if packet_data.has("steam_id") && Global.LOBBY_PEER_INSTANCES.has(packet_data["steam_id"]):
				var player_instance = Global.LOBBY_PEER_INSTANCES[packet_data["steam_id"]]
				if packet_data["foot"] == 0:
					player_instance.sound_manager.footstep_left_logic()
				elif packet_data["foot"] == 1:
					player_instance.sound_manager.footstep_right_logic()
		elif packet_data["message"] == "temperature_set":
			Global.TEMPERATURE_HIGH == packet_data["temperature_high"]
			Global.TEMPERATURE_LOW == packet_data["temperature_low"]

#############################
##### Console Commands ######
#############################

func c_set_time(set_time : int) -> void:
	set_time = set_time(set_time)
	
	Console.print_line("Time set to " + str(set_time) + ".")

func c_get_current_time() -> void:
	Console.print_line("It is currently [color=GOLD]" + str(get_current_time()) + "[/color].")

func c_simulate_time(toggle : bool) -> void:
	sky_box.simulateTime = toggle
	
	Console.print_line("Simulate time was set to " + str(toggle) + ".")

func c_get_current_temperature() -> void:
	Console.print_line("\n------------------------------------------------------------------------------")
	Console.print_line("High of [color=CORAL]" + str(Global.get_temperature_high_display()) + " " + Global.get_temperature_sign_display() + "[/color]")
	Console.print_line("Low of [color=CORNFLOWER_BLUE]" + str(Global.get_temperature_low_display()) + " " + Global.get_temperature_sign_display() + "[/color]")
	Console.print_line("The current temperature is [color=FOREST_GREEN]" + str(Global.get_current_temperature_display()) + " " + Global.get_temperature_sign_display()  + "[/color]\n")
	
	Console.print_line("MAX: [color=DIM_GRAY]" + str(Global.get_temperature_max_display()) + " " + Global.get_temperature_sign_display()  + "[/color]")
	Console.print_line("MIN: [color=DIM_GRAY]" + str(Global.get_temperature_min_display()) + " " + Global.get_temperature_sign_display()  + "[/color]")
	Console.print_line("------------------------------------------------------------------------------\n")

func c_enable_enviroment_sdfgi(toggle : bool) -> void:
	sky_box.environment.sdfgi_enabled = toggle
	
	Console.print_line("Graphical setting 'SDFGI' was toggled " + str(toggle) + ".")

func c_enable_enviroment_glow(toggle : bool) -> void:
	sky_box.environment.glow_enabled = toggle
	
	Console.print_line("Graphical setting 'GLOW' was toggled " + str(toggle) + ".")

func c_enable_enviroment_fog(toggle : bool) -> void:
	sky_box.environment.volumetric_fog_enabled = toggle
	
	Console.print_line("Graphical setting 'VOLUMETRIC FOG' was toggled " + str(toggle) + ".")
