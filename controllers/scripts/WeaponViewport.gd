extends SubViewport

var screen_size : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_window().size
	size = screen_size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
