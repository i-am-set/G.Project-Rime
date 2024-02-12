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

var _current_rotation : float

# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = 9.8

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_mouse_captured = true
	elif event.is_action_pressed("exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_mouse_captured = false
	
	if event is InputEventMouseMotion && _mouse_captured == true:
		look_dir = event.relative * 0.001
		_rotate_camera()

#func _input(event):
	#if event.is_action_pressed("exit"):
		#get_tree().quit()
		
func _rotate_camera(sens_mod: float = 1.0) -> void:
	self.rotation.y -= look_dir.x * MOUSE_SENSITIVITY
	CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x - look_dir.y * MOUSE_SENSITIVITY, -1.5, 1.5)
	
#func update_camera(delta) -> void:
	#_current_rotation = _rotation_input
	#_mouse_rotation.x += _tilt_input * delta
	#_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	#_mouse_rotation.y += _rotation_input * delta
	#
	#_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	#_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
#
	#CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	#global_transform.basis = Basis.from_euler(_player_rotation)
	#
	#CAMERA_CONTROLLER.rotation.z = 0.0
#
	#_rotation_input = 0.0
	#_tilt_input = 0.0
	
func _ready():
	
	Global.player = self
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = lerp(velocity.x,direction.x * speed, acceleration)
		velocity.z = lerp(velocity.z,direction.z * speed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration)
		velocity.z = move_toward(velocity.z, 0, deceleration)
	
func update_velocity() -> void:
	move_and_slide()
