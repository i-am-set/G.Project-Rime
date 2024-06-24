class_name SprintingPlayerState extends PlayerMovementState

@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.6
@export var TOP_ANIM_SPEED : float = 1.6
@export var WEAPON_BOB_SPD : float = 8.0
@export var WEAPON_BOB_H : float = 2.5
@export var WEAPON_BOB_V : float = 1.5
@export var WEAPON_PULL_DOWN_DISTANCE : float = 0.075
@export var WEAPON_PULL_DOWN_SPEED : float = 10

var DEFAULT_SPEED: float = 8.0
var SPEED: float = DEFAULT_SPEED

func enter(previous_state) -> void:
	PLAYER.is_sprinting = true
	
	if ANIMATION.is_playing() and ANIMATION.current_animation == "JumpEnd":
		await ANIMATION.animation_finished
		ANIMATION.play("Sprinting")
	else:
		ANIMATION.play("Sprinting")
	
func exit() -> void:
	PLAYER.is_sprinting = false
	ANIMATION.speed_scale = 1.0
	PLAYER.player_data.set_stamina_regen_cooldown_timer()
	
	WEAPON.weapon_bob_amount = Vector2(0,0)
	WEAPON.stop_run()

func update(delta):
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED,ACCELERATION,DECELERATION)
	PLAYER.update_velocity()
	
	WEAPON.sway_weapon(delta, false)
	WEAPON._weapon_bob(delta, WEAPON_BOB_SPD, WEAPON_BOB_H, WEAPON_BOB_V)
	WEAPON.start_run(delta, WEAPON_PULL_DOWN_DISTANCE, WEAPON_PULL_DOWN_SPEED)
	
	#set_animation_speed(PLAYER.velocity.length())
	
	
	if Input.is_action_just_released("sprint") or PLAYER.velocity.length() == 0 or PLAYER.player_data.stamina <= 0 or PLAYER.player_data.is_exhausted:
		transition.emit("IdlePlayerState")
		
	if Input.is_action_just_pressed("jump") and PLAYER.is_on_floor():
		if PLAYER.player_data.try_exert_stamina(PLAYER.player_data.jump_stamina_requirement):
			transition.emit("JumpingPlayerState")
		
	if PLAYER.velocity.y < -3.0 and !PLAYER.is_on_floor():
		transition.emit("FallingPlayerState")

#func set_animation_speed(spd) -> void:
	#var alpha = remap(spd, 0.0, SPEED, 0.0, 1.0)
	#ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)
