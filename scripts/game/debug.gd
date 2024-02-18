extends PanelContainer

@onready var property_container = %VBoxContainer

#var property
var frames_per_second : String

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Set global reference to self in Global Singleton
	Global.debug = self
	
	# Hide Debug Panel on load
	visible = false
	
#	add_debug_property("FPS",frames_per_second)
	
func _process(delta):
	
	Global.debug.add_property("FPS", frames_per_second, 0)
	
	if visible:
		# Use delta time to get approx frames per second and round to two decimal places !Disable VSync if fps is stuck at 60!
#			frames_per_second = "%.2f" % (1.0/delta) # Gets frames per second every frame
			frames_per_second = str(Engine.get_frames_per_second()) # Gets frames per second every second
#			property.text = property.name + ": " + frames_per_second
	
func _input(event):
	# Toggle debug panel
	if event.is_action_pressed("debug"):
		visible = !visible
		
# Debug funtion to add and update property
func add_property(title: String, value, order):
	var target
	target = property_container.find_child(title,true,false) # Try to find Label node with same name
	if !target: # If there is no current Label node for property (ie. inital load)
		target = Label.new() # Create new Label node
		property_container.add_child(target) # Add new node as child to VBox container
		target.name = title # Set name to title
		target.text = target.name + ": " + str(value) # Set text value
	elif visible:
		target.text = title + ": " + str(value) # Update text value
		property_container.move_child(target,order) # Reorder property based on given order value

# Callable function to add new debug property
#func add_debug_property(title : String,value):
#	property = Label.new() # Create new Label node
#	property_container.add_child(property) # Add new node as child to VBox container
#	property.name = title # Set name to title
#	property.text = property.name + value
