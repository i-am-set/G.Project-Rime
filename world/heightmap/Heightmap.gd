extends Node

var image: Image = load(ProjectSettings.get_setting("shader_globals/heightmap").value).get_image()
var amplitude: float = ProjectSettings.get_setting("shader_globals/amplitude").value

var size = image.get_width()

func set_height_map(texture : NoiseTexture2D):
	await get_tree().process_frame
	size = texture.get_width()
	image = texture.get_image()
	RenderingServer.global_shader_parameter_set("heightmap", texture)
	Global.WORLD_HEIGHT_MAP = texture

func get_height(x,z):
	if image != null:
		return image.get_pixel(fposmod(x,size), fposmod(z,size)).r * amplitude
