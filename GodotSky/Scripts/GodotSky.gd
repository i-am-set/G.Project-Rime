
extends WorldEnvironment

signal temperature_set

# General settings for time of day, on/off for simulating day and night cycle, rate of time, and overall rotation of the sky
@export_category("GodotSky Control")
@export_range(0,2400,0.01) var timeOfDay : float = 700.0
@export var simulateTime : bool = false
@export_range(0,10,0.0005) var rateOfTime : float = 0.1
@export_range(0,360,0.1) var skyRotation : float = 0.0
@export_enum("Static", "2D Dynamic") var cloudType : String = "Static"
@export_range(0,1,0.001) var cloudCoverage : float = 0.5
#@export var staticClouds : bool = true *DEPRECATED*
@export var animateStaticClouds : bool = true
@export var animateStarMap : bool = true
@export var sunShadow : bool = true
@export var moonShadow : bool = true
@export_category("GodotSky Preset")
@export var skyPreset : SkyPreset = preload("res://GodotSky/Presets/sky_default.tres")

# Get required node references
@onready var sunWarmthMultiplierCurve = preload("res://scenes/utility/sun_warmth_multiplier_curve.tres")
@onready var sunMoonParent = $SunMoon
@onready var sunRoot : MeshInstance3D = $SunMoon/Sun
@onready var moonRoot : MeshInstance3D = $SunMoon/Moon
@onready var sun : DirectionalLight3D = $SunMoon/Sun/SunLight
@onready var moon : DirectionalLight3D = $SunMoon/Moon/MoonLight
@onready var sky : WorldEnvironment = $"."
@onready var world: Node3D = $".."


var sunPosition : float = 0.0
var moonPosition : float = 0.0
var sunPosAlpha : float = 0.0

# temperature variables
var cached_temperature = Global.CURRENT_TEMPERATURE_C


# Check if simulating day/night cycle, determine rate of time, and increase time
func simulateDay():
	if (simulateTime == true):
		timeOfDay += rateOfTime
		if (timeOfDay >= 2400.0):
			timeOfDay = 0.0
			set_temp_for_day()
		Global.TIME_OF_DAY = snapped(timeOfDay, 0.01)
		if Global.GLOBAL_TICK % 100 == 0:
			update_temperature()
		#Global.SUN_WARMTH_MULTIPLIER = clamp(((snapped(sunWarmthMultiplierCurve.sample(sunPosition), 0.01) + 1) - cloudCoverage), 1, 2)

func update_temperature():
	var time_ratio = timeOfDay / 2400.0
	if time_ratio <= 0.5:
		Global.CURRENT_TEMPERATURE_C = lerp(cached_temperature, Global.TEMPERATURE_HIGH_C, time_ratio * 2)
	else:
		Global.CURRENT_TEMPERATURE_C = lerp(Global.TEMPERATURE_HIGH_C, Global.TEMPERATURE_LOW_C, (time_ratio - 0.5) * 2)
	

func set_temp_for_day():
	if world._is_server_host:
		var temperature_high
		var temperature_low
		
		var temperature_max_increase = 15
		
		cached_temperature = Global.CURRENT_TEMPERATURE_C
		
		if cached_temperature + temperature_max_increase > Global.MAX_TEMPERATURE_C:
			temperature_high = cached_temperature + randf_range(-3, 0)
		elif cached_temperature - 3 < Global.MIN_TEMPERATURE:
			temperature_high = cached_temperature + randf_range(0, temperature_max_increase)
		else:
			temperature_high = cached_temperature + randf_range(-3, temperature_max_increase)
		
		temperature_low = temperature_high - randf_range(1, 6)
		
		Global.TEMPERATURE_HIGH_C = temperature_high
		Global.TEMPERATURE_LOW_C = temperature_low
		
		emit_signal("temperature_set")

# Update sun and moon based on current time of day 
func updateLights():
	sunPosition = sunRoot.global_position.y / 2.0 + 0.5
	moonPosition = moonRoot.global_position.y / 2.0 + 0.5
	sun.light_color = skyPreset.sunLightColor.gradient.sample(sunPosition)
	
	#sun.shadow_enabled = sunShadow
	moon.light_color = skyPreset.moonLightColor.gradient.sample(sunPosition)
	
	#moon.shadow_enabled = moonShadow
	match cloudType:
		"Static":
			sun.light_energy = clamp(skyPreset.sunLightIntensity.sample(sunPosition),0.0,1.0)
			moon.light_energy = clamp(skyPreset.moonLightIntensity.sample(sunPosition),0.0,1.0)
		"2D Dynamic":
			sun.light_energy = clamp(skyPreset.sunLightIntensity.sample(sunPosition) * (1.0 - (cloudCoverage + 0.2)),0.0,1.0)
			moon.light_energy = clamp(skyPreset.moonLightIntensity.sample(sunPosition)  * (1.0 - (cloudCoverage + 0.2)),0.0,1.0)

