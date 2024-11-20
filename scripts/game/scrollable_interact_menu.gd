extends Control

@onready var far_previous_selection_label: Label = $VBoxContainer/FarPreviousSelection
@onready var previous_selection_label: Label = $VBoxContainer/PreviousSelection
@onready var current_selection_label: Label = $VBoxContainer/CurrentSelection
@onready var next_selection_label: Label = $VBoxContainer/NextSelection
@onready var far_next_selection_label: Label = $VBoxContainer/FarNextSelection

@onready var ellipses_previous: Label = $VBoxContainer/EllipsesPrevious
@onready var ellipses_next: Label = $VBoxContainer/EllipsesNext

var ellipses_text = "  . . ."
var current_selection : int
var menu_options = [
	{'title': 'Inquire', 'id': 'arc_id1'},
	{'title': 'Combine', 'id': 'arc_id2'},	
	{'title': 'Uncombine (All)', 'id': 'arc_id3'},	
	{'title': 'Craft (Flint Spear)', 'id': 'arc_id4'},	
	{'title': 'Start fire pit', 'id': 'arc_id5'},	
	{'title': 'Item6', 'id': 'arc_id6'},	
	{'title': 'Item7', 'id': 'arc_id7'},	
] : set = set_menu_options

func _ready() -> void:
	ellipses_previous.text = ""
	ellipses_next.text = ""
	update_menu_option_visuals()

func _input(event):
	if event.is_action_pressed("ui_scroll_up"):
		previous_menu_option()
	if event.is_action_pressed("ui_scroll_down"):
		next_menu_option()

func set_menu_options(_options):
	"""
	Changes the menu options. Expects a list of 2-item dictionaries with the
	keys 'title' and 'id'.
	"""
	clear_menu_options()
	menu_options = _options

func clear_menu_options():
	menu_options.clear()

func open_menu_options():
	current_selection = 0

func previous_menu_option():
	if current_selection - 1 >= 0:
		current_selection -= 1
	else:
		current_selection = 0
	
	update_menu_option_visuals()

func next_menu_option():
	if current_selection + 1 <= menu_options.size()-1:
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
		else:
			option.label.text = ""
	
	if current_selection - 3 >= 0:
		ellipses_previous.text = ellipses_text
	else:
		ellipses_previous.text = ""
	
	if current_selection + 3 <= menu_options.size():
		ellipses_next.text = ellipses_text
	else:
		ellipses_next.text = ""
	#if current_selection-2 >= 0:
		#far_previous_selection_label.text = "  " + menu_options[current_selection-2]["title"]
	#else:
		#far_previous_selection_label.text = ""
	#if current_selection-1 >= 0:
		#previous_selection_label.text = "  " + menu_options[current_selection-1]["title"]
	#else:
		#previous_selection_label.text = ""
	#
	#current_selection_label.text = menu_options[current_selection]["title"]
	#
	#if current_selection+1 <= menu_options.size():
		#next_selection_label.text = "  " + menu_options[current_selection+1]["title"]
	#else:
		#next_selection_label.text = ""
	#if current_selection+2 <= menu_options.size():
		#far_next_selection_label.text = "  " + menu_options[current_selection+2]["title"]
	#else:
		#far_next_selection_label.text = ""
