class_name InteractionComponent extends Node

@export var is_pickable : bool = false

var parent

func _ready():
	parent = get_parent()
	connect_parent()

func _process(delta):
	pass

# Give "get_interact_label()" to the parent to apply an interact label

func in_range() -> void:
	print("In range.")
	if parent.has_method("in_range"):
		parent.in_range()
	else:
		printerr("Doesn't have 'in_range()'")

func not_in_range() -> void:
	if parent.has_method("not_in_range"):
		parent.not_in_range()
	else:
		printerr("Doesn't have 'not_in_range()'")

func on_interact() -> void:
	print("interacted")

func connect_parent():
	parent.add_user_signal("focused")
	parent.add_user_signal("unfocused")
	parent.add_user_signal("interacted")
	parent.connect("focused", Callable(self, "in_range"))
	parent.connect("unfocused", Callable(self, "not_in_range"))
	parent.connect("interacted", Callable(self, "on_interact"))
	
