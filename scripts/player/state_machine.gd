class_name StateMachine

extends Node

@export var CURRENT_STATE : State
var states: Dictionary = {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.transition.connect(on_child_transition)
		else:
			push_warning("State machine contains incompatible child node")
	
	await owner.ready
	CURRENT_STATE.enter(null)
	
	# Set console commands
	Console.create_command("set_speed_sprint", self.c_set_speed_sprint, "Sets your sprint speed. Default is 12.0")
	Console.create_command("set_speed_walk", self.c_set_speed_walk, "Sets your walk speed. Default is 6.0")

func _process(delta):
	CURRENT_STATE.update(delta)
	Global.debug.add_property("Current State",CURRENT_STATE.name,1)
		
func _physics_process(delta):
	CURRENT_STATE.physics_update(delta)
	
func on_child_transition(new_state_name: StringName) -> void:
	var new_state = states.get(new_state_name)
	if new_state != null:
		if new_state != CURRENT_STATE:
			CURRENT_STATE.exit()
			new_state.enter(CURRENT_STATE)
			CURRENT_STATE = new_state
	else:
		push_warning("State does not exist")

func c_set_speed_sprint(speed: float) -> void:
	states["SprintingPlayerState"].SPEED = speed

func c_set_speed_walk(speed: float) -> void:
	states["WalkingPlayerState"].SPEED = speed
