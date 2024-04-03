extends Resource
class_name PlayerData

@export var god_mode : bool = false
@export var no_clip : bool = false

const max_health : int = 100
const min_health : int = 0
const max_stamina : int = 100
const min_stamina : int = 0
const max_temperature : int = 200
const min_temperature : int = 200

var health : int = 100
var stamina : int = 100
var head_temperature : int = 100
var torso_temperature : int = 100
var left_arm_temperature : int = 100
var right_arm_temperature : int = 100
var left_leg_temperature : int = 100
var right_leg_temperature : int = 100

func get_all_limb_temperature() -> Dictionary:
	return {
		"head": head_temperature,
		"torso": torso_temperature,
		"left arm": left_arm_temperature,
		"right arm": right_arm_temperature,
		"left leg": left_leg_temperature,
		"right leg": right_leg_temperature
	}

func set_all_limb_temperature(temperature : float):
	head_temperature = temperature
	torso_temperature = temperature
	left_arm_temperature = temperature
	right_arm_temperature = temperature
	left_leg_temperature = temperature
	right_leg_temperature = temperature

func get_average_limb_temperature() -> float:
	var all_temperatures = get_all_limb_temperature()
	var total_temperature = 0.0
	var limb_count = 0

	for temperature in all_temperatures.values():
		total_temperature += temperature
		limb_count += 1

	return total_temperature / limb_count

func get_temperature_color(temperature) -> Color:
	var blue = Color(0, 0, 1)  # Blue color
	var green = Color(0, 1, 0)  # Green color
	var red = Color(1, 0, 0)  # Red color

	if temperature <= 100:
		# Interpolate between blue and green for values 0-100
		return blue.lerp(green, temperature / 100.0)
	else:
		# Interpolate between green and red for values 100-200
		return green.lerp(red, (temperature - 100) / 100.0)
