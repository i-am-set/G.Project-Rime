class_name Player

extends CharacterBody3D

@onready var player_model = $CollisionShape3D/player_model
@onready var legs_model = $CollisionShape3D/legs_model
@onready var pause_menu = $UserInterface/PauseMenu
@onready var pause_animator = $UserInterface/PauseMenu/BlurAnimator
@onready var inventory_menu = $UserInterface/InventoryMenu
@onready var inventory_manager: InventoryManager = $UserInterface/InventoryMenu/InventoryPanel/MarginContainer/VBoxContainer/InventoryManager
@onready var POSTP_DITHER = $PostProcessingDither
@onready var POSTP_OUTLINE = $PostProcessingOutline
@onready var world = $"../.."
@onready var drop_position = $CameraController/Camera3D/DropPosition
@onready var look_at_ray_cast = $CameraController/Camera3D/LookAtRayCast
@onready var look_at_label = $LookAtLabel

@export var MOUSE_SENSITIVITY : float = 1
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var ANIMATIONPLAYER : AnimationPlayer
@export var CROUCH_SHAPECAST : ShapeCast3D
@export var PLAYERSTATEMACHINE : StateMachine
@export var WEAPON_CONTROLLER : WeaponController
@export var USERINTERFACE : Control
@export var WEAPONVIEWPORT : SubViewportContainer

var _is_authorized_user : bool = false

var _player_data : PlayerData

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
var look_at_label_anchor : Vector3
var look_at_collider
var _current_rotation : float

# interaction variables
var is_holding_interact = false
var interact_hold_time = 0.0
var increasing_interact_value = 0
var interact_time_threshold = 0.5

# Get the gravity from the project s ettings to be synced with RigidBody nodes.
var gravity = 9.8
var mass = 82

func _authorize_user():
	_is_authorized_user = true
	player_model= get_node("CollisionShape3D/player_model")
	legs_model = get_node("CollisionShape3D/legs_model")
	player_model.visible = false
	legs_model.visible = false

func _deauthorize_user():
	_is_authorized_user = false
	player_model= get_node("CollisionShape3D/player_model")
	legs_model = get_node("CollisionShape3D/legs_model")
	player_model.visible = true
	legs_model.visible = false

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
	
	if event.is_action_pressed("interact"):
		is_holding_interact = true
		interact_hold_time = 0  # Reset the timer
		increasing_interact_value = 0  # Reset the increasing value

	if event.is_action_released("interact"):
		if look_at_collider != null:
			if increasing_interact_value > 0 and increasing_interact_value < 100:
				# Reset values if released while value is above 0 but below 100
				is_holding_interact = false
				increasing_interact_value = 0
			elif increasing_interact_value == 0:
				interact_pick_up_to_inventory()
			is_holding_interact = false

func _unhandled_input(event: InputEvent) -> void:
	if _is_authorized_user == true:
		if event.is_action_pressed("mouse_click") && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE:
			capture_mouse()
		if event.is_action_pressed("exit"):
			if (inventory_menu.visible):
				if !Global.IS_IN_CONSOLE:
					inventory_menu.toggle_inventory()
			elif Global.IS_IN_CONSOLE:
				pass
			else:
				toggle_pause_menu()
		
		if event is InputEventMouseMotion && Global.MOUSE_CAPTURED == true:
			look_dir = event.relative * 0.001
			_rotate_camera()
			looking_process()

func toggle_pause_menu():
	pause_menu.visible = !pause_menu.visible
	
	if pause_menu.visible:
		uncapture_mouse()
		Global.IS_PAUSED = true
		pause_animator.play("start_pause")
	else:
		capture_mouse()
		Global.IS_PAUSED = false
		pause_animator.play("RESET")

func capture_mouse():
	Global.capture_mouse(true)

func uncapture_mouse():
	Global.capture_mouse(false)

func _rotate_camera(sens_mod: float = 1.0) -> void:
	if Global.IS_PAUSED || Global.IS_IN_CONSOLE:
		return
		
	self.rotation.y -= look_dir.x * MOUSE_SENSITIVITY
	CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x - look_dir.y * MOUSE_SENSITIVITY, -1.5, 1.5)
	
func _ready():
	if _is_authorized_user == true:
		capture_mouse()
		
		set_settings()
		
		_player_data = load("res://resources/default_player_data.tres")
		
		Global.player = self
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		POSTP_DITHER.visible = true
		POSTP_OUTLINE.visible = true
		
		_steam_ID = Steam.getSteamID()
		
		CROUCH_SHAPECAST.add_exception($".")
		
		if CAMERA_CONTROLLER != null:
			set_fov(Global.FIELD_OF_VIEW)
		enable_postp_dither(Global.POSTP_DITHER_ON)
		enable_postp_dither(Global.POSTP_OUTLINE_ON)
		
		set_sensitivity(Global.MOUSE_SENSITIVITY)
		
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
		Console.create_command("postp_set_color_depth", self.c_set_postp_color_depth, "Sets the color depth post process effect. 1 is minimum; 8 is maximum; 4 is default.")
		Console.create_command("postp_enable_outline", self.c_enable_postp_outline, "Toggles the outline post process effect. Takes a true or false.")
		Console.create_command("set_body_temperature", self.c_set_all_player_limb_temperature, "Sets the temperature of all body parts to the given value. 100.0 is default; 0.0 is min; 200.0 is max")
		Console.create_command("get_body_temperature", self.c_get_all_player_limb_temperature, "Displays the body temperature of each body part. 100.0 is default; 0.0 is min; 200.0 is max")
		Console.create_command("create_item", self.c_create_item_from_id, "Drops the number input of input item by ID in front of player.")

