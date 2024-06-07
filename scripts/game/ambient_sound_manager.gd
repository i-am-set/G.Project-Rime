extends Node

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

@onready var fps_controller: Player = $".."
@onready var amb_distant_crows: AudioStreamPlayer3D = $AmbDistantCrows
@onready var crow_cooldown_timer: Timer = $AmbDistantCrows/CrowCooldownTimer
@onready var wind_audio_players: Node3D = $WindAudioPlayers
@onready var wind_secondary_audio_player: Node3D = $WindSecondaryAudioPlayer


var cached_wind_direction : Vector2


var sfx_distant_crows_distance : int = 50

func _ready() -> void:
	start_distant_crow_amb_cooldown_timer()

func _physics_process(delta: float) -> void:
	var current_wind_direction = Global.WIND_DIRECTION * 3
	if current_wind_direction != cached_wind_direction:
		wind_audio_players.position = fps_controller.position + Vector3(current_wind_direction.x, 2.5, current_wind_direction.y)
		wind_secondary_audio_player.position = fps_controller.position + Vector3(-current_wind_direction.x, 2.5, -current_wind_direction.y)

func _on_sfx_distant_crows_finished() -> void:
	start_distant_crow_amb_cooldown_timer()

func _on_crow_cooldown_timer_timeout() -> void:
	displace_amb_3d_node()
	play_distant_crow_amb()

func start_distant_crow_amb_cooldown_timer():
	crow_cooldown_timer.wait_time = randi_range(1, 20)
	crow_cooldown_timer.start()

func play_distant_crow_amb():
	amb_distant_crows.volume_db = randi_range(-10, 0)
	amb_distant_crows.stream = CROW_SOUNDS[randi() % CROW_SOUNDS.size()]
	amb_distant_crows.play()

func displace_amb_3d_node():
	var angle = randf_range(0, 2 * PI)
	var distance = sfx_distant_crows_distance
	var amb_distant_crows_position = amb_distant_crows.position
	var x = distance * cos(angle)
	var y = distance * sin(angle)
	var z = 10
	
	amb_distant_crows_position = fps_controller.position + Vector3(x, y, z)
