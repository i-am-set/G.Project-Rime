class_name Player

extends CharacterBody3D

@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var ANIMATIONPLAYER : AnimationPlayer
@export var CROUCH_SHAPECAST : ShapeCast3D

var _mouse_input : bool = false
var _mouse_captured : bool = false
var look_dir: Vector2 # Input direction for look/aim
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _cached_position : Vector3 = position
var _steam_ID : int

var _current_rotation : float

# Get the gravity from the project s ettings to be synced with RigidBody nodes.

var gravity = 9.8

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		capture_mouse()
	elif event.is_action_pressed("exit"):
		uncapture_mouse()
	
	if event is InputEventMouseMotion && _mouse_captured == true:
		look_dir = event.relative * 0.001
		_rotate_camera()

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_mouse_captured = true

func uncapture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_mouse_captured = false

#func _input(event):
	#if event.is_action_pressed("exit"):
		#get_tree().quit()
		
func _rotate_camera(sens_mod: float = 1.0) -> void:
	self.rotation.y -= look_dir.x * MOUSE_SENSITIVITY
	CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x - look_dir.y * MOUSE_SENSITIVITY, -1.5, 1.5)
	
func _ready():
	capture_mouse()
	
	Global.player = self
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_steam_ID = Steam.getSteamID()
	
	CROUCH_SHAPECAST.add_exception($".")
	
	CAMERA_CONTROLLER.fov = 75.0

func _physics_process(delta):
	Global.debug.add_property("Velocity","%.2f" % velocity.length(), 2)
	Global.debug.add_property("ShapeCast", CROUCH_SHAPECAST.is_colliding(), 2)
	Global.debug.add_property("Collision Pos", $CollisionShape3D.position , 2)
	Global.debug.add_property("Mouse Rotation", _rotation_input, 2)
	
	#update_camera(delta)
	
func update_gravity(delta) -> void:
	velocity.y -= gravity * delta
	
func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	_cached_position = global_position
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = lerp(velocity.x,direction.x * speed, acceleration)
		velocity.z = lerp(velocity.z,direction.z * speed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration)
		velocity.z = move_toward(velocity.z, 0, deceleration)
	
func update_velocity() -> void:
	move_and_slide()
	if global_position != _cached_position:
		send_p2p_packet(0, {"steam_id" : _steam_ID, "player_position" : global_position})

func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0 # unreliable
	
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
		if readable_data.has("location"):
			print(readable_data["location"])
