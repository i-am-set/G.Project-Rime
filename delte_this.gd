extends Node

var _player_node = preload("res://scenes/fps_controller.tscn")

func _ready():
	if Global.LOBBY_MEMBERS.size() > 1:
		for this_member in Global.LOBBY_MEMBERS:
			if this_member['steam_id'] != Global.STEAM_ID:
				print("creating player %s" %this_member['steam_id'])
				var player_instance = _player_node.instantiate()
				player_instance._steam_ID = this_member['steam_id']
				player_instance._authorized_user = false
				player_instance.delete_camera()
				add_child(player_instance)
				player_instance.global_transform.origin = Vector3(-5, 10, 0)
			else:
				print("creating self")
				var player_instance = _player_node.instantiate()
				player_instance._steam_ID = this_member['steam_id']
				player_instance._authorized_user = true
				add_child(player_instance)
				player_instance.global_transform.origin = Vector3(5, 10, 0)
	else:
		print("creating self")
		var player_instance = _player_node.instantiate()
		player_instance._steam_ID = Global.STEAM_ID
		player_instance._authorized_user = true
		add_child(player_instance)
		player_instance.global_transform.origin = Vector3(5, 10, 0)
		print("self created")