# Update rotation of sun and moon
func updateRotation():
	var hourMapped = remap(timeOfDay, 0.0, 2400.0 ,0.0 ,1.0)
	sunMoonParent.rotation_degrees.y = skyRotation
	sunMoonParent.rotation_degrees.x = hourMapped * 360.0
	
# Update colors based on current time of day
func updateSky():
	sunPosition = sunRoot.global_position.y / 2.0 + 0.5
	
	var skyMaterial = self.environment.sky.get_material()
	var cloudColor = lerp(skyPreset.baseCloudColor.gradient.sample(sunPosition),skyPreset.overcastCloudColor.gradient.sample(sunPosition),cloudCoverage)
	
	skyMaterial.set_shader_parameter("bAnimStars",animateStarMap)
	skyMaterial.set_shader_parameter("bAnimClouds",animateStaticClouds)
	#skyMaterial.set_shader_parameter("bStaticClouds",staticClouds) *DEPRECATED*
	
	skyMaterial.set_shader_parameter("baseColor", skyPreset.baseSkyColor.gradient.sample(sunPosition))
	skyMaterial.set_shader_parameter("baseCloudColor", cloudColor)
	skyMaterial.set_shader_parameter("horizonSize",skyPreset.horizonSize)
	skyMaterial.set_shader_parameter("horizonAlpha",skyPreset.horizonAlpha)
	skyMaterial.set_shader_parameter("horizonFogColor", skyPreset.horizonFogColor.gradient.sample(sunPosition))
	
	match cloudType:
		"Static":
			skyMaterial.set_shader_parameter("cloudType",0)
		"2D Dynamic":
			skyMaterial.set_shader_parameter("cloudType",1)
			#self.environment.volumetric_fog_density = remap(cloudCoverage,0.5,1.0,0.0,0.024)
	
	skyMaterial.set_shader_parameter("cloudDensity",skyPreset.cloudDensity)
	skyMaterial.set_shader_parameter("mgSize",skyPreset.cloudGlow)
	skyMaterial.set_shader_parameter("cloudSpeed",skyPreset.cloudSpeed)
	skyMaterial.set_shader_parameter("cloudDirection",skyPreset.cloudDirection)
	skyMaterial.set_shader_parameter("cloudCoverage",cloudCoverage)
	skyMaterial.set_shader_parameter("absorption",skyPreset.cloudLightAbsorption)
	skyMaterial.set_shader_parameter("henyeyGreensteinLevel",skyPreset.anisotropy)
	skyMaterial.set_shader_parameter("cloudEdge",skyPreset.cloudEdge)
	skyMaterial.set_shader_parameter("dynamicCloudBrightness",skyPreset.cloudBrightness)
	skyMaterial.set_shader_parameter("horizonUVCurve",skyPreset.cloudUvCurvature)
	
	skyMaterial.set_shader_parameter("sunRadius",skyPreset.sunRadius)
	skyMaterial.set_shader_parameter("sunDiscColor", skyPreset.sunDiscColor.gradient.sample(sunPosition))
	skyMaterial.set_shader_parameter("sunGlowColor",skyPreset.sunGlow)
	skyMaterial.set_shader_parameter("sunGlowColor", skyPreset.sunGlow.gradient.sample(sunPosition))
	skyMaterial.set_shader_parameter("sunEdgeBlur",skyPreset.sunEdgeBlur)
	skyMaterial.set_shader_parameter("sunGlowIntensity",skyPreset.sunGlowIntensity)
	skyMaterial.set_shader_parameter("sunlightColor", skyPreset.sunLightColor.gradient.sample(sunPosition))
	
	skyMaterial.set_shader_parameter("moonRadius",skyPreset.moonRadius)
	skyMaterial.set_shader_parameter("moonGlowColor", skyPreset.moonGlowColor.gradient.sample(sunPosition))
	skyMaterial.set_shader_parameter("moonEdgeBlur",skyPreset.moonEdgeBlur)
	skyMaterial.set_shader_parameter("moonGlowIntensity",skyPreset.moonGlowIntensity)
	skyMaterial.set_shader_parameter("moonLightColor", skyPreset.moonLightColor.gradient.sample(sunPosition))
	
	skyMaterial.set_shader_parameter("starColor",skyPreset.starColor)
	skyMaterial.set_shader_parameter("starBrightness",skyPreset.starBrightness)
	skyMaterial.set_shader_parameter("twinkleSpeed",skyPreset.twinkleSpeed)
	skyMaterial.set_shader_parameter("twinkleScale",skyPreset.twinkleScale)
	skyMaterial.set_shader_parameter("starResolution",skyPreset.starResolution)
	skyMaterial.set_shader_parameter("starSpeed",skyPreset.starSpeed)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_temp_for_day()
	#await get_tree().create_timer(3).timeout
	#self.environment.sdfgi_enabled = false
	#await get_tree().create_timer(3).timeout
	#self.environment.sdfgi_enabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	simulateDay()
	updateRotation()
	updateSky()
	updateLights()
