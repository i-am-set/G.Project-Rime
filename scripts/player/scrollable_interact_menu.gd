extends Control

const WAILA_INTERACT_SUBTEXT_LABEL = preload("res://scenes/ui/waila_interact_subtext_label.tscn")

@onready var fps_controller: Player = $"../../.."

@onready var far_previous_selection_label: Label = $VBoxContainer/FarPreviousSelection
@onready var previous_selection_label: Label = $VBoxContainer/PreviousSelection
@onready var current_selection_label: Label = $VBoxContainer/CurrentSelection
@onready var next_selection_label: Label = $VBoxContainer/NextSelection
@onready var far_next_selection_label: Label = $VBoxContainer/FarNextSelection

@onready var waila_interact_subtext_v_box_container: VBoxContainer = $WAILAInteractLabel/WAILAInteractSubtextVBoxContainer
@onready var selector: Label = $VBoxContainer/CurrentSelection/Selector

@onready var ellipses_previous: Label = $VBoxContainer/EllipsesPrevious
@onready var ellipses_next: Label = $VBoxContainer/EllipsesNext


var interacted_collider = null
var interacted_collider_id : String = ""

var ellipses_text = "  . . ."
var current_selection : int
var cached_menu_options
var menu_options = [
	{'title': 'Inquire', 'color': '#ffffff', 'id': 'arc_id1', 'imbedded_data' : '', 'selector': '>'},
	{'title': 'Combine', 'color': '#ffffff', 'id': 'arc_id2', 'imbedded_data' : '', 'selector': '>'},	
	{'title': 'Uncombine (All)', 'color': '#ffffff', 'id': 'arc_id3', 'imbedded_data' : '', 'selector': '>'},	
	{'title': 'Craft (Flint Spear)', 'color': '#ffffff', 'id': 'arc_id4', 'imbedded_data' : '', 'selector': '>'},	
	{'title': 'Start fire pit', 'color': '#ffffff', 'id': 'arc_id5', 'imbedded_data' : '', 'selector': '>'},	
	{'title': 'Item6', 'color': '#ffffff', 'id': 'arc_id6', 'imbedded_data' : '', 'selector': '>'},	
	{'title': 'Item7', 'color': '#ffffff', 'id': 'arc_id7', 'imbedded_data' : '', 'selector': '>'},	
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

func set_waila_interact_subtext():
	var _imbedded_data = menu_options[current_selection]["imbedded_data"]
	if _imbedded_data == "":
		return
	
	if interacted_collider != null && StaticData.recipe_data.has(_imbedded_data):
		if not "combined_items" in interacted_collider:
			return
		var _recipe = StaticData.recipe_data[_imbedded_data]
		for _recipe_component in _recipe:
			if _recipe_component[0] != "a":
				continue
			var _required_component_amount = _recipe[_recipe_component]
			var _subtext_item = WAILA_INTERACT_SUBTEXT_LABEL.instantiate()
			var _recipe_component_count = 0
			for _item in interacted_collider.combined_items:
				if _item.item_id == _recipe_component:
					_recipe_component_count += 1
			var _text = str(_required_component_amount) + "x " + StaticData.item_data[_recipe_component]["item_name"] + " : " + str(_recipe_component_count) + "/" + str(_required_component_amount)
			_subtext_item.text = _text
			if _recipe_component_count < _required_component_amount:
				_subtext_item.set("theme_override_colors/font_color", Color.html(Global.COLOR_RED_HTML))
			else:
				_subtext_item.set("theme_override_colors/font_color", Color.html(Global.COLOR_WHITE_HTML))
			waila_interact_subtext_v_box_container.add_child(_subtext_item)
		
		if StaticData.recipe_data[_imbedded_data].has("recipe_tool_requirement"):
			var _recipe_tool_requirement = StaticData.recipe_data[_imbedded_data]["recipe_tool_requirement"]
			var _tool_requirement_subtext = WAILA_INTERACT_SUBTEXT_LABEL.instantiate()
			if _recipe_tool_requirement == 0:
				_tool_requirement_subtext.text = "TOOL REQUIRED : Hammer"
			elif _recipe_tool_requirement == 1:
				_tool_requirement_subtext.text = "TOOL REQUIRED : Blade"
			var _currently_held_item = fps_controller.inventory_menu.get_selected_item()
			if _currently_held_item != null && StaticData.item_data[_currently_held_item.item_id]["item_hammer_value"] > 0:
				_tool_requirement_subtext.set("theme_override_colors/font_color", Color.html(Global.COLOR_WHITE_HTML))
			else:
				_tool_requirement_subtext.set("theme_override_colors/font_color", Color.html(Global.COLOR_RED_HTML))
			waila_interact_subtext_v_box_container.add_child(_tool_requirement_subtext)

func clear_waila_interact_subtext():
	var _children = waila_interact_subtext_v_box_container.get_children()
	for _child in _children:
		_child.queue_free()

func update_menu_option_visuals():
	var options = [
		{"label": far_previous_selection_label, "index": current_selection - 2},
		{"label": previous_selection_label, "index": current_selection - 1},
		{"label": current_selection_label, "index": current_selection, "prefix": ""},
		{"label": next_selection_label, "index": current_selection + 1},
		{"label": far_next_selection_label, "index": current_selection + 2}
	]
	
	selector.text = menu_options[current_selection]["selector"]
	clear_waila_interact_subtext()
	set_waila_interact_subtext()
	
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
