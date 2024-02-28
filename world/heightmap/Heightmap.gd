extends Node

var image: Image = load(ProjectSettings.get_setting("shader_globals/heightmap").value).get_image()
var amplitude_mask: Image = load(ProjectSettings.get_setting("shader_globals/amplitude_mask_heightmap").value).get_image()
var amplitude: float = ProjectSettings.get_setting("shader_globals/amplitude").value

var size = image.get_width()

func set_height_map(texture : NoiseTexture2D, textureAmp : NoiseTexture2D):
	await get_tree().process_frame
	size = texture.get_width()
	image = texture.get_image()
	amplitude_mask = textureAmp.get_image()
	RenderingServer.global_shader_parameter_set("heightmap", texture)
	RenderingServer.global_shader_parameter_set("amplitude_mask_heightmap", textureAmp)
	Global.WORLD_HEIGHT_MAP = texture

func get_height(x,z):
	if image != null:
		var  amplitudeValue = amplitude_mask.get_pixel(fposmod(x,size), fposmod(z,size)).r
		return image.get_pixel(fposmod(x,size), fposmod(z,size)).r * amplitude * amplitudeValue
