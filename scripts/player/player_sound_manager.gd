extends Node

var prvious_crow_sound_index : int = 0
const CROW_SOUNDS : Array[AudioStreamWAV] = [
	preload("res://sound/sfx/birds/sfx_crow_call-01.wav"),
	preload("res://sound/sfx/birds/sfx_crow_call-02.wav"),
	preload("res://sound/sfx/birds/sfx_crow_call-03.wav"),
	preload("res://sound/sfx/birds/sfx_crow_call-04.wav"),
	preload("res://sound/sfx/birds/sfx_crow_call-05.wav"),
	preload("res://sound/sfx/birds/sfx_crow_call-06.wav"),
	preload("res://sound/sfx/birds/sfx_crow_call-07.wav"),
	preload("res://sound/sfx/birds/sfx_crow_call-08.wav"),
	preload("res://sound/sfx/birds/sfx_crow_call-09.wav")
]

var previous_footstep_index : int = 0
const FOOTSTEP_SOUNDS : Array[AudioStreamWAV] = [
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-01.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-02.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-03.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-04.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-05.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-06.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-07.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-08.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-09.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-10.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-11.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-12.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-13.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-14.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-15.wav"),
	preload("res://sound/sfx/footsteps/sfx_snow_footstep-16.wav")
]

var previous_exhale_index : int = 0
const EXHALE_SOUNDS : Array[AudioStreamWAV] = [
	preload("res://sound/sfx/human/breathing/exhale/soft_exhale-01.wav"),
	preload("res://sound/sfx/human/breathing/exhale/soft_exhale-02.wav"),
	preload("res://sound/sfx/human/breathing/exhale/soft_exhale-03.wav"),
	preload("res://sound/sfx/human/breathing/exhale/soft_exhale-04.wav"),
	preload("res://sound/sfx/human/breathing/exhale/soft_exhale-05.wav"),
	preload("res://sound/sfx/human/breathing/exhale/soft_exhale-06.wav")
]

@onready var fps_controller: Player = $".."
@onready var amb_distant_crows: AudioStreamPlayer3D = $AmbientSounds/AmbDistantCrows
@onready var crow_cooldown_timer: Timer = $AmbientSounds/AmbDistantCrows/CrowCooldownTimer
@onready var wind_audio_player: Node3D = $AmbientSounds/WindAudioPlayer
@onready var wind_secondary_audio_player: Node3D = $AmbientSounds/WindSecondaryAudioPlayer
@onready var sfx_left_footstep: AudioStreamPlayer3D = $SfxLeftFootstep
@onready var sfx_right_footstep: AudioStreamPlayer3D = $SfxRightFootstep
@onready var sfx_exhale_inhale = $SfxExhaleInhale
@onready var sfx_button_hover: AudioStreamPlayer = $SfxButtonHover
@onready var sfx_button_click: AudioStreamPlayer = $SfxButtonClick


var wind_audio_players_default_volume : int = -20
var wind_secondary_audio_player_default_volume : int = -40
var cached_wind_direction : Vector2
var sfx_distant_crows_distance : int = 50

func _ready() -> void:
	start_distant_crow_amb_cooldown_timer()

func _physics_process(delta: float) -> void:
	if fps_controller._is_authorized_user:
		var current_wind_direction = Global.WIND_DIRECTION * 3
		if current_wind_direction != cached_wind_direction:
			wind_audio_player.position = fps_controller.position + Vector3(current_wind_direction.x, 2.5, current_wind_direction.y)
			wind_secondary_audio_player.position = fps_controller.position + Vector3(-current_wind_direction.x, 2.5, -current_wind_direction.y)

func _on_sfx_distant_crows_finished() -> void:
	start_distant_crow_amb_cooldown_timer()

func _on_crow_cooldown_timer_timeout() -> void:
	displace_amb_3d_node_crow()
	play_distant_crow_amb()

func start_distant_crow_amb_cooldown_timer():
	crow_cooldown_timer.wait_time = randi_range(1, 85)
	crow_cooldown_timer.start()

func play_distant_crow_amb():
	amb_distant_crows.volume_db = randi_range(-20, 0)
	var crow_sound_index : int = prvious_crow_sound_index
	while crow_sound_index == prvious_crow_sound_index:
		crow_sound_index = randi() % CROW_SOUNDS.size()
	amb_distant_crows.stream = CROW_SOUNDS[crow_sound_index]
	amb_distant_crows.play()

func displace_amb_3d_node_crow():
	var angle = randf_range(0, 2 * PI)
	var distance = sfx_distant_crows_distance
	var amb_distant_crows_position = amb_distant_crows.position
	var x = distance * cos(angle)
	var y = distance * sin(angle)
	var z = 10
	
	amb_distant_crows_position = fps_controller.position + Vector3(x, y, z)

func footstep_left():
	if fps_controller._is_authorized_user && fps_controller.is_on_floor() && !fps_controller._is_crouching:
		footstep_left_logic()
		send_p2p_packet(0, {"message": "footstep", "steam_id": fps_controller._steam_ID, "foot": 0})

func footstep_right():
	if fps_controller._is_authorized_user && fps_controller.is_on_floor() && !fps_controller._is_crouching:
		footstep_right_logic()
		send_p2p_packet(0, {"message": "footstep", "steam_id": fps_controller._steam_ID, "foot": 0})

func footstep_left_logic():
	var footstep_index : int = previous_footstep_index
	while footstep_index == previous_footstep_index:
		footstep_index = randi() % FOOTSTEP_SOUNDS.size()
	if !sfx_left_footstep.playing:
		sfx_left_footstep.stream = FOOTSTEP_SOUNDS[footstep_index]
		sfx_left_footstep.pitch_scale = randf_range(0.95, 1.05)
		sfx_left_footstep.play()

func footstep_right_logic():
	var footstep_index : int = previous_footstep_index
	while footstep_index == previous_footstep_index:
		footstep_index = randi() % FOOTSTEP_SOUNDS.size()
	if !sfx_right_footstep.playing:
		sfx_right_footstep.stream = FOOTSTEP_SOUNDS[footstep_index]
		sfx_right_footstep.pitch_scale = randf_range(0.95, 1.05)
		sfx_right_footstep.play()

func play_exhale():
	var exhale_index : int = previous_exhale_index
	while exhale_index == previous_exhale_index:
		exhale_index = randi() % EXHALE_SOUNDS.size()
	if !sfx_exhale_inhale.playing:
		sfx_exhale_inhale.stream = EXHALE_SOUNDS[exhale_index]
		sfx_exhale_inhale.pitch_scale = randf_range(0.95, 1.05)
		sfx_exhale_inhale.play()

func play_inhale():
	pass
	#sfx_exhale_inhale.play()

func play_button_hover():
	sfx_button_hover.play()

func play_button_click():
	sfx_button_click.play()

func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_UNRELIABLE
	var channel: int = 0
	
	# Create a data array to send the data through
	var this_data: PackedByteArray
	
	# Compress the PackedByteArray we create from our dictionary  using the GZIP compression method
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)
	
	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if Global.LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for this_member in Global.LOBBY_MEMBERS:
				if this_member['steam_id'] != Global.STEAM_ID:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)
	
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, this_data, send_type, channel)
