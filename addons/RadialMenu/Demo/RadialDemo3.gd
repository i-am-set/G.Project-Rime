extends PanelContainer

"""
(c) 2021-2024 Pascal Schuppli

Demonstrates the use of the RadialMenu control.

This code is made available under the MIT license. See LICENSE for further
information.
"""

const TWODEE_TEXTURE = preload("icons/2D.svg")
const POINTS_TEXTURE = preload("icons/PointMesh.svg")
const GRID_TEXTURE = preload("icons/Grid.svg")
const ORIGIN_TEXTURE = preload("icons/CoordinateOrigin.svg")
const SCALE_TEXTURE = preload("icons/Zoom.svg")
const TOOL_TEXTURE = preload("icons/Tools.svg")

# Import the Radial Menu
const RadialMenu = preload("../RadialMenu.gd")


func create_submenu(parent_menu):
	# create a new radial menu
	var submenu = RadialMenu.new()
	# copy some important properties from the parent menu
	submenu.circle_coverage = 0.45
	submenu.width = parent_menu.width*1.25
	submenu.default_theme = parent_menu.default_theme
	submenu.show_animation = parent_menu.show_animation
	submenu.animation_speed_factor = parent_menu.animation_speed_factor
	return submenu
		

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Create a few dummy submenus
	var submenu1 = create_submenu($Node/RadialMenu)
	var submenu2 = create_submenu($Node/RadialMenu)
	var submenu3 = create_submenu($Node/RadialMenu)
	var submenu4 = create_submenu($Node/RadialMenu)
		
	# Define the main menu's items
	$Node/RadialMenu.menu_items = [
		{'texture': SCALE_TEXTURE, 'title': "Reset\nscale", 'id': "action7"},		
		{'texture': TWODEE_TEXTURE, 'title': "Axis\nSetup", 'id': submenu1}, 
		{'texture': POINTS_TEXTURE, 'title': "Dataset\nSetup", 'id': submenu2},
		{'texture': GRID_TEXTURE, 'title': "Grid\nSetup", 'id': submenu3},
		{'texture': TOOL_TEXTURE, 'title': "Advanced\nTools", 'id': submenu4},
		#{'texture': ORIGIN_TEXTURE, 'title': "Back to\norigin", 'id': "action5"},
		#{'texture': SCALE_TEXTURE, 'title': "Reset\nscale", 'id': "action6"},		
	]

	
func _input(event):
	if event is InputEventMouseButton:		
		# open the menu
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			var m = get_local_mouse_position()			
			$Node/RadialMenu.open_menu(m)
			get_viewport().set_input_as_handled()


func _on_ArcPopupMenu_item_selected(action, _position):
	$MenuResult.text = str(action)
