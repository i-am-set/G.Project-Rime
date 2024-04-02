class_name Player

extends CharacterBody3D

@onready var PLAYER_MODEL : Node3D = get_node("CollisionShape3D/player_model")
@onready var LEGS_MODEL : Node3D = get_node("CollisionShape3D/legs_model")
@onready var PAUSE_MENU = $UserInterface/PauseMenu
@onready var CONSOLE_MENU = $UserInterface/ConsoleMenu
@onready var POSTP_DITHER = $PostProcessingDither
@onready var POSTP_OUTLINE = $PostProcessingOutline

@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var ANIMATIONPLAYER : AnimationPlayer
@export var CROUCH_SHAPECAST : ShapeCast3D
@export var PLAYERSTATEMACHINE : StateMachine
@export var USERINTERFACE : Control
@export var WEAPONVIEWPORT : SubViewportContainer
@export var GRASS_EMITTER : GPUParticles3D

var _is_authorized_user : bool = false

var _no_clip : bool = false

var _mouse_input : bool = false
var look_dir: Vector2 # Input direction for look/aim
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _camera_rotation : Vector3
var _cached_position : Vector3
var _cached_rotation : Vector3 
var _steam_ID : int
var _resource_spawn_radius : int

var _current_rotation : float

# Get the gravity from the project s ettings to be synced with RigidBody nodes.
var gravity = 9.8

func _authorize_user():
	_is_authorized_user = true
	PLAYER_MODEL= get_node("CollisionShape3D/player_model")
	LEGS_MODEL = get_node("CollisionShape3D/legs_model")
	PLAYER_MODEL.visible = false
	LEGS_MODEL.visible = true

func _deauthorize_user():
	_is_authorized_user = false
	PLAYER_MODEL= get_node("CollisionShape3D/player_model")
	LEGS_MODEL = get_node("CollisionShape3D/legs_model")
	PLAYER_MODEL.visible = true
	LEGS_MODEL.visible = false

func strip_into_peer():
	remove_child(CAMERA_CONTROLLER)
	CAMERA_CONTROLLER.queue_free()
	remove_child(ANIMATIONPLAYER)
	ANIMATIONPLAYER.queue_free()
	remove_child(CROUCH_SHAPECAST)
	CROUCH_SHAPECAST.queue_free()
	remove_child(USERINTERFACE)
	USERINTERFACE.queue_free()
	remove_child(WEAPONVIEWPORT)
	WEAPONVIEWPORT.queue_free()
	remove_child(PLAYERSTATEMACHINE)
	PLAYERSTATEMACHINE.queue_free()

func _input(event):
	if event.is_action_pressed("ui_scroll_up"):
		print_debug("scroll up")
	if event.is_action_pressed("ui_scroll_down"):
		print_debug("scroll down")

func _unhandled_input(event: InputEvent) -> void:
	if _is_authorized_user == true:
		if event.is_action_pressed("mouse_click") && !Global.IS_PAUSED:
			capture_mouse()
		elif event.is_action_pressed("exit"):
			toggle_pause_menu()
			if (CONSOLE_MENU.visible):
				CONSOLE_MENU.toggle_debug_console()
		elif event.is_action_pressed("debug"):
			CONSOLE_MENU.toggle_debug_console()
		
		if event is InputEventMouseMotion && Global.MOUSE_CAPTURED == true:
			look_dir = event.relative * 0.001
			_rotate_camera()

func toggle_pause_menu():
	PAUSE_MENU.visible = !PAUSE_MENU.visible
	
	if PAUSE_MENU.visible:
		uncapture_mouse()
		Global.IS_PAUSED = true
	else:
		capture_mouse()
		Global.IS_PAUSED = false

func capture_mouse():
	Global.capture_mouse(true)

func uncapture_mouse():
	Global.capture_mouse(false)

