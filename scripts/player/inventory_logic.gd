extends Control

const info_offset: Vector2 = Vector2(20, 0)

@onready var fps_controller = $"../.."
@onready var inventory = $inventory
@onready var sound_manager: Node = $"../../SoundManager"

#func _ready() -> void:
	#await fps_controller.ready
	#
	#self.visible = false


#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("inventory") && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE && !DebugAutoloadCanvas.game_chat_controller.visible:
		#toggle_inventory()

func toggle_inventory():
	if Global.IS_PAUSED || Global.IS_IN_CONSOLE:
		self.visible == false
		sound_manager.play_inventory(false)
		inventory.HideHeldItemPreview()
		return
	else:
		visible = !visible
		sound_manager.play_inventory(visible)
		Global.capture_mouse(!visible)

func pick_up_item(_picked_up_item : InventoryItem):
	print_debug(_picked_up_item.get_item_name())
