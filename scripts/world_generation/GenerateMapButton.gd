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

var tick : int = 0

func _physics_process(delta):
	tick += 1
	if tick >= 5:
		tick = 0
		if MapGenerator.autoUpdate == true:
			MapGenerator.GenerateMap()

func _ready():
	MapGenerator.GenerateMap()
