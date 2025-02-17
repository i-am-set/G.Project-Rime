extends Control

@onready var chat = $Chat
@onready var chatGetType = $Chat/ChatType
@onready var chatOutput = $Chat/ChatOutput
@onready var chatInput = $Chat/SendMessage/LineEdit
@onready var sendMessage = $Chat/SendMessage
@onready var chatHideTimer = $ChatHideTimer

var _chat_type : String = "GLOBAL"
var chat_hide_tween : Tween

func _ready():
	visible = false
	set_chat_type()

func _input(event: InputEvent) -> void:
	if Global.IS_IN_GAME:
		if Global.MOUSE_CAPTURED == true && chatInput.has_focus():
			deselect_chat_input()
		if !Global.IS_PAUSED && !Global.IS_IN_CONSOLE && Input.is_action_just_pressed("ui_text_completion_accept"):
			# stop the tween if needed and reset variable
			if chat_hide_tween != null:
				if chat_hide_tween.is_running():
					chat_hide_tween.stop()
					chat.modulate.a = 1
			# change logic based on if the chat window is open or not
			if visible == false || chatInput.has_focus() == false && Global.IS_PAUSED == false && Global.IS_IN_CONSOLE == false:
				visible = true
				select_chat_input()
				uncapture_mouse()
			else:
				send_chat_message()
		if Input.is_action_pressed("exit") || Global.IS_PAUSED == true || Global.IS_IN_CONSOLE == true:
			chatInput.clear()
			if visible == true:
				deselect_chat_input()
				visible = false
		if event.is_action_pressed("ui_scroll_up") && chatInput.has_focus() == true:
			chatOutput.scroll_vertical -= 1
		if event.is_action_pressed("ui_scroll_down") && chatInput.has_focus() == true:
			chatOutput.scroll_vertical += 1

func capture_mouse():
	Global.capture_mouse(true)

func uncapture_mouse():
	Global.capture_mouse(false)

func set_chat_type():
	deselect_chat_input()
	chatGetType.text = _chat_type

#func switch_chat_type():
	#if _chat_type == "GLOBAL":
		#_chat_type == "LOCAL"
	#elif _chat_type == "LOCAL":
		#_chat_type == "GLOBAL"
	#else:
		#_chat_type == "GLOBAL"
	#
	#chatGetType.text = _chat_type

func select_chat_input():
	chatInput.grab_focus()
	chat.modulate.a = 1

func deselect_chat_input():
	chatInput.release_focus()
	chat.modulate.a = 0.5

func display_message(message):
	if chatOutput.text == "":
		chatOutput.text += (str(message))
		return
	
	chatOutput.text += ("\n" + str(message))
	chatOutput.scroll_vertical += 1000

func _on_chat_hide_timer_timeout():
	chat_hide_tween = get_tree().create_tween()
	chat_hide_tween.tween_property(chat, "modulate:a", 0, 1)
	await chat_hide_tween.finished
	visible = false

func send_chat_message():
	# reset the timer
	chatHideTimer.stop()
	chatHideTimer.start()
	# Get chat input
	var this_message = " " + chatInput.text
	# Pass message to steam
	if this_message != "":
		var is_sent = Steam.sendLobbyChatMsg(Global.LOBBY_ID, this_message)
	# Check message sent
		if not is_sent:
			display_message("ERROR: Chat message failed to send")
	# Capture mouse
	capture_mouse()
	# Deselect the chat input
	deselect_chat_input()
	# Clear chat input
	chatInput.text = ""


func _on_send_message_pressed():
	send_chat_message()
