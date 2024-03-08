@tool
extends Node

@export var MapGenerator : Node3D
@export var generateMap: bool:
	set(value):
		generateMap = false
		MapGenerator.GenerateMap()
@export var randomizeSeed: bool:
	set(value):
		randomizeSeed = false
		MapGenerator.RandomizeSeed()

func _physics_process(delta):
	if MapGenerator.needsUpdating == true:
		MapGenerator.needsUpdating = false
		if MapGenerator.autoUpdate == true:
			MapGenerator.GenerateMap()

func _ready():
	MapGenerator.GenerateMap()
