extends Camera3D

@export var MAIN_CAMERA : Node3D

# Match Weapon Camera to Player Camera
func _process(delta: float) -> void:
	if MAIN_CAMERA != null:
		global_transform = MAIN_CAMERA.global_transform
