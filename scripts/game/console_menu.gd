extends Control

func _ready():
	visible = false

func toggle_debug_console():
	# Toggle debug console
	visible = !visible
	Global.IS_PAUSED = visible
	Global.MOUSE_CAPTURED = visible
	if visible:
		Global.capture_mouse(false)
	else:
		Global.capture_mouse(true)
