extends HBoxContainer

@onready var fps_controller = $"../../.."

@onready var fullscreen_button = $VBoxContainer/_Display_Mode/DisplayModes/Fullscreen
@onready var borderless_button = $VBoxContainer/_Display_Mode/DisplayModes/Borderless
@onready var windowed_button = $VBoxContainer/_Display_Mode/DisplayModes/Windowed

@onready var resolution_option_button = $VBoxContainer/_Resolution/Resolution_OptionButton

@onready var scale_box = $VBoxContainer/_Scale/Scale_Box
@onready var scalepercent_label = $VBoxContainer/_Scale/Scale_Box/PercentLabel
@onready var scale_slider = $VBoxContainer/_Scale/Scale_Box/ScaleSlider

@onready var fsr_box = $VBoxContainer/_Scale/_FSR_Quality
@onready var fsr_options = $VBoxContainer/_Scale/_FSR_Quality/FSROptions

@onready var vsync_checkbox = $VBoxContainer/_Vsync/vsync_checkbox

@onready var screen_selector = $VBoxContainer/_Screen_Select/Screen_Selector

@onready var fovpercent_label = $VBoxContainer/_FieldOfView/PercentLabel
@onready var fov_slider = $VBoxContainer/_FieldOfView/FovSlider

@onready var dithering_checkbox = $VBoxContainer/_PostP_Dither/dithering_checkbox

@onready var outline_checkbox = $VBoxContainer/_PostP_Outline/outline_checkbox


var Resolutions: Dictionary = {"3840x2160":Vector2i(3840,2160),
								"2560x1440":Vector2i(2560,1080),
								"1920x1080":Vector2i(1920,1080),
								"1600x900":Vector2i(1600,900),
								"1536x864":Vector2i(1536,864),
								"1440x900":Vector2i(1440,900),
								"1366x768":Vector2i(1366,768),
								"1280x720":Vector2i(1280,720),
								"1024x600":Vector2i(1024,600),
								"800x600": Vector2i(800,600)}
								

func _ready():
	await get_tree().process_frame
	
	Add_Resolutions()
	Check_Variables()
	Get_Screens()

func Check_Variables():
	var _window = get_window()
	var mode = _window.get_mode()
	
	fov_slider.min_value = Global.MIN_FOV
	fov_slider.max_value = Global.MAX_FOV
	_on_fov_slider_value_changed(Global.FIELD_OF_VIEW)
	
	scale_slider.set_value_no_signal(Global.RES_SCALE_PERCENT)
	_on_scale_slider_value_changed(Global.RES_SCALE_PERCENT)
	
	if mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		resolution_option_button.set_disabled(true)
		fullscreen_button.set_pressed_no_signal(true)
	elif mode == Window.MODE_FULLSCREEN:
		resolution_option_button.set_disabled(true)
		borderless_button.set_pressed_no_signal(true)
	else:
		resolution_option_button.set_disabled(false)
		windowed_button.set_pressed_no_signal(true)
		_on_windowed_button_up()
	
	vsync_checkbox.set_pressed_no_signal(Global.IS_VSYNC_ENABLED)
	_on_vsync_checkbox_toggled(Global.IS_VSYNC_ENABLED)
	
	dithering_checkbox.set_pressed_no_signal(Global.POSTP_DITHER_ON)
	_on_dithering_checkbox_toggled(Global.POSTP_DITHER_ON)
	
	outline_checkbox.set_pressed_no_signal(Global.POSTP_OUTLINE_ON)
	_on_outline_checkbox_toggled(Global.POSTP_OUTLINE_ON)

func Set_Resolution_Text():
	var Resolution_Text = str(get_window().get_size().x)+"x"+str(get_window().get_size().y)
	resolution_option_button.set_text(Resolution_Text)
	
	scale_slider.set_value_no_signal(100.00)
	_on_scale_slider_value_changed(100.00)
	
