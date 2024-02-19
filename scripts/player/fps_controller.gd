class_name Player

extends CharacterBody3D

@export var VISOR : MeshInstance3D

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

var _mouse_input : bool = false
var look_dir: Vector2 # Input direction for look/aim
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _camera_rotation : Vector3
var _cached_position : Vector3
var _cached_rotation : Vector3
var _steam_ID : int

var _current_rotation : float

# Get the gravity from the project s ettings to be synced with RigidBody nodes.
var gravity = 9.8

func _authorize_user():
	_is_authorized_user = true

func _deauthorize_user():
	_is_authorized_user = false

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_click"):
		capture_mouse()
	elif event.is_action_pressed("exit"):
		uncapture_mouse()
	
	if event is InputEventMouseMotion && Global.MOUSE_CAPTURED == true && _is_authorized_user == true:
		look_dir = event.relative * 0.001
		_rotate_camera()

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.MOUSE_CAPTURED = true

func uncapture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.MOUSE_CAPTURED = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	self.rotation.y -= look_dir.x * MOUSE_SENSITIVITY
	CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x - look_dir.y * MOUSE_SENSITIVITY, -1.5, 1.5)
	
func _ready():
	capture_mouse()
	
	Global.player = self
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_steam_ID = Steam.getSteamID()
	
	CROUCH_SHAPECAST.add_exception($".")
	
	if CAMERA_CONTROLLER != null:
		CAMERA_CONTROLLER.fov = 75.0

func _physics_process(delta):
	if _is_authorized_user:
		Global.debug.add_property("Velocity","%.2f" % velocity.length(), 2)
		Global.debug.add_property("ShapeCast", CROUCH_SHAPECAST.is_colliding(), 2)
		Global.debug.add_property("Collision Pos", $CollisionShape3D.position , 2)
		Global.debug.add_property("Mouse Rotation", _rotation_input, 2)
		
		_cached_position = global_position
		_cached_rotation = rotation
	
func update_gravity(delta) -> void:
	velocity.y -= gravity * delta
	
func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	if _is_authorized_user == true:
		var input_dir = Vector3.ZERO
		if (Global.MOUSE_CAPTURED == true):
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
			send_p2p_packet(0, {"message" : "move", "steam_id" : _steam_ID, "player_position" : global_position, "player_rotation" : rotation})
	
func update_velocity() -> void:
	pass

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
