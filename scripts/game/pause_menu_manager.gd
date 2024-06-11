extends Control

@onready var fps_controller: Player = $"../.."
@onready var landing_page: Control = $LANDING_PAGE
@onready var settings_page: Control = $SETTINGS_PAGE
@onready var are_you_sure_prompt: Panel = $Are_you_sure_prompt

func hide_all_pages():
	landing_page.visible = false
	settings_page.visible = false
	are_you_sure_prompt.visible = false

func pressed_resume():
	hide_all_pages()
	landing_page.visible = true
	fps_controller.toggle_pause_menu()

func pressed_settings():
	settings_page.intialize_settings()
	hide_all_pages()
	settings_page.visible = true

func pressed_back():
	hide_all_pages()
	landing_page.visible = true

func pressed_quit():
	are_you_sure_prompt.visible = true

func cancel_quit():
	are_you_sure_prompt.visible = false

func confirm_quit():
	get_tree().quit()