func Add_Resolutions():
	var Current_Resolution = get_window().get_size()
	print_debug(Current_Resolution)
	var ID = 0
	
	for r in Resolutions:
		resolution_option_button.add_item(r, ID)
		
		if Resolutions[r] == Current_Resolution:
			resolution_option_button.select(ID)
		
		ID += 1

func _on_resolution_option_button_item_selected(index):
	var ID = resolution_option_button.get_item_text(index)
	if (Resolutions[ID].x >= DisplayServer.screen_get_size().x || Resolutions[ID].y >= DisplayServer.screen_get_size().y):
		get_window().set_size(DisplayServer.screen_get_size())
	else:
		get_window().set_size(Resolutions[ID])
	Set_Resolution_Text()
	Center_Window()

func Center_Window():
	var Centre_Screen = DisplayServer.screen_get_position()+DisplayServer.screen_get_size()/2
	var Window_Size = get_window().get_size_with_decorations()
	get_window().set_position(Centre_Screen-Window_Size/2)

func _on_scale_slider_value_changed(value):
	Global.RES_SCALE_PERCENT = value
	
	var Resolution_Scale = value/100.00
	var Resolution_Text = str(round(get_window().get_size().x*Resolution_Scale))+"x"+str(round(get_window().get_size().y*Resolution_Scale))
	
	scalepercent_label.set_text(str(value)+"% - "+ Resolution_Text)
	get_viewport().set_scaling_3d_scale(Resolution_Scale)
	
func _on_scaler_item_selected(index):
	var _viewport = get_viewport()
	
	match index:
		0:
			_viewport.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_BILINEAR)
			scale_slider.set_value_no_signal(100.00)
			_on_scale_slider_value_changed(100)
			scale_box.show()
			fsr_box.hide()
		1:
			_viewport.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_FSR2)
			fsr_options.selected = 0
			scale_box.hide()
			fsr_box.show()
	
func _on_fsr_options_item_selected(index):
	match index:
		0:
			scale_slider.set_value_no_signal(50.00)
			_on_scale_slider_value_changed(50.00)
		1:
			scale_slider.set_value_no_signal(59.00)
			_on_scale_slider_value_changed(59.00)
		2:
			scale_slider.set_value_no_signal(67.00)
			_on_scale_slider_value_changed(67.00)
		3:
			scale_slider.set_value_no_signal(77.00)
			_on_scale_slider_value_changed(77.00)

func _on_vsync_checkbox_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		Global.IS_VSYNC_ENABLED = true
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Global.IS_VSYNC_ENABLED = false

func Get_Screens():
	var Screens = DisplayServer.get_screen_count()
	
	for s in Screens:
		screen_selector.add_item("Screen: "+str(s+1))

func _on_screen_selector_item_selected(index):
	var _window = get_window()
	
	var mode = _window.get_mode()

	_window.set_mode(Window.MODE_WINDOWED)
	_window.set_current_screen(index)
	
	if mode == Window.MODE_FULLSCREEN:
		_window.set_mode(Window.MODE_FULLSCREEN)

func _on_fullscreen_button_up():
	resolution_option_button.set_disabled(true)
	get_window().set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
	get_tree().create_timer(.05).timeout.connect(Set_Resolution_Text)

func _on_borderless_button_up():
	resolution_option_button.set_disabled(true)
	get_window().set_mode(Window.MODE_FULLSCREEN)
	get_tree().create_timer(.05).timeout.connect(Set_Resolution_Text)

func _on_windowed_button_up():
	resolution_option_button.set_disabled(false)
	get_window().set_mode(Window.MODE_WINDOWED)
	Center_Window()
	get_tree().create_timer(.05).timeout.connect(Set_Resolution_Text)

func _on_fov_slider_value_changed(value):
	fps_controller.set_fov(value)
	fovpercent_label.set_text(str(value))

func _on_dithering_checkbox_toggled(toggled_on):
	fps_controller.enable_postp_dither(toggled_on)

func _on_outline_checkbox_toggled(toggled_on):
	fps_controller.enable_postp_outline(toggled_on)

func c_set_display_mode() -> void:
	# Todo: add this logic for console
	pass
