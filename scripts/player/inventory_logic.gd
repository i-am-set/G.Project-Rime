extends Control

const info_offset: Vector2 = Vector2(20, 0)

@onready var fps_controller = $"../.."
@onready var temperature_map = $silhouette_panel/temperature_map
@onready var temperature_map_material = temperature_map.material
@onready var animation_player = $AnimationPlayer
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
		animation_player.play("RESET")
		return
	else:
		visible = !visible
		Global.IS_IN_INVENTORY = visible
		Global.capture_mouse(!visible)
		if visible == true:
			animation_player.play("blur_start")
			update_temperature_map_colors()
		else:
			animation_player.play("RESET")

func update_temperature_map_colors():
	temperature_map_material.set_shader_parameter("head_color", player_data.get_temperature_color(player_data.head_temperature))
	temperature_map_material.set_shader_parameter("torso_color", player_data.get_temperature_color(player_data.torso_temperature))
	temperature_map_material.set_shader_parameter("left_arm_color", player_data.get_temperature_color(player_data.left_arm_temperature))
	temperature_map_material.set_shader_parameter("right_arm_color", player_data.get_temperature_color(player_data.right_arm_temperature))
	temperature_map_material.set_shader_parameter("left_leg_color", player_data.get_temperature_color(player_data.left_leg_temperature))
	temperature_map_material.set_shader_parameter("right_leg_color", player_data.get_temperature_color(player_data.right_leg_temperature))
