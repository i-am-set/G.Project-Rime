extends Node
class_name PlayerData

signal health_changed(diff : int)
signal health_depleted
signal hunger_changed(diff : int)
signal hunger_depleted
signal temperature_changed(diff : int)
signal temperature_depleted
signal stamina_depleted
signal stamina_regened

@onready var fps_controller: Player = $".."
@onready var stamina_bar: Control = $"../UserInterface/Hud/StaminaBar"
@onready var stamina_bar_left: ProgressBar = $"../UserInterface/Hud/StaminaBar/StaminaBarLeft"
@onready var stamina_bar_right: ProgressBar = $"../UserInterface/Hud/StaminaBar/StaminaBarRight"
@onready var stamina_bar_animation_player: AnimationPlayer = $"../UserInterface/Hud/StaminaBarAnimationPlayer"

@export var god_mode : bool = false
@export var no_clip : bool = false

const max_health : int = 100
const min_health : int = 0
const max_stamina : int = 100
const min_stamina : int = 0
const max_temperature : int = 200
const comfortable_temperature : int = 100
const min_temperature : int = 0
const max_hunger : int = 100
const min_hunger : int = 0
const hunger_decrease_amount = 1
const stamina_decrease_amount = 1
const stamina_regen_amount = 1

var is_dead : bool = false
var is_exhausted : bool = false
var is_freezing : bool = false
var is_starving : bool = false
var health : int
var stamina : float
var temperature : int
var hunger : int
var hunger_damage : int = 1
var hunger_decrease_rate : int = 1800
var current_hunger_tick : int = 0
var stamina_decrease_rate : int = 8
var stamina_regen_rate : int = 3
var current_stamina_tick : int = 0
var current_stamina_regen_timer : float = 0
var stamina_regen_timer_duration : float = 0.75
var stamina_regen_timer_exhausted_duration : float = 2.5
var can_regen_stamina : bool = true
var not_exhausted_threshold : int = 10

func _ready() -> void:
	health = max_health
	stamina = max_stamina
	hunger = max_hunger
	temperature = comfortable_temperature

func _physics_process(delta: float) -> void:
	update_hunger_tick()
	update_stamina_tick()
	update_stamina_regen_cooldown(delta)
	update_progress_bars(delta)

func damage_player(damage : int):
	var damaged_health = health - damage
	set_health(damaged_health)

func heal_player(heal : int):
	var healed_health = health + heal
	set_health(healed_health)

func set_health(value : int):
	if value < health && god_mode:
		return
	
	var clamped_value = clampi(value, min_health, max_health)
	
	if clamped_value != health:
		var difference = clamped_value - health
		health = clamped_value
		health_changed.emit(difference)
		
		if health <= min_health:
			health = min_health
			kill()

func kill():
	is_dead = true
	health_depleted.emit()

func feed_player(value : int):
	var satiated_hunger = hunger + value
	set_hunger(satiated_hunger)

func set_hunger(value : int):
	if value < hunger && god_mode:
		return
	
	var clamped_value = clampi(value, min_hunger, max_hunger)
	
	if clamped_value != hunger:
		var difference = clamped_value - hunger
		hunger = clamped_value
		hunger_changed.emit(difference)
		
		if hunger <= min_hunger:
			hunger = min_hunger
			starve()
		elif is_starving:
			is_starving = false

func starve():
	is_starving = true
	hunger_depleted.emit()

func chill_player(value : int):
	var chilled_amount = temperature - value
	set_temperature(chilled_amount)

func warm_player(value : int):
	var warmed_amoung = temperature + value
	set_temperature(warmed_amoung)

func set_temperature(value : int):
	if value < temperature && god_mode:
		return
	
	var clamped_value = clampi(value, min_temperature, max_temperature)
	
	if clamped_value != temperature:
		var difference = clamped_value - temperature
		temperature = clamped_value
		temperature_changed.emit(difference)
		
		if temperature <= min_temperature:
			temperature = min_temperature
			freeze()

func freeze():
	is_freezing = true
	temperature_depleted.emit()