func _rotate_camera(sens_mod: float = 1.0) -> void:
	if  Global.IS_PAUSED == true:
		return
		
	self.rotation.y -= look_dir.x * MOUSE_SENSITIVITY
	CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x - look_dir.y * MOUSE_SENSITIVITY, -1.5, 1.5)
	
func _ready():
	if _is_authorized_user == true:
		capture_mouse()
		
		set_settings()
		
		Global.player = self
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		_steam_ID = Steam.getSteamID()
		
		CROUCH_SHAPECAST.add_exception($".")
		
		if CAMERA_CONTROLLER != null:
			set_fov(Global.FIELD_OF_VIEW)
		enable_postp_dither(Global.POSTP_DITHER_ON)
		enable_postp_dither(Global.POSTP_OUTLINE_ON)
		
		# Set console commands
		Console.create_command("no_clip", self.c_set_no_clip, "Toggles no_clip for self.")
		Console.create_command("seed", self.c_get_world_seed, "Gets the world seed")
		Console.create_command("get_self_position", self.c_get_current_position_self, "Gets the current position of self.")
		Console.create_command("get_player_position", self.c_get_current_position_peer, "Gets the current position of the specified player.")
		Console.create_command("tpc", self.c_teleport_self_to_coordinate, "Teleports your player to the given world coordinate by x, y, z vectors.")
		Console.create_command("tp_to", self.c_teleport_self_to_player, "Teleports your player to the specified player by name.")
		Console.create_command("tp", self.c_teleport_player_to_player, "Teleports the first specified player to the second specified player by name.")
		Console.create_command("fov", self.c_set_fov, "Sets the FOV of the camera. " + str(Global.MIN_FOV) + " is minimum; " + str(Global.MAX_FOV) + " is maximum; " + str(Global.DEFAULT_FOV) + " is default")
		Console.create_command("postp_enable_dither", self.c_enable_postp_dither, "Toggles the dithering post process effect. Takes a true or false.")
		Console.create_command("postp_set_color_depth", self.c_set_postp_color_depth, "Sets the color depth post process effect. 1 is minimum; 8 is maximum; 6 is default.")
		Console.create_command("postp_enable_outline", self.c_enable_postp_outline, "Toggles the outline post process effect. Takes a true or false.")

func set_settings():
	RenderingServer.global_shader_parameter_set("fade_distance_max", Global.RENDER_DISTANCE*12)
	RenderingServer.global_shader_parameter_set("fade_distance_min", Global.RENDER_DISTANCE*9)
	#CAMERA_CONTROLLER.far = Global.RENDER_DISTANCE*12 # opt - see if this would have even helped performance; can't use it with the skybox
	_resource_spawn_radius = (Global.RENDER_DISTANCE*24)+20

func _physics_process(delta):
	if _is_authorized_user:
		Global.debug.add_property("Velocity","%.2f" % velocity.length(), 2)
		Global.debug.add_property("ShapeCast", CROUCH_SHAPECAST.is_colliding(), 2)
		Global.debug.add_property("Collision Pos", $CollisionShape3D.position , 2)
		Global.debug.add_property("Mouse Rotation", _rotation_input, 2)
		
		_cached_position = global_position
		_cached_rotation = rotation


func update_gravity(delta) -> void:
	if (_no_clip):
		pass
	else:
		velocity.y -= gravity * delta
	
