extends Control

func _ready():
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_click") && !Global.IS_PAUSED:
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
	Global.IS_PAUSED = visible
	if visible:
		Global.capture_mouse(false)
