extends Label

func _process(delta):
	if(visible):
		set_text(str(Engine.get_frames_per_second()))
