extends Control

@onready var stack_label = $StackLabel
@onready var display = $Display

func _ready():
	set_preview_size(Vector2.ONE)

func set_preview_size(_size : Vector2):
	size = _size * Global.INV_CELL_SIZE

func set_preview_stack_label(_stack_size : int):
	if _stack_size > 1:
		stack_label.text = str(_stack_size)
	else:
		stack_label.text = ""

func _process(delta):
	pass
