extends Control
class_name InvItemRect

@onready var icon_label: Label = $IconLabel
@onready var name_label: Label = $NameLabel
@onready var weight_label: Label = $WeightLabel
@onready var weightlb_label: Label = $WeightLabel/WeightlbLabel

var item_id : String = ""
var item_stack : int = 0

var ItemIcon : Array = ["", "", "", "", "", "", ""]

var ItemType : Array = ["Misc", "Resource", "Resource", "Resource", "Resource", "Resource", "Resource"]

func _ready():
	set_inv_item_rect_label()

func set_inv_item_rect_variables(_item_id : String, _item_stack : int):
	item_id = _item_id
	item_stack = _item_stack
	set_inv_item_rect_label()

func set_inv_item_rect_label():
	if item_id != "" && item_stack != 0:
		var _item_data = StaticData.item_data[item_id]
		var _item_data_item_type = _item_data["item_type"]
		var _item_icon : String
		var _item_type : String
		var _item_weight : float
		
		if ItemIcon.has(_item_data_item_type):
			_item_icon = ItemIcon[0]
		else:
			_item_icon = ItemIcon[_item_data_item_type]
		
		if ItemType.has(_item_data_item_type):
			_item_type = ItemType[0]
		else:
			_item_type = ItemType[_item_data_item_type]
		
		_item_weight = _item_data["item_weight"]
		var _stack_weight : float = float(_item_weight) * item_stack
		
		icon_label.text = _item_icon
		name_label.text = "%s (%d)" %[_item_data["item_name"], item_stack]
		weight_label.text = "%.2f" % _stack_weight
