extends ColorRect

@onready var sound_manager: Node = $"../../SoundManager"

var freeze_shader := material
var current_freeze_screen_amount : float
var busy : bool = false

func apply_freeze_screen(_freeze_screen_amount: float, sound_index: int) -> void:
	if current_freeze_screen_amount == _freeze_screen_amount || busy == true:
		return
	
	busy = true
	var tween = create_tween()
	if _freeze_screen_amount <= 91:
		freeze_shader.set_shader_parameter("vignette_strength", 1.0)
	else:
		freeze_shader.set_shader_parameter("vignette_strength", 0.0)
	tween.tween_property(self, "current_freeze_screen_amount", _freeze_screen_amount, 2.0).set_ease(Tween.EASE_OUT_IN)
	if sound_index >= 0:
		sound_manager.play_freezing_screen(sound_index)
	await tween.finished
	busy = false


func _process(delta: float) -> void:
	freeze_shader.set_shader_parameter("inner_radius", 0.6 - (0.15 / 100.0) * (100.0 - current_freeze_screen_amount))
	freeze_shader.set_shader_parameter("outer_radius", 1.0 - (0.25 / 100.0) * (100.0 - current_freeze_screen_amount))
