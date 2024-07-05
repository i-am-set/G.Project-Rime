extends Resource
class_name InventoryItem

# Item properties
@export var item_id: String
@export var item_weight: float
@export var item_durability: int

# Optional: Provide a function to display basic info
func _to_string() -> String:
	return "InvItem: %s (ID: %d)" % [get_item_name(), item_id]

func get_item_name() -> String:
	return StaticData.item_data[item_id]["item_name"]

func get_item_description() -> String:
	return StaticData.item_data[item_id]["item_description"]

func get_item_type() -> int:
	return StaticData.item_data[item_id]["item_type"]

func get_item_weight() -> float:
	return item_weight

func get_item_durability() -> int:
	return item_durability

func get_item_tinder_value() -> int:
	return StaticData.item_data[item_id]["item_tinder_value"]

func get_item_kindling_value() -> int:
	return StaticData.item_data[item_id]["item_kindling_value"]

func get_item_fuel_value() -> int:
	return StaticData.item_data[item_id]["item_fuel_value"]

func get_item_hammer_value() -> int:
	return StaticData.item_data[item_id]["item_hammer_value"]

func get_item_blade_value() -> int:
	return StaticData.item_data[item_id]["item_blade_value"]

func get_item_parameter_1() -> int:
	return StaticData.item_data[item_id]["item_parameter_1"]

func get_item_parameter_2() -> int:
	return StaticData.item_data[item_id]["item_parameter_2"]

func get_item_parameter_3() -> int:
	return StaticData.item_data[item_id]["item_parameter_3"]

func get_item_misc(_item_parameter : String):
	return StaticData.item_data[item_id][_item_parameter]
