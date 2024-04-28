extends Control
class_name InvItemRect

@onready var label = $Label

var item_id : String = ""
var item_stack : int = 0

func _ready():
	set_inv_item_rect_label()

func set_inv_item_rect_variables(_item_id : String, _item_stack : int):
	item_id = _item_id
	item_stack = _item_stack
	set_inv_item_rect_label()

func set_inv_item_rect_label():
	if item_id != "" && item_stack != 0:
		printerr(item_stack)
		label.text = "%s (%d)" %[StaticData.item_data[item_id]["item_name"], item_stack]
