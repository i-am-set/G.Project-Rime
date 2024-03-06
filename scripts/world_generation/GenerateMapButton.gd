@tool
extends Node

@export var MapGenerator : Node3D
@export var mybutton: bool:
	set(value):
		mybutton = false
		MapGenerator.GenerateMap()

func _ready():
	MapGenerator.GenerateMap()
