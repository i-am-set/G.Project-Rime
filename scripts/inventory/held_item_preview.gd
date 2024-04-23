extends Control

@onready var stack_label = $StackLabel
@onready var display = $Display

var inv_item_size : Vector2
var is_rotated : bool = false:
	set(new_value):
		is_rotated = new_value
		rotate_preview()

func _ready():
	set_preview_size(Vector2.ONE)

func rotate_preview():
	if is_rotated && inv_item_size.x != inv_item_size.y:
		display.pivot_offset = get_correct_pivot(inv_item_size)
		display.rotation_degrees = -90
		#display.modulate = Color.GOLD
	else:
		display.rotation_degrees = 0
		#display.modulate = Color.WHITE
		display.pivot_offset = Global.INV_CELL_SIZE * 0.5

func set_preview_size(_size : Vector2):
	inv_item_size = _size
	size = _size * Global.INV_CELL_SIZE
	
	if display == null:
		display = get_node("Display")
	
	display.size = _size * Global.INV_CELL_SIZE
	display.pivot_offset = Global.INV_CELL_SIZE * 0.5

func set_preview_stack_label(_stack_size : int):
	if _stack_size > 1:
		stack_label.text = str(_stack_size)
	else:
		stack_label.text = ""

func get_correct_pivot(_size : Vector2) -> Vector2:
	var _pivot_offset
	if _size.x > 1:
		_pivot_offset = Global.INV_CELL_SIZE * 0.5 * Vector2(_size.x, _size.x)
	else:
		_pivot_offset = Global.INV_CELL_SIZE * 0.5
	
	return _pivot_offset

func _process(delta):
	pass
