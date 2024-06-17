extends CanvasLayer

@onready var fps_label = $FPS_Label
@onready var game_chat_controller = $GameChatController
@onready var game_player_list_controller = $GamePlayerListController

var is_high_contrast : bool = false

func _ready():
	fps_label.visible = false
	is_high_contrast = false
	fps_label.set("theme_override_colors/font_color", Color.DARK_GRAY)
	
	# Set console commands
	#Console.create_command("fps_display", self.c_fps_display, "Toggles fps display.")
	Console.create_command("fps_high_contrast", self.c_fps_high_contrast, "Toggles fps high contrast.")

func toggle_display_fps(toggle : bool):
	await get_tree().create_timer(0.1).timeout
	if fps_label == null:
		fps_label = get_node("FPS_Label")
		await get_tree().create_timer(1).timeout
	fps_label.visible = toggle

#func c_fps_display():
	#fps_label.visible = !fps_label.visible

func c_fps_high_contrast():
	is_high_contrast = !is_high_contrast
	if is_high_contrast:
		fps_label.set("theme_override_colors/font_color", Color.LAWN_GREEN)
	else:
		fps_label.set("theme_override_colors/font_color", Color.DARK_GRAY)
