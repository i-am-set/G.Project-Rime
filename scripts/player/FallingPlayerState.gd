class_name FallingPlayerState extends PlayerMovementState

@export var SPEED: float = 5.0
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25
@export var DOUBLE_JUMP_VELOCITY : float = 4.5
@onready var arms_animation_player = $"../../CameraController/Camera3D/ArmsModel/male_arm_model/AnimationPlayer"

func enter(previous_state) -> void:
	ANIMATION.pause()
	pass
	
func exit() -> void:
	pass
	
func update(delta: float) -> void:
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED,ACCELERATION,DECELERATION)
	PLAYER.update_velocity()
	
	if PLAYER.is_on_floor():
		ANIMATION.play("JumpEnd")
		transition.emit("IdlePlayerState")
