class_name CrouchingPlayerState extends PlayerMovementState

@export var SPEED: float = 2.0
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25
@export var TOGGLE_CROUCH : bool = false
@export_range(1, 6, 0.1) var CROUCH_SPEED : float = 4.0
@export var WEAPON_BOB_SPD : float = 2.0
@export var WEAPON_BOB_H : float = 1.5
@export var WEAPON_BOB_V : float = 0.7

@onready var CROUCH_SHAPECAST : ShapeCast3D = %OverheadShapeCast

var RELEASED : bool = false

func enter(previous_state) -> void:
	if ANIMATION.is_playing() and ANIMATION.current_animation == "JumpEnd":
		await ANIMATION.animation_finished
	
	ANIMATION.speed_scale = 1.0
	if previous_state.name != "SlidingPlayerState":
		ANIMATION.play("Crouching", -1.0, CROUCH_SPEED)
	elif previous_state.name == "SlidingPlayerState":
		ANIMATION.current_animation = "Crouching"
		ANIMATION.seek(1.0, true)
	
	PLAYER.crouch_toggle(true)
	
func exit() -> void:
	PLAYER.crouch_toggle(false)
	RELEASED = false
	
	WEAPON.weapon_bob_amount = Vector2(0,0)

func update(delta):
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED,ACCELERATION,DECELERATION)
	PLAYER.update_velocity()
	
	WEAPON.sway_weapon(delta, false)
	WEAPON._weapon_bob(delta, WEAPON_BOB_SPD, WEAPON_BOB_H, WEAPON_BOB_V)
	
	if TOGGLE_CROUCH == false:
		if Input.is_action_just_released("crouch"):
			uncrouch()
		elif Input.is_action_pressed("crouch") == false and RELEASED == false:
			RELEASED = true
			uncrouch()
	else:
		if CROUCH_SHAPECAST.is_colliding() == false:
			if Input.is_action_just_pressed("crouch"):
				uncrouch()
			if Input.is_action_pressed("sprint") and PLAYER.is_on_floor() and PLAYER.player_data.stamina > 0 and not PLAYER.player_data.is_exhausted:
				uncrouch()
			elif Input.is_action_just_pressed("jump") and PLAYER.is_on_floor():
				uncrouch()
				if ANIMATION.is_playing() and ANIMATION.current_animation == "Crouching":
					await ANIMATION.animation_finished
				transition.emit("JumpingPlayerState")
	
	if Input.is_action_just_pressed("attack"):
		WEAPON._attack()

func uncrouch():
	if CROUCH_SHAPECAST.is_colliding() == false:
		ANIMATION.play("Crouching", -1.0 ,-CROUCH_SPEED, true)
		await ANIMATION.animation_finished
		if PLAYER.velocity.length() == 0:
			transition.emit("IdlePlayerState")
		else:
			transition.emit("WalkingPlayerState")
	elif CROUCH_SHAPECAST.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch()
