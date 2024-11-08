extends Control

@onready var reticle: CenterContainer = $"../../Reticle"


func _ready() -> void:
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("inventory"):
		open_radial_menu()

func open_radial_menu() -> void:
	Global.capture_mouse(false)
	# Pass the center position to open_menu as a Vector2!
	$RadialMenu.open_menu(reticle.position)
	## Make sure we don't handle the click again anywhere else...
	#get_viewport().set_input_as_handled()

func _on_radial_menu_menu_closed(menu: Variant) -> void:
	Global.capture_mouse(true)
