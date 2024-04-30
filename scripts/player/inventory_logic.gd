extends Control

const info_offset: Vector2 = Vector2(20, 0)

@onready var fps_controller = $"../.."
@onready var animation_player = $AnimationPlayer
@onready var inventory = $inventory
var player_data

func _ready() -> void:
	await fps_controller.ready
	player_data = fps_controller._player_data
	
	self.visible = false
	Global.IS_IN_INVENTORY = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE && !DebugAutoloadCanvas.game_chat_controller.visible:
		toggle_inventory()

func toggle_inventory():
	if Global.IS_PAUSED || Global.IS_IN_CONSOLE:
		self.visible == false
		Global.IS_IN_INVENTORY == false
		inventory.HideHeldItemPreview()
		animation_player.play("RESET")
		return
	else:
		visible = !visible
		Global.IS_IN_INVENTORY = visible
		Global.capture_mouse(!visible)
		if visible == true:
			animation_player.play("blur_start")
		else:
			#inventory.HideHeldItemPreview()
			animation_player.play("RESET")
