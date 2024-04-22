extends Control

@onready var stack_label = $StackLabel
@onready var display = $Display

var is_rotated : bool = false:
	set(new_value):
		is_rotated = new_value
		rotate_preview()

func _ready():
	set_preview_size(Vector2.ONE)

func rotate_preview():
	if is_rotated:
		display.rotation_degrees = -90
		display.modulate = Color.GOLD
	else:
		display.rotation_degrees = 0
		display.modulate = Color.WHITE

func set_preview_size(_size : Vector2):
	size = _size * Global.INV_CELL_SIZE
	
	if display == null:
		display = get_node("Display")
	
	display.pivot_offset = Global.INV_CELL_SIZE * 0.5

func set_preview_stack_label(_stack_size : int):
	if _stack_size > 1:
		stack_label.text = str(_stack_size)
	else:
		stack_label.text = ""

func _process(delta):
	pass
