extends Control


func _ready():
	pass

func _process(delta):
	pass

func initialize_game(seed):
	# Cement changes
	Global.WORLD_SEED = seed
	# Await processing
	await get_tree().process_frame

func _on_singleplayer_debug_button_pressed() -> void:
	var seed = randi_range(1, 999999999999)
	Global.LOBBY_ID = -1
	Global.WORLD_SEED = seed
	await get_tree().process_frame
	await initialize_game(seed)
	await get_tree().change_scene_to_file(Global.WORLD_PATH)

