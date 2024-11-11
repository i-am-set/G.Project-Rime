extends Control

@onready var reticle: CenterContainer = $"../../Reticle"
@onready var radial_menu: Control = $RadialMenu

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
	# Pass the center position to open_menu as a Vector2!
	radial_menu.open_menu(reticle.position)
	## Make sure we don't handle the click again anywhere else...
	#get_viewport().set_input_as_handled()

func close_radial_menu() -> void:
	radial_menu.close_menu()

func _on_radial_menu_menu_closed(menu: Variant) -> void:
	Global.capture_mouse(true)
