extends Control

var _current_game_settings
var _current_video_settings
var _current_control_settings
var _current_audio_settings

@onready var fps_controller: Player = $"../../.."


@onready var fov_slider: HSlider = $VBoxContainer/Options_Settings/Game_Settings_Scroll/HBoxContainer/VBoxContainer/_FieldOfView/FovSlider

@onready var celsius: Button = $VBoxContainer/Options_Settings/Game_Settings_Scroll/HBoxContainer/VBoxContainer/_Temperature_Unit/DisplayModes/Celsius
@onready var fahrenheit: Button = $VBoxContainer/Options_Settings/Game_Settings_Scroll/HBoxContainer/VBoxContainer/_Temperature_Unit/DisplayModes/Fahrenheit

@onready var fps_checkbox = $VBoxContainer/Options_Settings/Game_Settings_Scroll/HBoxContainer/VBoxContainer/_FPS_Display/fps_checkbox

@onready var fullscreen: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Display_Mode/DisplayModes/Fullscreen
@onready var borderless: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Display_Mode/DisplayModes/Borderless
@onready var windowed: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Display_Mode/DisplayModes/Windowed

@onready var resolution_option_button: OptionButton = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Resolution/Resolution_OptionButton

@onready var scale_slider: HSlider = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Scale/Scale_Box/ScaleSlider

@onready var vsync_checkbox: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Vsync/vsync_checkbox

@onready var screen_selector: OptionButton = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Screen_Select/Screen_Selector

@onready var sens_slider: HSlider = $VBoxContainer/Options_Settings/Controls_Settings_Scroll/HBoxContainer/VBoxContainer/_Sensitivity/SensSlider

@onready var master_slider: HSlider = $VBoxContainer/Options_Settings/Audio_Settings_Scroll/HBoxContainer/VBoxContainer/Master/MasterSlider
@onready var music_slider: HSlider = $VBoxContainer/Options_Settings/Audio_Settings_Scroll/HBoxContainer/VBoxContainer/Music/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/Options_Settings/Audio_Settings_Scroll/HBoxContainer/VBoxContainer/SFX/SFXSlider
@onready var ambience_slider: HSlider = $VBoxContainer/Options_Settings/Audio_Settings_Scroll/HBoxContainer/VBoxContainer/Ambience/AmbienceSlider

@onready var low_quality_shadow: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Shadow_Quality/ShadowQualities/LowQualityShadow
@onready var high_quality_shadow: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Shadow_Quality/ShadowQualities/HighQualityShadow
@onready var ultra_quality_shadow: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Shadow_Quality/ShadowQualities/UltraQualityShadow

@onready var hard_filter_shadow: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Shadow_Filter/ShadowFilters/HardFilterShadow
@onready var soft_filter_shadow: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Shadow_Filter/ShadowFilters/SoftFilterShadow
@onready var soft_ultra_filter_shadow: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_Shadow_Filter/ShadowFilters/SoftUltraFIlterShadow

@onready var low_quality_ssil: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_SSIL_Quality/SSILQualities/LowQualitySSIL
@onready var high_quality_ssil: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_SSIL_Quality/SSILQualities/HighQualitySSIL
@onready var ultra_quality_ssil: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_SSIL_Quality/SSILQualities/UltraQualitySSIL

@onready var low_quality_ssao: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_SSAO_Quality/SSAOQualities/LowQualitySSAO
@onready var high_quality_ssao: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_SSAO_Quality/SSAOQualities/HighQualitySSAO
@onready var ultra_quality_ssao: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_SSAO_Quality/SSAOQualities/UltraQualitySSAO

@onready var outline_checkbox: Button = $VBoxContainer/Options_Settings/Video_Settings_Scroll/HBoxContainer/VBoxContainer/_PostP_Outline/outline_checkbox



@onready var back_button: Button = $VBoxContainer/BackAndApplyHBox/BackButton
@onready var apply_button: Button = $VBoxContainer/BackAndApplyHBox/ApplyButton

const Resolutions: Dictionary = {"3840x2160":Vector2i(3840,2160),
								"2560x1440":Vector2i(2560,1080),
								"1920x1080":Vector2i(1920,1080),
								"1600x900":Vector2i(1600,900),
								"1536x864":Vector2i(1536,864),
								"1440x900":Vector2i(1440,900),
								"1366x768":Vector2i(1366,768),
								"1280x720":Vector2i(1280,720),
								"1024x600":Vector2i(1024,600),
								"800x600": Vector2i(800,600)}

