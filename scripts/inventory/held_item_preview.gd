extends Control

@onready var DISPLAY = $display

func _ready():
	set_preview_size(Vector2.ONE)

func set_preview_size(_size : Vector2):
	size = _size * Global.INV_CELL_SIZE

func _process(delta):
	pass
