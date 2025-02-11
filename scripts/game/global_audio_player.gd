extends AudioStreamPlayer

const world_drone = preload("res://sound/music/mus_world_drone_track_1.wav")

func _play_music(music: AudioStream, volume = 0.0):
	if stream == music:
		return
	
	stream = music
	volume_db = volume
	play()

func play_world_drone():
	_play_music(world_drone, -36.0)