var initialized : bool = false

# game
var fov : int
var temperature_unit : int
var display_fps : bool
# video
var display_mode : int
var resolution : String
var upscaler : int
var vsync : bool
var screen_select : int
var shadow_quality : int
var shadow_filter : int
var ssil_quality : int
var ssao_quality : int
var outline : bool
# controls
var mouse_sensitivity : float
# audio
var master_audio : int
var music_audio : int
var sfx_audio : int
var ambience_audio : int

func _physics_process(delta: float) -> void:
	if visible:
		if initialized:
			if apply_button.disabled && are_settings_different():
				apply_button.disabled = false
			elif !apply_button.disabled && !are_settings_different():
				apply_button.disabled = true

func initialize_settings():
	initialized = false
	_current_game_settings = ConfigFileHandler.load_settings("game")
	_current_video_settings = ConfigFileHandler.load_settings("video")
	_current_control_settings = ConfigFileHandler.load_settings("controls")
	_current_audio_settings = ConfigFileHandler.load_settings("audio")
	
	add_resolutions()
	get_screens()
	
	# game
	fov = _current_game_settings["fov"]
	temperature_unit = _current_game_settings["temperature_unit"]
	display_fps = _current_game_settings["display_fps"]
	# video
	display_mode = _current_video_settings["display_mode"]
	resolution = _current_video_settings["resolution"]
	upscaler = _current_video_settings["upscaler"]
	vsync = _current_video_settings["vsync"]
	screen_select = _current_video_settings["screen_select"]
	shadow_quality = _current_video_settings["shadow_quality"]
	shadow_filter = _current_video_settings["shadow_filter"]
	ssil_quality = _current_video_settings["ssil_quality"]
	ssao_quality = _current_video_settings["ssao_quality"]
	outline = _current_video_settings["outline"]
	# controls
	mouse_sensitivity = _current_control_settings["mouse_sensitivity"]
	# audio
	master_audio = _current_audio_settings["master_audio"]
	music_audio = _current_audio_settings["music_audio"]
	sfx_audio = _current_audio_settings["sfx_audio"]
	ambience_audio = _current_audio_settings["ambience_audio"]
	
	set_settings_controls()
	
	initialized = true

func set_settings_controls():
	# game
	fov_slider.value = fov
	
	if temperature_unit == 0:
		celsius.set_pressed_no_signal(true)
	elif temperature_unit == 1:
		fahrenheit.set_pressed_no_signal(true)
	else:
		celsius.set_pressed_no_signal(true)
		temperature_unit = 0
	
	if display_fps == true:
		fps_checkbox.set_pressed_no_signal(true)
	else:
		fps_checkbox.set_pressed_no_signal(false)
	
	# video
	if display_mode == 0:
		resolution_option_button.set_disabled(false)
		windowed.set_pressed_no_signal(true)
	elif display_mode == 1:
		resolution_option_button.set_disabled(true)
		borderless.set_pressed_no_signal(true)
	elif display_mode == 2:
		resolution_option_button.set_disabled(true)
		fullscreen.set_pressed_no_signal(true)
	else:
		resolution_option_button.set_disabled(false)
		windowed.set_pressed_no_signal(true)
		display_mode = 0
	
	var ID : int = 0
	if Resolutions.keys().has(resolution):
		for r in Resolutions.keys():
			if r == resolution:
				resolution_option_button.select(ID)
				break
			ID += 1
			if ID > resolution_option_button.item_count:
				resolution_option_button.select(resolution_option_button.item_count)
	
	scale_slider.value = upscaler
	
	vsync_checkbox.button_pressed = vsync
	
	screen_selector.select(screen_select)
	
	if shadow_quality == 0:
		low_quality_shadow.set_pressed_no_signal(true)
	elif shadow_quality == 1:
		high_quality_shadow.set_pressed_no_signal(true)
	elif shadow_quality == 2:
		ultra_quality_shadow.set_pressed_no_signal(true)
	else:
		high_quality_shadow.set_pressed_no_signal(true)
		shadow_quality = 1
	
	if shadow_filter == 0:
		hard_filter_shadow.set_pressed_no_signal(true)
	elif shadow_filter == 1:
		soft_filter_shadow.set_pressed_no_signal(true)
	elif shadow_filter == 2:
		soft_ultra_filter_shadow.set_pressed_no_signal(true)
	else:
		soft_filter_shadow.set_pressed_no_signal(true)
		shadow_filter = 1
	
	if ssil_quality == 0:
		low_quality_ssil.set_pressed_no_signal(true)
	elif ssil_quality == 1:
		high_quality_ssil.set_pressed_no_signal(true)
	elif ssil_quality == 2:
		ultra_quality_ssil.set_pressed_no_signal(true)
	else:
		high_quality_ssil.set_pressed_no_signal(true)
		ssil_quality = 1
	
	if ssao_quality == 0:
		low_quality_ssao.set_pressed_no_signal(true)
	elif ssao_quality == 1:
		high_quality_ssao.set_pressed_no_signal(true)
	elif ssao_quality == 2:
		ultra_quality_ssao.set_pressed_no_signal(true)
	else:
		high_quality_ssao.set_pressed_no_signal(true)
		ssao_quality = 1
	
	outline_checkbox.button_pressed = outline
	
	# controls
	sens_slider.value = mouse_sensitivity
	
	# audio
	master_slider.value = master_audio
	music_slider.value = music_audio
	sfx_slider.value = sfx_audio
	ambience_slider.value = ambience_audio

