extends Control

@onready var display = $Display
@onready var highlight_mask = $Display/HighlightMask
@onready var stack_label : Label = $StackLabel

var subinventory : Control
var held_item_preview : Control
var mouse_is_over = false
var max_scale : float = 1.25
var tooltip_timer: Timer

var current_stack : int : set = set_current_stack
func set_current_stack(value):
	current_stack = value
	update_current_stack()

var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_item_size()

func _ready():
	define_tooltip_timer()
	Global.inv_cell_size_updated.connect(update_item_size)

func _process(delta):
	subinventory = get_parent()
	held_item_preview = subinventory.held_item_preview

func _physics_process(delta):
	hover_item()

func update_item_size():
	size = Vector2(inv_item.item_width, inv_item.item_height) * Global.INV_CELL_SIZE

func update_current_stack():
	if stack_label == null:
		stack_label = $StackLabel
	if current_stack > 1:
		stack_label.text = str(current_stack)
	else:
		stack_label.text = ""

func hover_item():
	if mouse_is_over:
		if display.texture != null:
			display.scale = Vector2(max_scale, max_scale)
	else:
		if display.texture != null:
			display.scale = Vector2(1, 1)

func highlight_item_display(toggle : bool):
	highlight_mask.visible = toggle

func define_tooltip_timer():
	tooltip_timer = Timer.new()
	add_child(tooltip_timer)
	tooltip_timer.wait_time = 0.2
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(ShowTooltip)

func ShowTooltip():
	subinventory.inventory.ShowTooltip(inv_item)

func _on_mouse_entered():
	subinventory = get_parent()
	subinventory.inventory.HideTooltip()
	tooltip_timer.start()
	mouse_is_over = true

func _on_mouse_exited():
	tooltip_timer.stop()
	subinventory.inventory.HideTooltip()
	mouse_is_over = false
