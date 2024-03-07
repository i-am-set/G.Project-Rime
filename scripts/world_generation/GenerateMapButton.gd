@tool
extends Node

@export var MapGenerator : Node3D
@export var mybutton: bool:
	set(value):
		mybutton = false
		MapGenerator.GenerateMap()

var tick : int = 0

func _physics_process(delta):
	tick += 1
	if tick >= 40:
		tick = 0
		if MapGenerator.autoUpdate == true:
			MapGenerator.GenerateMap()

func _ready():
	MapGenerator.GenerateMap()
