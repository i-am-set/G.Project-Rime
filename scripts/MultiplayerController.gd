extends Control

@export var Address = "127.0.0.1"

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func peer_connected(id):
	print("Player Connected" + id)

func peer_disconnected(id):
	print("Player Disconnected" + id)

func connected_to_server():
	print("Connected to server")

func connection_failed():
	print("Could not connect")
