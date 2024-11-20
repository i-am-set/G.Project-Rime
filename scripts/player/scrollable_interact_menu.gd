extends Control

@onready var far_previous_selection_label: Label = $VBoxContainer/FarPreviousSelection
@onready var previous_selection_label: Label = $VBoxContainer/PreviousSelection
@onready var current_selection_label: Label = $VBoxContainer/CurrentSelection
@onready var next_selection_label: Label = $VBoxContainer/NextSelection
@onready var far_next_selection_label: Label = $VBoxContainer/FarNextSelection

@onready var ellipses_previous: Label = $VBoxContainer/EllipsesPrevious
@onready var ellipses_next: Label = $VBoxContainer/EllipsesNext


var interacted_collider = null
var interacted_collider_id : String = ""

var ellipses_text = "  . . ."
var current_selection : int
var cached_menu_options
var menu_options = [
	{'title': 'Inquire', 'color': '#ffffff', 'id': 'arc_id1'},
	{'title': 'Combine', 'color': '#ffffff', 'id': 'arc_id2'},	
	{'title': 'Uncombine (All)', 'color': '#ffffff', 'id': 'arc_id3'},	
	{'title': 'Craft (Flint Spear)', 'color': '#ffffff', 'id': 'arc_id4'},	
	{'title': 'Start fire pit', 'color': '#ffffff', 'id': 'arc_id5'},	
	{'title': 'Item6', 'color': '#ffffff', 'id': 'arc_id6'},	
	{'title': 'Item7', 'color': '#ffffff', 'id': 'arc_id7'},	
] : set = set_menu_options

func _ready() -> void:
	visible = false
	ellipses_previous.text = ""
	ellipses_next.text = ""
	update_menu_option_visuals()

func set_menu_options(_options):
	"""
	Changes the menu options. Expects a list of 3-item dictionaries with the
	keys 'title', 'color', and 'id'.
	"""
	current_selection = 0
	clear_menu_options()
	menu_options = _options
	update_menu_option_visuals()

func set_sub_menu_items(_sub_options):
	cached_menu_options = menu_options.duplicate()
	current_selection = 0
	clear_menu_options()
	menu_options = _sub_options
	update_menu_option_visuals()

func back_out_of_sub_menu_options():
	if cached_menu_options == null:
		close_interact_menu()
		print_debug("cached_menu_options not present for back function")
		return
	
	set_menu_options(cached_menu_options)

func open_interact_menu():
	current_selection = 0
	cached_menu_options = null
	visible = true
	update_menu_option_visuals()

func close_interact_menu():
	clear_menu_options()
	interacted_collider = null
	interacted_collider_id = ""
	visible = false

func clear_menu_options():
	menu_options.clear()

func previous_menu_option():
	if current_selection - 1 >= 0:
		current_selection -= 1
	else:
		current_selection = 0
	
	update_menu_option_visuals()

func next_menu_option():
	if current_selection + 1 < menu_options.size():
		current_selection += 1
	else:
		current_selection = menu_options.size()-1
	
	update_menu_option_visuals()

func update_menu_option_visuals():
	var options = [
		{"label": far_previous_selection_label, "index": current_selection - 2},
		{"label": previous_selection_label, "index": current_selection - 1},
		{"label": current_selection_label, "index": current_selection, "prefix": ""},
		{"label": next_selection_label, "index": current_selection + 1},
		{"label": far_next_selection_label, "index": current_selection + 2}
	]
	
	for option in options:
		var prefix = "  "
		if option.has("prefix"):
			prefix = option["prefix"]
		if option.index >= 0 and option.index < menu_options.size():
			option.label.text = prefix + menu_options[option.index]["title"]
			option.label.set("theme_override_colors/font_color", Color.html(menu_options[option.index]["color"]))
		else:
			option.label.text = ""
	
	if current_selection - 3 >= 0:
		ellipses_previous.text = ellipses_text
	else:
		ellipses_previous.text = ""
	
	if current_selection + 3 < menu_options.size():
		ellipses_next.text = ellipses_text
	else:
		ellipses_next.text = ""
