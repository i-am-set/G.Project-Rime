extends Control

func _ready():
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_click") && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE:
		pass
		#Global.capture_mouse(true)
	elif event.is_action_pressed("exit"):
		if (visible):
			toggle_debug_console()
	elif event.is_action_pressed("debug"):
		toggle_debug_console()

func toggle_debug_console():
	# Toggle debug console
	visible = !visible
	Global.IS_IN_CONSOLE = visible
	if visible:
		Global.capture_mouse(false)
	else:
		if !Global.IS_PAUSED && !Global.IS_IN_INVENTORY && Global.IS_IN_GAME:
				Global.capture_mouse(true)
