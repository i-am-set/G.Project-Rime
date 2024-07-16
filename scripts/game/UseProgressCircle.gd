extends TextureProgressBar

@onready var timer = $Timer
@onready var fps_controller: Player = $"../../.."
@onready var reticle: CenterContainer = $"../../Reticle"

func start_busy_progress_circle_timer(timer_duration: float) -> void:
	fps_controller._is_busy = true
	reticle.visible = false
	self.visible = true
	timer.wait_time = timer_duration
	timer.start()

# Function to update the progress bar
func _process(delta: float) -> void:
	if timer.time_left > 0:
		var progress = (1 - timer.time_left / timer.wait_time) * 100
		self.value = progress
	else:
		self.value = 0

func _on_timer_timeout() -> void:
	fps_controller._is_busy = false
	reticle.visible = true
	self.visible = false
	self.value = 0