func set_settings():
	#CAMERA_CONTROLLER.far = Global.RENDER_DISTANCE*12 # opt - see if this would have even helped performance; can't use it with the skybox
	_resource_spawn_radius = (Global.RENDER_DISTANCE*24)+20

func _physics_process(delta):
	if _is_authorized_user:
		debug_process()
		
		interact_process(delta)
		
		_cached_position = global_position
		_cached_rotation = rotation
		
		if pause_menu.visible:
			Global.IS_PAUSED = true

func _process(delta):
	look_at_label.global_position = look_at_label_anchor

func update_gravity(delta) -> void:
	if (_player_data.no_clip):
		pass
	else:
		var gravitational_force = gravity * mass
		var acceleration = gravitational_force / mass  # Simplifies to gravity
		velocity.y -= acceleration * delta
	
func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	if _is_authorized_user == true:
		if _player_data.no_clip:
			if Input.is_action_pressed("sprint"):
				speed = speed * 6
			else:
				speed = speed * 3
			# Allow flying movement based on mouse direction
			var input_dir = Vector3.ZERO
			var camera_forward = Vector3.ZERO
			if (Global.MOUSE_CAPTURED == true && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE) || Global.IS_IN_INVENTORY:
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
			if (Global.MOUSE_CAPTURED == true && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE) || Global.IS_IN_INVENTORY:
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
			send_move_packet()

func send_move_packet():
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

func set_sensitivity(sensitivity : float) -> float:
	if sensitivity < Global.MIN_SENSITIVITY:
		sensitivity = Global.MIN_SENSITIVITY
	elif sensitivity > Global.MAX_SENSITIVITY:
		sensitivity = Global.MAX_SENSITIVITY
	
	Global.MOUSE_SENSITIVITY = sensitivity
	MOUSE_SENSITIVITY = sensitivity
	
	return sensitivity

func debug_process():
	Global.debug.add_property("Velocity","%.2f" % velocity.length(), 2)
	Global.debug.add_property("ShapeCast", CROUCH_SHAPECAST.is_colliding(), 2)
	Global.debug.add_property("Collision Pos", $CollisionShape3D.position , 2)
	Global.debug.add_property("Mouse Rotation", _rotation_input, 2)

func looking_process():
	if look_at_ray_cast.is_colliding():
		if look_at_collider != null:
			look_at_collider.toggle_highlight(false)
		look_at_collider = look_at_ray_cast.get_collider()
		if look_at_collider != null:
			look_at_collider.toggle_highlight(true)
			look_at_label_anchor = look_at_collider.global_position
			var _stack_amount = look_at_collider.stack_amount
			if _stack_amount > 1:
				look_at_label.text = str(look_at_collider.inv_item.item_name, " (", look_at_collider.stack_amount, ")")
			else:
				look_at_label.text = look_at_collider.inv_item.item_name
	else:
		if look_at_collider != null:
			look_at_collider.toggle_highlight(false)
			look_at_collider = null
		look_at_label.text = ""

func interact_process(delta):
	if is_holding_interact:
		interact_hold_time += delta
		if interact_hold_time >= interact_time_threshold:
			# Increase value only if hold time has surpassed the threshold
			if increasing_interact_value < 100:
				increasing_interact_value += 2  # Increase the value each frame
				if increasing_interact_value >= 100:
					interact_pick_up_to_hand()  # Call function2 when it reaches 100

func interact_pick_up_to_inventory():
	if inventory_manager.try_to_pick_up_item(look_at_collider.inv_item.item_id, look_at_collider.stack_amount) != false:
		look_at_collider.queue_free()
		look_at_label.text = ""
		look_at_collider = null

func interact_pick_up_to_hand():
	print_debug("item to hand")

func drop_ground_item(_item_id : String, _stack_amount : int):
	world.instance_ground_item(StaticData.create_item_from_id(_item_id), _stack_amount, drop_position.global_position)

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

func c_set_all_player_limb_temperature(temperature : float) -> void:
	var rounded_temperature : int = temperature
	_player_data.set_all_limb_temperature(rounded_temperature)
	
	Console.print_line("Set body temperature to " + str(rounded_temperature))

func c_get_all_player_limb_temperature() -> void:
	var body_temperatures: Dictionary = _player_data.get_all_limb_temperature()
	var average_temperature : int = _player_data.get_average_limb_temperature()
	
	for body_part in body_temperatures.keys():
		Console.print_line(body_part + " is at " + str(body_temperatures[body_part]))
	Console.print_line("\n[color=GOLD]" + "Average: " + str(average_temperature) + "[/color]")

func c_get_world_seed():
	Console.print_line(str(Global.WORLD_SEED))
	Console.print_line(Steam.getLobbyData(Global.LOBBY_ID, "world_seed"))

func c_set_no_clip() -> void:
	_player_data.no_clip = !_player_data.no_clip
	
	if (_player_data.no_clip == true):
		Console.print_line("no_clip was enabled.")
	else:
		Console.print_line("no_clip was disabled.")
	
	if get_collision_mask_value(1) == _player_data.no_clip:
		set_collision_mask_value(1, !_player_data.no_clip)

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

func c_create_item_from_id(item_to_create_id : String, number_of_item : int):
	var process_step = 0
	for i in range(number_of_item):
		process_step += 1
		if process_step % 10 == 0:
			await get_tree().process_frame
		world.instance_ground_item(StaticData.create_item_from_id(item_to_create_id), 1, drop_position.global_position)

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
