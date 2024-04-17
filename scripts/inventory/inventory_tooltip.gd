extends Control

@onready var tooltip_label : Label = $TooltipLabel

var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_tooltip()

func _ready():
	hide()

func _process(delta):
	pass

func update_tooltip():
	tooltip_label.text = inv_item.item_name
