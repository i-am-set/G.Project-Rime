extends Control

@onready var fps_controller: Player = $"../../.."

@onready var reticle: CenterContainer = $"../../Reticle"
@onready var radial_menu: Control = $RadialMenu

@onready var radial_interacted_object_title: Label = $RadialMenu/RadialInteractedObjectTitle
@onready var radial_selection_title: Label = $RadialMenu/RadialSelectionTitle
@onready var radial_subtext: Label = $RadialMenu/RadialSubtext


var mouse_limit_radius = 50.0

func _ready() -> void:
	pass # Replace with function body.

func toggle_radial_menu():
	if !radial_menu.visible:
		open_radial_menu()
	else:
		close_radial_menu()

func _process(delta: float) -> void:
	if !Input.is_action_pressed("interact") and radial_menu.visible:
		radial_menu.close_menu()
	
	if radial_menu.visible:
		var center = Vector2(get_viewport().size / 2)
		var mouse_pos = get_global_mouse_position()
		var distance = center.distance_to(mouse_pos)
		
		if distance > mouse_limit_radius:
			var direction = (mouse_pos - center).normalized()
			var limited_pos = center + direction * mouse_limit_radius
			Input.warp_mouse(limited_pos)

func open_radial_menu() -> void:
	Global.capture_mouse(false)
	radial_selection_title.text = ""
	radial_subtext.text = ""
	radial_menu.open_menu(reticle.position)

func close_radial_menu() -> void:
	radial_menu.close_menu()

func update_main_title(_interacted_object_id) -> void:
	if _interacted_object_id != null:
		if _interacted_object_id.length() > 0:
			if _interacted_object_id[0] == "a":
				radial_interacted_object_title.text = StaticData.item_data[_interacted_object_id]["item_name"]
			elif _interacted_object_id[0] == "c":
				radial_interacted_object_title.text = StaticData.structure_data[_interacted_object_id]["structure_name"]

func _on_radial_menu_menu_closed(menu: Variant) -> void:
	Global.capture_mouse(true)

func _on_radial_menu_item_selected(id: Variant, position: Variant) -> void:
	fps_controller.run_interact_method_by_id(id)

func _on_radial_menu_item_hovered(_selection_dictionary: Variant) -> void:
	radial_selection_title.text = _selection_dictionary["title"]
	radial_subtext.text = ""
	if _selection_dictionary["id"] == "interact_description":
		var _interacted_object_id = fps_controller.get_collider_id(fps_controller.look_at_collider)
		if _interacted_object_id != null:
			if _interacted_object_id.length() > 0:
				if _interacted_object_id[0] == "a":
					radial_subtext.text = StaticData.item_data[_interacted_object_id]["item_description"]
				elif _interacted_object_id[0] == "c":
					radial_subtext.text = StaticData.structure_data[_interacted_object_id]["structure_description"]
				else:
					radial_subtext.text = ""

