extends Control

const info_offset: Vector2 = Vector2(20, 0)

@onready var fps_controller = $"../.."
@onready var inventory = $inventory

func _ready() -> void:
	await fps_controller.ready
	
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
		return
	else:
		visible = !visible
		Global.IS_IN_INVENTORY = visible
		Global.capture_mouse(!visible)