func add_resolutions():
	var ID = 0
	
	resolution_option_button.clear()
	
	for r in Resolutions:
		resolution_option_button.add_item(r, ID)
		ID += 1

func get_screens():
	var Screens = DisplayServer.get_screen_count()
	
	screen_selector.clear()
	
	for s in Screens:
		screen_selector.add_item("Screen: "+str(s+1))

func are_settings_different() -> bool:
	var settings = [
		[fov, _current_game_settings["fov"]],
		[temperature_unit, _current_game_settings["temperature_unit"]],
		[display_fps, _current_game_settings["display_fps"]],
		[display_mode, _current_video_settings["display_mode"]],
		[resolution, _current_video_settings["resolution"]],
		[upscaler, _current_video_settings["upscaler"]],
		[vsync, _current_video_settings["vsync"]],
		[screen_select, _current_video_settings["screen_select"]],
		[shadow_quality, _current_video_settings["shadow_quality"]],
		[shadow_filter, _current_video_settings["shadow_filter"]],
		[ssil_quality, _current_video_settings["ssil_quality"]],
		[ssao_quality, _current_video_settings["ssao_quality"]],
		[outline, _current_video_settings["outline"]],
		[mouse_sensitivity, _current_control_settings["mouse_sensitivity"]],
		[master_audio, _current_audio_settings["master_audio"]],
		[music_audio, _current_audio_settings["music_audio"]],
		[sfx_audio, _current_audio_settings["sfx_audio"]],
		[ambience_audio, _current_audio_settings["ambience_audio"]]
	]
	
	for setting in settings:
		if setting[0] != setting[1]:
			return true
	
	return false

func get_settings_different() -> Array:
	var different_settings : Array = []
	var settings = {
		"fov": [fov, _current_game_settings["fov"]],
		"temperature_unit": [temperature_unit, _current_game_settings["temperature_unit"]],
		"display_fps": [display_fps, _current_game_settings["display_fps"]],
		"display_mode": [display_mode, _current_video_settings["display_mode"]],
		"resolution": [resolution, _current_video_settings["resolution"]],
		"upscaler": [upscaler, _current_video_settings["upscaler"]],
		"vsync": [vsync, _current_video_settings["vsync"]],
		"screen_select": [screen_select, _current_video_settings["screen_select"]],
		"shadow_quality": [shadow_quality, _current_video_settings["shadow_quality"]],
		"shadow_filter": [shadow_filter, _current_video_settings["shadow_filter"]],
		"ssil_quality": [ssil_quality, _current_video_settings["ssil_quality"]],
		"ssao_quality": [ssao_quality, _current_video_settings["ssao_quality"]],
		"outline": [outline, _current_video_settings["outline"]],
		"mouse_sensitivity": [mouse_sensitivity, _current_control_settings["mouse_sensitivity"]],
		"master_audio": [master_audio, _current_audio_settings["master_audio"]],
		"music_audio": [music_audio, _current_audio_settings["music_audio"]],
		"sfx_audio": [sfx_audio, _current_audio_settings["sfx_audio"]],
		"ambience_audio": [ambience_audio, _current_audio_settings["ambience_audio"]]
	}
	
	for setting in settings.keys():
		if settings[setting][0] != settings[setting][1]:
			different_settings.append(setting)
	
	return different_settings

