extends Node

var _player_node = preload("res://scenes/fps_controller.tscn")

func _ready():
	for this_member in Global.LOBBY_MEMBERS:
		if this_member['steam_id'] != Global.STEAM_ID:
			print("success")
			var player_instance = _player_node.instantiate()
			player_instance._steam_ID = this_member['steam_id']
			get_tree().get_root().add_child(player_instance)
			player_instance.global_transform.origin = Vector3(1, 0, 0)