func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	if _is_authorized_user == true:
		if _no_clip:
			if Input.is_action_pressed("sprint"):
				speed = speed * 6
			else:
				speed = speed * 3
			# Allow flying movement based on mouse direction
			var input_dir = Vector3.ZERO
			var camera_forward = Vector3.ZERO
			if Global.MOUSE_CAPTURED && !Global.IS_PAUSED:
				input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
				camera_forward = -CAMERA_CONTROLLER.global_transform.basis.z.normalized()
				
			var direction
			if Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
				direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			else:
				direction = camera_forward * -input_dir.y
			
			if direction:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration)
				velocity.y = lerp(velocity.y, direction.y * speed, acceleration)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration)
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.y = move_toward(velocity.y, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
			
			
			# Handle vertical movement
			if Input.is_action_pressed("jump"):
				velocity.y = speed  # Move up
			elif Input.is_action_pressed("crouch"):
				velocity.y = -speed  # Move down
		else:
			var input_dir = Vector3.ZERO
			if (Global.MOUSE_CAPTURED == true) && !Global.IS_PAUSED:
				input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
			
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			
			if direction:
				velocity.x = lerp(velocity.x,direction.x * speed, acceleration)
				velocity.z = lerp(velocity.z,direction.z * speed, acceleration)
			else:
				velocity.x = move_toward(velocity.x, 0, deceleration)
				velocity.z = move_toward(velocity.z, 0, deceleration)
		
		move_and_slide()
		
		if global_position != _cached_position || rotation != _cached_rotation:
			send_p2p_packet(0, {"message": "move", "steam_id": _steam_ID, "player_position": global_position, "player_rotation": rotation})
	
func update_velocity() -> void:
	pass

func set_fov(fov : int) -> int:
	if fov < Global.MIN_FOV:
		fov = Global.MIN_FOV
	elif fov > Global.MAX_FOV:
		fov = Global.MAX_FOV
	
	Global.FIELD_OF_VIEW = fov
	CAMERA_CONTROLLER.fov = fov
	
	return fov

func enable_postp_dither(toggle : bool) -> void:
	POSTP_DITHER.get_surface_override_material(0).set_shader_parameter("dithering", toggle)
	Global.POSTP_DITHER_ON = toggle

func set_postp_color_depth(depth : int) -> void:
	depth = clamp(depth, 1, 8)
	POSTP_DITHER.get_surface_override_material(0).set_shader_parameter("color_depth", depth)

func enable_postp_outline(toggle : bool) -> void:
	POSTP_OUTLINE.visible = toggle
	Global.POSTP_OUTLINE_ON = toggle

func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_UNRELIABLE
	var channel: int = 0
	
	# Create a data array to send the data through
	var this_data: PackedByteArray
	
	# Compress the PackedByteArray we create from our dictionary  using the GZIP compression method
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)
	
	# If sending a packet to everyone
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

func c_get_world_seed():
	Console.print_line("Global seed:" + str(Global.WORLD_SEED))
	Console.print_line("Global seed:" + Steam.getLobbyData(Global.LOBBY_ID, "world_seed"))

func c_set_no_clip() -> void:
	_no_clip = !_no_clip
	
	if (_no_clip == true):
		Console.print_line("No clip was enabled.")
	else:
		Console.print_line("No clip was disabled.")
	
	if get_collision_mask_value(1) == _no_clip:
		set_collision_mask_value(1, !_no_clip)

func c_set_fov(fov : int) -> void:
	fov = set_fov(fov)
	
	Console.print_line("Field of view set to " + str(fov) + ".")

func c_enable_postp_dither(toggle : bool) -> void:
	enable_postp_dither(toggle)
	
	Console.print_line("Post process 'dither' was toggled " + str(toggle) + ".")

func c_set_postp_color_depth(depth : int) -> void:
	set_postp_color_depth(depth)
	
	Console.print_line("Post process 'color depth' was set to " + str(depth) + ".")

func c_enable_postp_outline(toggle : bool) -> void:
	enable_postp_outline(toggle)
	
	Console.print_line("Post process 'outline' was toggled " + str(toggle) + ".")

func c_get_current_position_self() -> void:
	Console.print_line("[color=GOLD]Your current world position is " + str(position) + ".[/color]")

func c_get_current_position_peer(player_name : String) -> void:
	for player in Global.LOBBY_MEMBERS:
		if player["steam_name"] == player_name:
			var player_id = player["steam_id"]
			if Global.LOBBY_PEER_INSTANCES.has(player_id):
				Console.print_line("[color=GOLD]" + player_name + "'s current world position is " + str(Global.LOBBY_PEER_INSTANCES[player_id].position) + ".[/color]")
			return
	Console.print_line("[color=RED]'" + player_name + "' is not a valid player name.[/color]")
	