func backed_out():
	initialized = false

func apply_settings():
	var different_settings : Array = get_settings_different()
	
	if different_settings.has("fov"):
		if Global.FIELD_OF_VIEW != fov:
			Global.FIELD_OF_VIEW = fov
		
		print_debug("Changing 'FOV'")
		ConfigFileHandler.save_setting("game", "fov", fov)
	if different_settings.has("temperature_unit"):
		if Global.TEMPERATURE_UNIT != temperature_unit:
			Global.TEMPERATURE_UNIT = temperature_unit
		
		ConfigFileHandler.save_setting("game", "temperature_unit", temperature_unit)
	if different_settings.has("display_fps"):
		DebugAutoloadCanvas.toggle_display_fps(display_fps)
		
		ConfigFileHandler.save_setting("game", "display_fps", display_fps)
	if different_settings.has("display_mode"):
		if display_mode == 0:
			get_window().set_mode(Window.MODE_WINDOWED)
			Center_Window()
		elif display_mode == 1:
			get_window().set_mode(Window.MODE_FULLSCREEN)
		elif display_mode == 2:
			get_window().set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
		else:
			get_window().set_mode(Window.MODE_WINDOWED)
			Center_Window()
		
		ConfigFileHandler.save_setting("video", "display_mode", display_mode)
	if different_settings.has("resolution"):
		if (Resolutions[resolution].x >= DisplayServer.screen_get_size().x || Resolutions[resolution].y >= DisplayServer.screen_get_size().y):
			get_window().set_size(DisplayServer.screen_get_size())
		else:
			get_window().set_size(Resolutions[resolution])
		
		ConfigFileHandler.save_setting("video", "resolution", resolution)
	if different_settings.has("upscaler"):
		var Resolution_Scale = upscaler/100.00
		get_viewport().set_scaling_3d_scale(Resolution_Scale)
		
		ConfigFileHandler.save_setting("video", "upscaler", upscaler)
	if different_settings.has("vsync"):
		if vsync == true:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		ConfigFileHandler.save_setting("video", "vsync", vsync)
	if different_settings.has("screen_select"):
		var _window = get_window()
		var _cached_mode = _window.get_mode()
		_window.set_mode(Window.MODE_WINDOWED)
		_window.set_current_screen(screen_select)
		
		if _cached_mode == Window.MODE_FULLSCREEN:
			_window.set_mode(Window.MODE_FULLSCREEN)
		elif _cached_mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			_window.set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
		
		ConfigFileHandler.save_setting("video", "screen_select", screen_select)
	if different_settings.has("shadow_quality"):
		if shadow_quality == 0:
			RenderingServer.directional_shadow_atlas_set_size(512, true)
		elif shadow_quality == 1:
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		elif shadow_quality == 2:
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
		else:
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		
		ConfigFileHandler.save_setting("video", "shadow_quality", shadow_quality)
	if different_settings.has("shadow_filter"):
		if shadow_filter == 0:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
		elif shadow_filter == 1:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
		elif shadow_filter == 2:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
		else:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
		
		ConfigFileHandler.save_setting("video", "shadow_filter", shadow_filter)
	if different_settings.has("ssil_quality"):
		if ssil_quality == 0:
			ProjectSettings.set("rendering/environment/ssil/quality", 0)
		elif ssil_quality == 1:
			ProjectSettings.set("rendering/environment/ssil/quality", 2)
		elif ssil_quality == 2:
			ProjectSettings.set("rendering/environment/ssil/quality", 3)
		else:
			ProjectSettings.set("rendering/environment/ssil/quality", 2)
		ProjectSettings.save()
		
		ConfigFileHandler.save_setting("video", "ssil_quality", ssil_quality)
	if different_settings.has("ssao_quality"):
		if ssao_quality == 0:
			ProjectSettings.set("rendering/environment/ssao/quality", 0)
		elif ssao_quality == 1:
			ProjectSettings.set("rendering/environment/ssao/quality", 2)
		elif ssao_quality == 2:
			ProjectSettings.set("rendering/environment/ssao/quality", 3)
		else:
			ProjectSettings.set("rendering/environment/ssao/quality", 2)
		ProjectSettings.save()
		
		ConfigFileHandler.save_setting("video", "ssao_quality", ssao_quality)
	if different_settings.has("outline"):
		if Global.POSTP_OUTLINE_ON != outline:
			Global.POSTP_OUTLINE_ON = outline
		
		ConfigFileHandler.save_setting("video", "outline", outline)
	if different_settings.has("mouse_sensitivity"):
		if Global.MOUSE_SENSITIVITY != mouse_sensitivity:
			Global.MOUSE_SENSITIVITY = mouse_sensitivity
		
		ConfigFileHandler.save_setting("controls", "mouse_sensitivity", mouse_sensitivity)
	if different_settings.has("master_audio"):
		AudioServer.set_bus_volume_db(0, Convert_Percentage_To_Decibel(master_audio))
		
		ConfigFileHandler.save_setting("audio", "master_audio", master_audio)
	if different_settings.has("music_audio"):
		AudioServer.set_bus_volume_db(1, Convert_Percentage_To_Decibel(music_audio))
		
		ConfigFileHandler.save_setting("audio", "music_audio", music_audio)
	if different_settings.has("sfx_audio"):
		AudioServer.set_bus_volume_db(2, Convert_Percentage_To_Decibel(sfx_audio))
		
		ConfigFileHandler.save_setting("audio", "sfx_audio", sfx_audio)
	if different_settings.has("ambience_audio"):
		AudioServer.set_bus_volume_db(3, Convert_Percentage_To_Decibel(ambience_audio))
		
		ConfigFileHandler.save_setting("audio", "ambience_audio", ambience_audio)
	
	
	fps_controller.settings_applied()
	initialize_settings()
	apply_button.disabled = true

