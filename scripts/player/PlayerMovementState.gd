class_name PlayerMovementState

extends State

var PLAYER: Player
var ANIMATION: AnimationPlayer
var WEAPON: WeaponController

func _ready() -> void:
	await owner.ready
	PLAYER = owner as Player
	ANIMATION = PLAYER.ANIMATIONPLAYER
	WEAPON = PLAYER.WEAPON_CONTROLLER