func set_stamina(value : int):
	if value < stamina && god_mode:
		return
	
	var clamped_value = clampi(value, min_stamina, max_stamina)
	
	if clamped_value != stamina:
		stamina = clamped_value
		
		if stamina <= min_stamina:
			stamina = min_stamina
			exhausted()

func exhausted():
	is_exhausted = true
	stamina_bar_animation_player.play("stamina_bar_exhausted_flash")
	stamina_depleted.emit()

func update_hunger_tick():
	current_hunger_tick += 1
	
	if current_hunger_tick >= hunger_decrease_rate:
		current_hunger_tick = 0
		
		var new_hunger = hunger - hunger_decrease_amount
		if is_starving:
			damage_player(hunger_damage)
		else:
			set_hunger(new_hunger)

func update_stamina_tick():
	if is_exhausted && stamina >= not_exhausted_threshold:
		is_exhausted = false
		stamina_bar_animation_player.play("RESET")
		stamina_bar_animation_player.stop()
	if stamina_bar.visible == false && stamina < max_stamina:
		stamina_bar_animation_player.play("RESET")
		stamina_bar_animation_player.stop()
	
	if fps_controller.is_sprinting:
		if stamina > 0:
			current_stamina_tick += 1
			
			if current_stamina_tick >= stamina_decrease_rate:
				current_stamina_tick = 0
				
				var new_stamina = stamina - stamina_decrease_amount
				set_stamina(new_stamina)
	else:
		if can_regen_stamina:
			current_stamina_tick += 1
			
			if stamina < max_stamina && current_stamina_tick >= stamina_regen_rate:
				current_stamina_tick = 0
				
				var new_stamina = stamina + stamina_regen_amount
				set_stamina(new_stamina)
			elif stamina >= max_stamina:
				stamina_bar_animation_player.play("stamina_bar_hide_timer")
				stamina_regened.emit()

func set_stamina_regen_cooldown_timer():
	can_regen_stamina = false
	
	if is_exhausted:
		current_stamina_regen_timer = stamina_regen_timer_exhausted_duration
	else:
		current_stamina_regen_timer = stamina_regen_timer_duration

func update_stamina_regen_cooldown(delta: float):
	if current_stamina_regen_timer > 0:
		current_stamina_regen_timer -= delta
	else:
		current_stamina_regen_timer = 0
		can_regen_stamina = true

func update_progress_bars(delta: float):
	var _lerp_speed = delta * 8
	stamina_bar_left.value = lerp(stamina_bar_left.value, stamina, _lerp_speed)
	stamina_bar_right.value = lerp(stamina_bar_right.value, stamina, _lerp_speed)

#var head_temperature : int = 100
#var torso_temperature : int = 100
#var left_arm_temperature : int = 100
#var right_arm_temperature : int = 100
#var left_leg_temperature : int = 100
#var right_leg_temperature : int = 100
#var left_hand_temperature : int = 100
#var right_hand_temperature : int = 100
#var left_foot_temperature : int = 100
#var right_foot_temperature : int = 100
#
#func get_all_limb_temperature() -> Dictionary:
	#return {
		#"head": head_temperature,
		#"torso": torso_temperature,
		#"left arm": left_arm_temperature,
		#"right arm": right_arm_temperature,
		#"left leg": left_leg_temperature,
		#"right leg": right_leg_temperature,
		#"left hand": left_hand_temperature,
		#"right hand": right_hand_temperature,
		#"left foot": left_foot_temperature,
		#"right foot": right_foot_temperature
	#}
#
#func set_all_limb_temperature(temperature : float):
	#head_temperature = temperature
	#torso_temperature = temperature
	#left_arm_temperature = temperature
	#right_arm_temperature = temperature
	#left_leg_temperature = temperature
	#right_leg_temperature = temperature
#
#func get_average_limb_temperature() -> float:
	#var all_temperatures = get_all_limb_temperature()
	#var total_temperature = 0.0
	#var limb_count = 0
	#
	#for temperature in all_temperatures.values():
		#total_temperature += temperature
		#limb_count += 1
	#
	#return total_temperature / limb_count