func Convert_Percentage_To_Decibel(percentage : float):
	var scale : float = 20.0
	var divisor : float = 50.0
	
	return scale * (log(percentage / divisor) / log(10))

func Center_Window():
	var Center_Screen = DisplayServer.screen_get_position()+DisplayServer.screen_get_size()/2
	var Window_Size = get_window().get_size_with_decorations()
	get_window().set_position(Center_Screen-Window_Size/2)

func _on_fov_slider_value_changed(value: float) -> void:
	fov = value

func _on_celsius_button_up() -> void:
	temperature_unit = 0

func _on_fahrenheit_button_up() -> void:
	temperature_unit = 1

func _on_windowed_button_up() -> void:
	display_mode = 0

func _on_borderless_button_up() -> void:
	display_mode = 1

func _on_fullscreen_button_up() -> void:
	display_mode = 2

func _on_resolution_option_button_item_selected(index: int) -> void:
	resolution = resolution_option_button.get_item_text(index)

func _on_scale_slider_value_changed(value: float) -> void:
	upscaler = value

func _on_vsync_checkbox_toggled(toggled_on: bool) -> void:
	vsync = toggled_on

func _on_screen_selector_item_selected(index: int) -> void:
	screen_select = index

func _on_low_quality_shadow_button_up() -> void:
	shadow_quality = 0

func _on_high_quality_shadow_button_up() -> void:
	shadow_quality = 1

func _on_ultra_quality_shadow_button_up() -> void:
	shadow_quality = 2

func _on_hard_filter_shadow_button_up() -> void:
	shadow_filter = 0

func _on_soft_filter_shadow_button_up() -> void:
	shadow_filter = 1

func _on_soft_ultra_f_ilter_shadow_button_up() -> void:
	shadow_filter = 2

func _on_low_quality_ssil_button_up() -> void:
	ssil_quality = 0

func _on_high_quality_ssil_button_up() -> void:
	ssil_quality = 1

func _on_ultra_quality_ssil_button_up() -> void:
	ssil_quality = 2

func _on_low_quality_ssao_button_up() -> void:
	ssao_quality = 0

func _on_high_quality_ssao_button_up() -> void:
	ssao_quality = 1

func _on_ultra_quality_ssao_button_up() -> void:
	ssao_quality = 2

func _on_outline_checkbox_toggled(toggled_on: bool) -> void:
	outline = toggled_on

func _on_sens_slider_value_changed(value: float) -> void:
	mouse_sensitivity = value

func _on_fps_checkbox_toggled(toggled_on):
	display_fps = toggled_on

func _on_master_slider_value_changed(value: float) -> void:
	master_audio = value

func _on_music_slider_value_changed(value: float) -> void:
	music_audio = value

func _on_sfx_slider_value_changed(value: float) -> void:
	sfx_audio = value

func _on_ambience_slider_value_changed(value: float) -> void:
	ambience_audio = value
