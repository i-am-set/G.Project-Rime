extends Control
class_name InventoryManager

@onready var junk_grid_container: GridContainer = $ScrollContainer/VBoxContainer/JunkGridContainer
@onready var resource_grid_container: GridContainer = $ScrollContainer/VBoxContainer/ResourceGridContainer
@onready var weapon_grid_container: GridContainer = $ScrollContainer/VBoxContainer/WeaponGridContainer
@onready var garment_grid_container: GridContainer = $ScrollContainer/VBoxContainer/GarmentGridContainer
@onready var food_grid_container: GridContainer = $ScrollContainer/VBoxContainer/FoodGridContainer
@onready var medical_grid_container: GridContainer = $ScrollContainer/VBoxContainer/MedicalGridContainer

@onready var fps_controller = $"../../../../.."
@onready var rmb_menu: Control = $"../../../../RmbMenu"
@onready var scroll_container = $ScrollContainer
@onready var subinventory_container = $ScrollContainer/SubinventoryContainer
@onready var weight_label : Label = $"../Weight"

var mouse_pos : Vector2

#var garment_head_id : String = ""
#var garment_face_id : String = ""
#var garment_shirt_id : String = ""
#var garment_subshirt_id : String = ""
#var garment_jacket_id : String = ""
#var garment_pant_id : String = ""
#var garment_subpant_id : String = ""
#var garment_sock_id : String = ""
#var garment_subsock_id : String = ""
#var garment_shoe_id : String = ""
#var garment_back_id : String = ""

@export var weight_capacity : float = 100
var weight_current : float

func _ready():
	update_weight(0)

func _process(delta):
	mouse_pos = get_global_mouse_position()

func item_type_to_grid_container(item_type : int) -> GridContainer:
	if item_type == 0:
		return junk_grid_container
	elif item_type == 1:
		return resource_grid_container
	elif item_type == 2:
		return weapon_grid_container
	elif item_type == 3:
		return garment_grid_container
	elif item_type == 4:
		return food_grid_container
	elif item_type == 5:
		return medical_grid_container
	else:
		return junk_grid_container

func pick_up_item(_picked_up_item : InventoryItem):
	item_type_to_grid_container(_picked_up_item.get_item_type()).add_item(_picked_up_item)

func ShowRmbMenu(_item_slot : int):
	rmb_menu.position = mouse_pos
	rmb_menu.right_clicked_item_slot = _item_slot
	rmb_menu.inv_item = subinventory_container.subinventory_contents[_item_slot]
	rmb_menu.show()

func HideRmbMenu():
	rmb_menu.hide()

func update_weight(_new_weight : int):
	weight_current = _new_weight
	weight_label.text = "%.2f/%.2f" %[weight_current,weight_capacity]
