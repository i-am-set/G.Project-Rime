extends RayCast3D
@export var steps_player: AudioStreamPlayer3D
func _physics_process(_delta: float) -> void:
	if !is_colliding(): return
	
	var col := get_collider() #this is the static body!
