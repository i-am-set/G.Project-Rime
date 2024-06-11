extends Control

@onready var fps_controller: Player = $"../.."
@onready var landing_page: Control = $LANDING_PAGE
@onready var options_page: Control = $OPTIONS_PAGE
@onready var are_you_sure_prompt: VBoxContainer = $LANDING_PAGE/HBoxContainer/VBoxContainer/QuitButton/Are_you_sure_prompt

func hide_all_pages():
	landing_page.visible = false
	options_page.visible = false
	are_you_sure_prompt.visible = false

func pressed_resume():
	hide_all_pages()
	landing_page.visible = true
	fps_controller.toggle_pause_menu()

func pressed_quit():
	are_you_sure_prompt.visible = true

func cancel_quit():
	are_you_sure_prompt.visible = false

func confirm_quit():
	get_tree().quit()
