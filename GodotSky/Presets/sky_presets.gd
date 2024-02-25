extends Resource

class_name SkyPreset

@export_category("GodotSky Settings")
@export_group("Sun Adjustments")
@export_range(0,0.001,0.00001) var sunRadius : float = 0.0003
@export_range(1500,10000,50) var sunEdgeBlur : float = 3600.0
@export var sunLightIntensity : Curve = preload("res://GodotSky/Presets/default/sunLightIntensity.tres")
@export_range(0,1,0.01) var sunGlowIntensity : float = 0.45
@export_group("Moon Adjustments")
@export_range(0,0.001,0.00001) var moonRadius : float = 0.0003
@export_range(1500,10000,50) var moonEdgeBlur : float = 10000.0
@export var moonLightIntensity : Curve = preload("res://GodotSky/Presets/default/moonLightIntensity.tres")
@export_range(0,1,0.01) var moonGlowIntensity : float = 0.8
@export_group("Horizon Adjustments")
@export_range(1.0,7.0,0.1) var horizonSize : float = 3.0;
@export_range(0.0,1.0,0.01) var horizonAlpha : float = 1.0;
@export_group("Clouds")
@export_range(0.0, 0.003, 0.00001) var cloudSpeed : float = 0.0003
@export var cloudDirection : Vector2 = Vector2(1.0,1.0)
@export_range(0.0, 8.0, 0.05) var cloudDensity : float = 4.25
@export_range(0.5, 0.99, 0.01) var cloudGlow : float = 0.92
@export_range(0.0, 5.0, 0.001) var cloudLightAbsorption : float = 5.0
@export_range(0.5, 1.0, 0.001) var cloudBrightness : float = 0.9
@export_range(0.5, 1.0, 0.001) var cloudUvCurvature : float = 0.5
@export_range(0.0, 1.0, 0.001) var cloudEdge : float = 0.0
@export_range(0.5, 1.0, 0.001) var anisotropy : float = 0.69
@export_group("Stars")
@export var starColor : Color =  Color(0.43,0.55,0.91);
@export_range(0.0, 0.5, 0.01) var starBrightness : float = 0.2
@export_range(-1.0, 3.0, 1.0) var starResolution : float = 1.0
@export_range(0.0, 0.05, 0.001) var twinkleSpeed : float = 0.025
@export_range(0.5, 5.0, 0.1) var twinkleScale : float = 4.0
@export_range(0.0, 0.005, 0.0001) var starSpeed : float = 0.002
@export_group("Color Curves")
@export var baseSkyColor : GradientTexture1D = preload("res://GodotSky/Presets/default/baseSkyColor.tres")
@export var baseCloudColor : GradientTexture1D = preload("res://GodotSky/Presets/default/baseCloudColor.tres")
@export var overcastCloudColor : GradientTexture1D = preload("res://GodotSky/Presets/default/overcastCloudColor.tres")
@export var horizonFogColor : GradientTexture1D = preload("res://GodotSky/Presets/default/horizonFogColor.tres")
@export var sunLightColor : GradientTexture1D = preload("res://GodotSky/Presets/default/sunLight.tres")
@export var sunDiscColor : GradientTexture1D = preload("res://GodotSky/Presets/default/sunDiscColor.tres")
@export var sunGlow : GradientTexture1D = preload("res://GodotSky/Presets/default/sunGlowColor.tres")
@export var moonLightColor : GradientTexture1D = preload("res://GodotSky/Presets/default/moonLight.tres")
@export var moonGlowColor : GradientTexture1D = preload("res://GodotSky/Presets/default/moonGlowColor.tres")