func c_teleport_self_to_coordinate(x: float, y: float, z: float) -> void:
	# Teleport self to given objects position
	if (position != null):
		position = Vector3(x, y, z)
	else:
		if (position == null):
			Console.print_line("Failed to find player position")

func c_teleport_self_to_player(des_player_name : String) -> void:
	# Teleport self to given objects position
	if (position != null):
		for player in Global.LOBBY_MEMBERS:
			if player["steam_name"] == des_player_name:
				var des_player_id = player["steam_id"]
				if Global.LOBBY_PEER_INSTANCES.has(des_player_id):
					var des_player_pos : Vector3 = Global.LOBBY_PEER_INSTANCES[des_player_id].position
					position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
					Console.print_line("Teleported to '" + des_player_name + "'.")
				elif Global.STEAM_ID == des_player_id:
					var des_player_pos : Vector3 = position
					position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
					Console.print_line("Teleported to '" + des_player_name + "' (self).")
				return
		Console.print_line("[color=RED]'" + des_player_name + "' is not a valid player name.[/color]")
	else:
		Console.print_line("[color=RED]Failed to find player position[/color]")

func c_teleport_player_to_player(ori_player_name : String, des_player_name : String) -> void:
	var ori_is_self = false
	var des_is_self = false
	
	var ori_player_id = 0
	var des_player_id = 0
	
	var des_player_pos = Vector3.ZERO
	
	for player in Global.LOBBY_MEMBERS:
		if ori_player_id == 0:
			if player["steam_name"] == ori_player_name:
				ori_player_id = player["steam_id"]
		if des_player_id == 0:
			if player["steam_name"] == des_player_name:
				des_player_id = player["steam_id"]
	
	if Global.STEAM_ID == ori_player_id || ori_player_name == "self" || ori_player_name == "_":
		ori_is_self = true
	if Global.STEAM_ID == des_player_id || des_player_name == "self" || des_player_name == "_":
		des_is_self = true
		
	if ori_player_id == 0 && des_player_id == 0 && !ori_is_self && !des_is_self:
		Console.print_line("[color=RED]'" + ori_player_name + "and" + des_player_name + "' are not a valid player names.[/color]")
	elif ori_player_id == 0 && !ori_is_self:
		Console.print_line("[color=RED]'" + ori_player_name + "' is not a valid player name.[/color]")
	elif des_player_id == 0 && !des_is_self:
		Console.print_line("[color=RED]'" + des_player_name + "' is not a valid player name.[/color]")
	
	if Global.LOBBY_PEER_INSTANCES.has(ori_player_id) || ori_is_self:
		if ori_is_self:
			if Global.LOBBY_PEER_INSTANCES.has(des_player_id) || des_is_self:
				if des_is_self:
					des_player_pos = position
					position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
					Console.print_line("Teleported '" + Global.STEAM_NAME + "' (self) to '" + Global.STEAM_NAME + "' (self).")
					return
				
				des_player_pos = Global.LOBBY_PEER_INSTANCES[des_player_id].position
				position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
				Console.print_line("Teleported '" + Global.STEAM_NAME + "' (self) to '" + des_player_name + "'.")
		
		if Global.LOBBY_PEER_INSTANCES.has(des_player_id) || des_is_self:
			if des_is_self:
				des_player_pos = position
				Global.LOBBY_PEER_INSTANCES[ori_player_id].position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
				Console.print_line("Teleported '" + ori_player_name + "' to '" + Global.STEAM_NAME + "' (self).")
			
			des_player_pos = Global.LOBBY_PEER_INSTANCES[des_player_id].position
			Global.LOBBY_PEER_INSTANCES[ori_player_id].position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
			Console.print_line("Teleported '" + ori_player_name + "' to '" + des_player_name + "'.")
