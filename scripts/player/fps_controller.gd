class_name Player

extends CharacterBody3D

@onready var player_data: PlayerData = $PlayerData
@onready var player_model = $CollisionShape3D/player_model
@onready var player_model_instance: MeshInstance3D = $CollisionShape3D/player_model/male_player_model_01/Armature/Skeleton3D/Cube
@onready var arms_model: Node3D = $CameraController/Camera3D/ArmsModel
@onready var arms_animation_player: AnimationPlayer = $CameraController/Camera3D/ArmsModel/male_arm_model/AnimationPlayer
@onready var animation_player: AnimationPlayer = $CollisionShape3D/player_model/male_player_model_01/AnimationPlayer
@onready var player_animation_tree: AnimationTree = $CollisionShape3D/player_model/AnimationTree
@onready var pause_menu = $UserInterface/PauseMenu
@onready var pause_animator = $UserInterface/PauseMenu/BlurAnimator
@onready var inventory_menu = $UserInterface/InventoryMenu
@onready var POSTP_DITHER = $PostProcessingDither
@onready var POSTP_OUTLINE = $PostProcessingOutline
@onready var world = $"../.."
@onready var drop_position = $CameraController/Camera3D/DropPosition
@onready var look_at_ray_cast = $CameraController/Camera3D/LookAtRayCast
@onready var tooltips: Control = $UserInterface/Hud/Tooltips
@onready var waila_label: Label = $UserInterface/Hud/Tooltips/WAILALabel
@onready var waila_interact_label: Label = $UserInterface/Hud/ScrollableInteractMenu/WAILAInteractLabel
@onready var interact_label: Label = $UserInterface/Hud/Tooltips/TooltipVbox/InteractLabel
@onready var pick_up_label: Label = $UserInterface/Hud/Tooltips/TooltipVbox/PickUpLabel
@onready var debug_panel: PanelContainer = $UserInterface/Debug/DebugPanel
@onready var sound_manager: Node = $SoundManager
@onready var third_person_camera: Camera3D = $CameraController/ThirdPersonCamera
@onready var front_third_person_camera: Camera3D = $CameraController/FrontThirdPersonCamera
@onready var busy_progress_circle: TextureProgressBar = $UserInterface/Hud/BusyProgressCircle
@onready var scrollable_interact_menu: Control = $UserInterface/Hud/ScrollableInteractMenu
@onready var interact_pointer: Node3D = $InteractPointer

@export var MOUSE_SENSITIVITY : float = 1
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var ANIMATIONPLAYER : AnimationPlayer
@export var CROUCH_SHAPECAST : ShapeCast3D
@export var PLAYERSTATEMACHINE : StateMachine
@export var WEAPON_CONTROLLER : WeaponController
@export var USERINTERFACE : Control
@export var WEAPONVIEWPORT : SubViewportContainer

var _is_authorized_user : bool = false

var _mouse_input : bool = false
var look_dir: Vector2 # Input direction for look/aim
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _camera_rotation : Vector3
var _cached_position : Vector3
var _cached_rotation : Vector3 
var _steam_ID : int
var _resource_spawn_radius : int
var _forward_speed : float
var _strafe_speed : float
var _head_movement : float
var _crouch_speed_mod : float
var _is_crouching : bool = false
var _is_busy : bool = false
var _current_rotation : float
var look_at_collider :
	get:
		return look_at_collider
	set(value):
		if value == null:
			scrollable_interact_menu.close_interact_menu()
		look_at_collider = value

# state variables
var is_sprinting : bool = false

# Get the gravity from the project s ettings to be synced with RigidBody nodes.
var gravity = 9.8
var mass = 82

func _authorize_user():
	_is_authorized_user = true
	player_model = get_node("CollisionShape3D/player_model")
	player_model_instance = get_node("CollisionShape3D/player_model/male_player_model_01/Armature/Skeleton3D/Cube")
	arms_model = get_node("CameraController/Camera3D/ArmsModel")
	CAMERA_CONTROLLER.current = true
	show_player_model_instance(false)

func _deauthorize_user():
	_is_authorized_user = false
	player_model = get_node("CollisionShape3D/player_model")
	player_model_instance = get_node("CollisionShape3D/player_model/male_player_model_01/Armature/Skeleton3D/Cube")
	arms_model = get_node("CameraController/Camera3D/ArmsModel")
	show_player_model_instance(true)

func show_player_model_instance(toggle : bool):
	if toggle:
		player_model_instance.cast_shadow = 1
		arms_model.visible = false
	else:
		player_model_instance.cast_shadow = 3
		arms_model.visible = true

func strip_into_peer():
	remove_child(CAMERA_CONTROLLER)
	CAMERA_CONTROLLER.queue_free()
	remove_child(ANIMATIONPLAYER)
	ANIMATIONPLAYER.queue_free()
	remove_child(CROUCH_SHAPECAST)
	CROUCH_SHAPECAST.queue_free()
	remove_child(USERINTERFACE)
	USERINTERFACE.queue_free()
	remove_child(WEAPONVIEWPORT)
	WEAPONVIEWPORT.queue_free()
	remove_child(PLAYERSTATEMACHINE)
	PLAYERSTATEMACHINE.queue_free()
	var PLAYER_DATA: Node = $PlayerData
	remove_child(PLAYER_DATA)
	PLAYER_DATA.queue_free()
	var AMBIENT_SOUNDS: Node = $SoundManager/AmbientSounds
	remove_child(AMBIENT_SOUNDS)
	AMBIENT_SOUNDS.queue_free()

func _input(event):
	if _is_authorized_user == true:
		if event.is_action_pressed("ui_scroll_up"):
			if Global.IS_IN_CONSOLE:
				return
			if !is_interacting():
				try_open_interact_menu()
			if !is_interacting():
				inventory_menu.select_previous_slot()
			else:
				scrollable_interact_menu.previous_menu_option()
			print_debug("scroll up")
		if event.is_action_pressed("ui_scroll_down"):
			if Global.IS_IN_CONSOLE:
				return
			if !is_interacting():
				try_open_interact_menu()
			if !is_interacting():
				inventory_menu.select_next_slot()
			else:
				scrollable_interact_menu.next_menu_option()
			print_debug("scroll down")
		
		looking_process()
		
		if event.is_action_pressed("pick_up"):
			if look_at_collider != null:
				if "interaction_component" in look_at_collider:
					var look_at_collider_interaction_component = look_at_collider.interaction_component
					if look_at_collider_interaction_component.is_pickable:
						pick_up_to_inventory()
		
		if event.is_action_pressed("interact"):
			if is_interacting():
				if scrollable_interact_menu.menu_options.size() > 0:
					var _cached_id : String = scrollable_interact_menu.menu_options[scrollable_interact_menu.current_selection]["id"]
					var _cached_imbedded_data : String = scrollable_interact_menu.menu_options[scrollable_interact_menu.current_selection]["imbedded_data"]
					run_interact_method_by_id(_cached_id, _cached_imbedded_data)
					if _cached_id.begins_with("open"):
						return
				scrollable_interact_menu.close_interact_menu()
			else:
				try_open_interact_menu()
		
		if event.is_action_pressed("exit"):
			if Global.IS_IN_CONSOLE || is_interacting():
				pass
			else:
				toggle_pause_menu()
		if (event.is_action_pressed("left_mouse_click") || event.is_action_pressed("right_mouse_click") || event.is_action_pressed("exit")) && is_interacting():
			scrollable_interact_menu.close_interact_menu()

func _unhandled_input(event: InputEvent) -> void:
	if _is_authorized_user == true:
		if event.is_action_pressed("mouse_click") && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE:
			capture_mouse()
		
		if event is InputEventMouseMotion && Global.MOUSE_CAPTURED == true && !is_interacting():
			look_dir = event.relative * 0.001
			_rotate_camera()
			send_p2p_packet(0, {"message": "move", "steam_id": _steam_ID, "player_rotation": rotation, "player_head_animation_value": _head_movement})

func toggle_pause_menu():
	pause_menu.visible = !pause_menu.visible
	
	if pause_menu.visible:
		uncapture_mouse()
		Global.IS_PAUSED = true
		pause_animator.play("start_pause")
	else:
		capture_mouse()
		Global.IS_PAUSED = false
		pause_animator.play("RESET")
	
	pause_menu.pressed_back()

func capture_mouse():
	Global.capture_mouse(true)

func uncapture_mouse():
	Global.capture_mouse(false)

func _rotate_camera(sens_mod: float = 1.0) -> void:
	if Global.IS_PAUSED || Global.IS_IN_CONSOLE:
		return
	
	self.rotation.y -= look_dir.x * MOUSE_SENSITIVITY
	CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x - look_dir.y * MOUSE_SENSITIVITY, -1.5, 1.5)
	player_animation_tree.set("parameters/looking_blend/blend_amount", head_movement_logic(CAMERA_CONTROLLER.rotation.x))

func head_movement_logic(input : float):
	var output = 0.0
	if input < 0:
		output = lerp(0.4, 0.0, -input)
		#arms_model.position.z = lerp(-0.14, 0.22, -input)
		#arms_model.position.y = 1.02
	else:
		output = lerp(0.4, 1.0, input)
		#arms_model.position.z = lerp(-0.14, -0.415, input)
		#arms_model.position.y = lerp(1.02, 1.4, input)
	_head_movement = output
	return output

func crouch_toggle(toggle : bool):
	if toggle:
		player_animation_tree.set("parameters/IsCrouching/blend_amount", 1)
		_is_crouching = true
		send_p2p_packet(0, {"message": "move", "steam_id": _steam_ID, "player_crouch_animation_value": 1})
	else:
		player_animation_tree.set("parameters/IsCrouching/blend_amount", 0)
		_is_crouching = false
		send_p2p_packet(0, {"message": "move", "steam_id": _steam_ID, "player_crouch_animation_value": 0})

func _ready():
	if _is_authorized_user == true:
		capture_mouse()
		
		set_settings()
		
		Global.player = self
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		POSTP_DITHER.visible = true
		POSTP_OUTLINE.visible = true
		
		_steam_ID = Steam.getSteamID()
		
		CROUCH_SHAPECAST.add_exception($".")
		
		if CAMERA_CONTROLLER != null:
			set_fov()
		enable_postp_dither(Global.POSTP_DITHER_ON)
		enable_postp_dither(Global.POSTP_OUTLINE_ON)
		
		set_sensitivity()
		
		# Set console commands
		Console.create_command("no_clip", self.c_set_no_clip, "Toggles no_clip for self.")
		Console.create_command("seed", self.c_get_world_seed, "Gets the world seed")
		Console.create_command("get_self_position", self.c_get_current_position_self, "Gets the current position of self.")
		Console.create_command("get_player_position", self.c_get_current_position_peer, "Gets the current position of the specified player.")
		Console.create_command("tpc", self.c_teleport_self_to_coordinate, "Teleports your player to the given world coordinate by x, y, z vectors.")
		Console.create_command("tp_to", self.c_teleport_self_to_player, "Teleports your player to the specified player by name.")
		Console.create_command("tp", self.c_teleport_player_to_player, "Teleports the first specified player to the second specified player by name.")
		Console.create_command("fov", self.c_set_fov, "Sets the FOV of the camera. " + str(Global.MIN_FOV) + " is minimum; " + str(Global.MAX_FOV) + " is maximum; " + str(Global.DEFAULT_FOV) + " is default")
		Console.create_command("postp_enable_dither", self.c_enable_postp_dither, "Toggles the dithering post process effect. Takes a true or false.")
		Console.create_command("postp_set_color_depth", self.c_set_postp_color_depth, "Sets the color depth post process effect. 1 is minimum; 8 is maximum; 4 is default.")
		Console.create_command("postp_enable_outline", self.c_enable_postp_outline, "Toggles the outline post process effect. Takes a true or false.")
		Console.create_command("full_heal", self.c_full_heal_self, "Fully heals all parameters of self. Health, hunger, temperature, stamina.")
		Console.create_command("kill", self.c_kill_self, "Kills self.")
		Console.create_command("heal", self.c_heal_self, "Heals the player by the given amount.")
		Console.create_command("damage", self.c_damage_self, "Damages the player by the given amount.")
		Console.create_command("set_hunger", self.c_set_hunger, "Sets the players hunger. " + str(player_data.min_hunger) + " is minimum; " + str(player_data.max_hunger) + " is maximum")
		Console.create_command("get_hunger", self.c_get_hunger, "Gets the players hunger. " + str(player_data.min_hunger) + " is minimum; " + str(player_data.max_hunger) + " is maximum")
		Console.create_command("set_health", self.c_set_health, "Sets the players health. " + str(player_data.min_health) + " is minimum; " + str(player_data.max_health) + " is maximum")
		Console.create_command("get_health", self.c_get_health, "Gets the players health. " + str(player_data.min_health) + " is minimum; " + str(player_data.max_health) + " is maximum")
		#Console.create_command("set_body_temperature", self.c_set_all_player_limb_temperature, "Sets the temperature of all body parts to the given value. 100.0 is default; 0.0 is min; 200.0 is max")
		#Console.create_command("get_body_temperature", self.c_get_all_player_limb_temperature, "Displays the body temperature of each body part. 100.0 is default; 0.0 is min; 200.0 is max")
		Console.create_command("create_item", self.c_create_item_from_id, "Drops the number input of input item by ID in front of player.")
		Console.create_command("switch_pov", self.c_switch_pov, "Changes camera view to one of three views; 0 = standard/first person; 1 = third person; 2 = front facing.")

func set_settings():
	#CAMERA_CONTROLLER.far = Global.RENDER_DISTANCE*12 # opt - see if this would have even helped performance; can't use it with the skybox
	_resource_spawn_radius = (Global.RENDER_DISTANCE*24)+20

func _physics_process(delta):
	if _is_authorized_user:
		debug_process()
		
		interact_process(delta)
		
		_cached_position = global_position
		_cached_rotation = rotation
		
		if pause_menu.visible && !Global.IS_PAUSED:
			Global.IS_PAUSED = true

func update_gravity(delta) -> void:
	if (player_data.no_clip):
		pass
	else:
		var gravitational_force = gravity * mass
		var acceleration = gravitational_force / mass  # Simplifies to gravity
		velocity.y -= acceleration * delta

func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	if _is_authorized_user == true:
		if player_data.no_clip:
			if Input.is_action_pressed("sprint"):
				speed = speed * 6
			else:
				speed = speed * 3
			# Allow flying movement based on mouse direction
			var input_dir = Vector3.ZERO
			var camera_forward = Vector3.ZERO
			if (Global.MOUSE_CAPTURED == true && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE):
				input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
				camera_forward = -CAMERA_CONTROLLER.global_transform.basis.z.normalized()
				
			var direction
			if Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
				direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			else:
				direction = camera_forward * -input_dir.y
			
			if direction:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration)
				velocity.y = lerp(velocity.y, direction.y * speed, acceleration)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration)
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.y = move_toward(velocity.y, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
			
			
			# Handle vertical movement
			if Input.is_action_pressed("jump"):
				velocity.y = speed  # Move up
			elif Input.is_action_pressed("crouch"):
				velocity.y = -speed  # Move down
		else:
			var input_dir = Vector3.ZERO
			if (Global.MOUSE_CAPTURED == true && !Global.IS_PAUSED && !Global.IS_IN_CONSOLE):
				input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
			
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			
			if direction:
				velocity.x = lerp(velocity.x,direction.x * speed, acceleration)
				velocity.z = lerp(velocity.z,direction.z * speed, acceleration)
			else:
				velocity.x = move_toward(velocity.x, 0, deceleration)
				velocity.z = move_toward(velocity.z, 0, deceleration)
			
			# Calculate forward speed
			var forward_direction = -transform.basis.z
			var strafe_direction = transform.basis.x
			
			if _is_crouching:
				_forward_speed = velocity.dot(forward_direction)
				_strafe_speed = velocity.dot(strafe_direction)
				player_animation_tree.set("parameters/CrouchMovementAnimBlend/blend_position", Vector2(_strafe_speed, _forward_speed))
			else:
				_forward_speed = velocity.dot(forward_direction) / 8
				_strafe_speed = velocity.dot(strafe_direction) / 8
				player_animation_tree.set("parameters/MovementAnimBlend/blend_position", Vector2(_strafe_speed, _forward_speed))
		
		move_and_slide()
		
		if global_position != _cached_position || rotation != _cached_rotation:
			send_move_packet()

func send_move_packet():
	send_p2p_packet(0, {"message": "move", "steam_id": _steam_ID, "player_position": global_position, "player_rotation": rotation, "player_animation_value": Vector2(_strafe_speed, _forward_speed)})

func update_velocity() -> void:
	pass

func settings_applied():
	set_fov()
	set_sensitivity()
	enable_postp_outline(Global.POSTP_OUTLINE_ON)

func set_fov() -> int:
	var fov = Global.FIELD_OF_VIEW
	if fov < Global.MIN_FOV:
		fov = Global.MIN_FOV
	elif fov > Global.MAX_FOV:
		fov = Global.MAX_FOV
	
	CAMERA_CONTROLLER.fov = fov
	
	return fov

func set_sensitivity() -> float:
	var sensitivity = Global.MOUSE_SENSITIVITY
	if sensitivity < Global.MIN_SENSITIVITY:
		sensitivity = Global.MIN_SENSITIVITY
	elif sensitivity > Global.MAX_SENSITIVITY:
		sensitivity = Global.MAX_SENSITIVITY
	
	MOUSE_SENSITIVITY = sensitivity
	
	return sensitivity

func debug_process():
	if debug_panel.visible:
		Global.debug.add_property("Velocity","%.2f" % velocity.length(), 2)
		Global.debug.add_property("ShapeCast", CROUCH_SHAPECAST.is_colliding(), 2)
		Global.debug.add_property("Collision Pos", $CollisionShape3D.position , 2)
		Global.debug.add_property("Mouse Rotation", _rotation_input, 2)
		Global.debug.add_property("Heart Rate", player_data.current_heart_rate_bpm, 2)
		Global.debug.add_property("Breathe Sine", player_data.breath_sine_wave, 2)
		Global.debug.add_property("Has Exhaled", player_data.has_exhaled, 2)
		Global.debug.add_property("Body Temperature", player_data.temperature, 2)

func looking_process():
	if look_at_ray_cast.is_colliding():
		#if look_at_collider != null && look_at_collider.has_method("toggle_highlight"):
			#look_at_collider.toggle_highlight(false)
		
		var temp_look_at_ray_cast_collider = look_at_ray_cast.get_collider()
		if temp_look_at_ray_cast_collider != null:
			look_at_collider = temp_look_at_ray_cast_collider.get_parent()
			if look_at_collider != null && look_at_collider.has_user_signal("focused"):
				look_at_collider.emit_signal("focused")
				waila_label.text = get_waila_string(look_at_collider)
				interact_label.visible = true
				interact_label.text = get_interact_label()
				if "inv_item" in look_at_collider:
					if look_at_collider.inv_item != null:
						pick_up_label.visible = true
						pick_up_label.text = get_pick_up_label(look_at_collider.inv_item)
	else:
		if look_at_collider != null &&  look_at_collider.has_user_signal("unfocused"):
			look_at_collider.emit_signal("unfocused")
			look_at_collider = null
		clear_hud_labels()

func run_interact_method_by_id(_interact_method_id : String, _cached_imbedded_data : String):
	match _interact_method_id:
		"interact_close":
			pass
		"interact_pick_up":
			if look_at_collider != null:
				if "interaction_component" in look_at_collider:
					var look_at_collider_interaction_component = look_at_collider.interaction_component
					if look_at_collider_interaction_component.is_pickable:
						pick_up_to_inventory()
		"interact_combine":
			var _collider = scrollable_interact_menu.interacted_collider
			var _collider_id = scrollable_interact_menu.interacted_collider_id
			if _collider_id != "":
				if _collider_id[0] == "a":
					create_combined_items(_collider, _collider_id)
				elif _collider_id[0] == "c":
					if _collider is Combined_Items:
						add_item_to_combined_items(_collider, _collider_id)
		"interact_uncombine_all":
			var _collider = scrollable_interact_menu.interacted_collider
			var _collider_id = scrollable_interact_menu.interacted_collider_id
			if _collider_id != "":
				if _collider_id[0] == "c":
					if _collider is Combined_Items:
						_collider.uncombine_all_combined_items()
		"interact_craft":
			if _cached_imbedded_data[0] == "c":
				#craft
				pass
			else:
				printerr("Can't craft... ", _cached_imbedded_data, " not a recipe.")
		"open_craft_menu":
			waila_interact_label.text = "Craft..."
			var _collider = scrollable_interact_menu.interacted_collider
			set_sub_interact_menu_items(_collider, "open_craft_menu")
		"open_back_out_of_sub_menu":
			waila_interact_label.text = get_waila_string(look_at_collider)
			scrollable_interact_menu.back_out_of_sub_menu_options()

func get_collider_id(_look_at_collider):
	var _collider_id
	if "inv_item" in _look_at_collider: # if collider is an item
		_collider_id = _look_at_collider.inv_item.item_id
	elif "structure_id" in _look_at_collider: # if collider is a structure
		_collider_id = _look_at_collider.structure_id
	else:
		_collider_id = null
		printerr("collider_id was not set to a given id after interacting")
	
	return _collider_id

func set_interact_menu_items(_look_at_collider):
	var _collider_id = get_collider_id(_look_at_collider)
	scrollable_interact_menu.interacted_collider = _look_at_collider
	scrollable_interact_menu.interacted_collider_id = _collider_id
	
	var _menu_options : Array
	_menu_options.append(get_interact_menu_selection_dictionary("[close]", Global.COLOR_GRAY_HTML, "interact_close", "", ">"))
	if _collider_id[0] == "a" || _collider_id[0] == "c":
		if _collider_id[0] == "a":
			_menu_options.append(get_interact_menu_selection_dictionary("Take", Global.COLOR_WHITE_HTML, "interact_pick_up", "", ">"))
		if _collider_id == "c000001" || _collider_id[0] == "a":
			if inventory_menu.is_selecting_item():
				_menu_options.append(get_interact_menu_selection_dictionary("Combine", Global.COLOR_WHITE_HTML, "interact_combine", "", ">"))
			var _all_possible_recipes_ids : Array
			if _collider_id == "c000001":
				if "combined_items" in _look_at_collider:
					if _look_at_collider.combined_items.size() > 1:
						_menu_options.append(get_interact_menu_selection_dictionary("Uncombine (All)", Global.COLOR_WHITE_HTML, "interact_uncombine_all", "", ">"))
					for _item in _look_at_collider.combined_items:
						for _recipe in StaticData.recipe_data:
							if StaticData.recipe_data[_recipe].has(_item.item_id):
								_all_possible_recipes_ids.append(_recipe)
			elif _collider_id[0] == "a":
				for _recipe in StaticData.recipe_data:
					if StaticData.recipe_data[_recipe].has(_collider_id):
						_all_possible_recipes_ids.append(_recipe)
			if _all_possible_recipes_ids.size() > 0:
				_menu_options.append(get_interact_menu_selection_dictionary("Craft...", "#d2974d", "open_craft_menu", "", ">"))
	
	scrollable_interact_menu.set_menu_options(_menu_options)

func set_sub_interact_menu_items(_look_at_collider, _sub_menu_id : String):
	var _sub_menu_options : Array = []
	_sub_menu_options.append(get_interact_menu_selection_dictionary("...", Global.COLOR_WHITE_HTML, "open_back_out_of_sub_menu", "", ">"))

	if _sub_menu_id == "open_craft_menu":
		var _all_possible_recipes_ids : Array = []
		var _recipe_matches_items = true

		if "inv_item" in _look_at_collider:
			_all_possible_recipes_ids = get_possible_recipes(_look_at_collider.inv_item.item_id)
		elif "combined_items" in _look_at_collider:
			_all_possible_recipes_ids = get_possible_recipes_from_combined_items(_look_at_collider.combined_items)

		if _all_possible_recipes_ids.size() > 0:
			var _used_recipes : Array = []
			for _recipe in _all_possible_recipes_ids:
				if _used_recipes.has(_recipe):
					break
				_used_recipes.append(_recipe)
				_recipe_matches_items = check_recipe_matches(_recipe, _look_at_collider, inventory_menu.get_selected_item())

				var color = Global.COLOR_GREEN_HTML if _recipe_matches_items else Global.COLOR_RED_HTML
				_sub_menu_options.append(get_interact_menu_selection_dictionary(StaticData.recipe_data[_recipe]["recipe_output_name"], color, "interact_craft", _recipe, ">" if _recipe_matches_items else "x"))

	scrollable_interact_menu.set_sub_menu_items(_sub_menu_options)

func get_possible_recipes(_interacted_item_id):
	var _all_possible_recipes_ids : Array = []
	for _recipe in StaticData.recipe_data:
		if StaticData.recipe_data[_recipe].has(_interacted_item_id):
			_all_possible_recipes_ids.append(_recipe)
	return _all_possible_recipes_ids

func get_possible_recipes_from_combined_items(_combined_items):
	var _all_possible_recipes_ids : Array = []
	var _combined_item_dictionary = {}
	for _item in _combined_items:
		if _item.item_id in _combined_item_dictionary:
			_combined_item_dictionary[_item.item_id] += 1
		else:
			_combined_item_dictionary[_item.item_id] = 1

	for _item in _combined_items:
		for _recipe in StaticData.recipe_data:
			if StaticData.recipe_data[_recipe].has(_item.item_id):
				_all_possible_recipes_ids.append(_recipe)
	return _all_possible_recipes_ids

func check_recipe_matches(_recipe, _look_at_collider, _currently_held_item):
	var _recipe_matches_items = true
	var _recipe_component_count = 0
	var _combined_item_dictionary = {}

	if "combined_items" in _look_at_collider:
		for _combined_item in _look_at_collider.combined_items:
			if _combined_item.item_id in _combined_item_dictionary:
				_combined_item_dictionary[_combined_item.item_id] += 1
			else:
				_combined_item_dictionary[_combined_item.item_id] = 1

	for _component in _recipe:
		if _component[0] == "a":
			_recipe_component_count += _recipe[_component]
			if "inv_item" in _look_at_collider and _component == _look_at_collider.inv_item.item_id:
				if _recipe[_component] <= 1:
					continue
			elif "combined_items" in _look_at_collider and _component in _combined_item_dictionary:
				if _recipe[_component] <= _combined_item_dictionary[_component]:
					continue
			_recipe_matches_items = false

	if StaticData.recipe_data[_recipe].has("recipe_tool_requirement"):
		var _recipe_tool_requirement = StaticData.recipe_data[_recipe]["recipe_tool_requirement"]
		if _recipe_tool_requirement == 0: # hammer
			if _currently_held_item == null or StaticData.item_data[_currently_held_item.item_id]["item_hammer_value"] <= 0:
				_recipe_matches_items = false

	return _recipe_matches_items

func get_interact_menu_selection_dictionary(_title : String, _hex_code : String, _id : String, _imbedded_data : String, _selector : String) -> Dictionary:
	return {'title': _title, 'color': _hex_code, 'id': _id, 'imbedded_data': _imbedded_data, 'selector': _selector}

func create_combined_items(_collider, _collider_id : String):
	if _collider_id[0] == "a" && inventory_menu.is_selecting_item():
		world.instance_combined_item(_collider.position, StaticData.create_item_from_id(_collider_id), inventory_menu.get_selected_item())
		inventory_menu.erase_selected_item()
		_collider.queue_free()

func add_item_to_combined_items(_collider, _collider_id : String):
	_collider.add_item_to_combined_items(inventory_menu.get_selected_item())
	inventory_menu.erase_selected_item()

func get_waila_string(_look_at_collider) -> String:
	if "inv_item" in _look_at_collider: # if collider is an item
		return StaticData.item_data[_look_at_collider.inv_item.item_id]["item_name"]
	elif "structure_id" in _look_at_collider: # if collider is a structure
		return StaticData.structure_data[_look_at_collider.structure_id]["structure_name"]
	else:
		return ""

func get_interact_label() -> String:
	for actionName in InputMap.get_actions():
		if actionName == "interact":
			for inputEvent in InputMap.action_get_events(actionName):
				return "[" + inputEvent.as_text().split(" (")[0] + "] to interact"
	return "Hold [??] to interact"

func get_pick_up_label(_inv_item : InventoryItem) -> String:
	for actionName in InputMap.get_actions():
		if actionName == "pick_up":
			for inputEvent in InputMap.action_get_events(actionName):
				return "[" + inputEvent.as_text().split(" (")[0] + "] to pick up" #+ _inv_item.get_item_name()
	return "[??] to pick up" #+ _inv_item.get_item_name()

func is_interacting() -> bool:
	return scrollable_interact_menu.visible

func try_open_interact_menu():
	if look_at_collider != null:
		waila_interact_label.text = get_waila_string(look_at_collider)
		set_interact_menu_items(look_at_collider)
		scrollable_interact_menu.open_interact_menu()

func interact_process(delta):
	if is_interacting():
		tooltips.visible = false
		if look_at_collider != null:
			interact_pointer.global_position = look_at_collider.global_position
		else:
			interact_pointer.global_position = position + Vector3(0, 100000, 0)
	else:
		tooltips.visible = true
		interact_pointer.global_position = position + Vector3(0, 100000, 0)

func pick_up_to_inventory():
	#printerr(inventory_menu.has_empty_slots(look_at_collider.inv_item.item_slot_size))
	if !_is_busy && inventory_menu.has_empty_slots(look_at_collider.inv_item.item_slot_size):
		busy_progress_circle.start_busy_progress_circle_timer(0.35)
		arms_animation_player.stop()
		arms_animation_player.play("left_hand_grab")
		sound_manager.play_pickup()
		inventory_menu.pick_up_item(look_at_collider.inv_item)
		look_at_collider.queue_free()
		clear_hud_labels()
		look_at_collider = null

func clear_hud_labels():
	waila_label.text = ""
	waila_interact_label.text = ""
	interact_label.text = ""
	interact_label.visible = false
	pick_up_label.text = ""
	pick_up_label.visible = false

func interact_pick_up_to_hand():
	print_debug("item to hand")

func drop_ground_item(_item_id : String, _stack_amount : int):
	world.instance_ground_item(StaticData.create_item_from_id(_item_id), _stack_amount, drop_position.global_position, -CAMERA_CONTROLLER.get_global_transform().basis.z)

func enable_postp_dither(toggle : bool) -> void:
	POSTP_DITHER.get_surface_override_material(0).set_shader_parameter("dithering", toggle)
	Global.POSTP_DITHER_ON = toggle

func set_postp_color_depth(depth : int) -> void:
	depth = clamp(depth, 1, 8)
	POSTP_DITHER.get_surface_override_material(0).set_shader_parameter("color_depth", depth)

func enable_postp_outline(toggle : bool) -> void:
	POSTP_OUTLINE.visible = toggle
	Global.POSTP_OUTLINE_ON = toggle

func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_UNRELIABLE
	var channel: int = 0
	
	# Create a data array to send the data through
	var this_data: PackedByteArray
	
	# Compress the PackedByteArray we create from our dictionary  using the GZIP compression method
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)
	
	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if Global.LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for this_member in Global.LOBBY_MEMBERS:
				if this_member['steam_id'] != Global.STEAM_ID:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)
	
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, this_data, send_type, channel)

#func c_set_all_player_limb_temperature(temperature : float) -> void:
	#var rounded_temperature : int = temperature
	#_player_data.set_all_limb_temperature(rounded_temperature)
	#
	#Console.print_line("Set body temperature to " + str(rounded_temperature))
#
#func c_get_all_player_limb_temperature() -> void:
	#var body_temperatures: Dictionary = _player_data.get_all_limb_temperature()
	#var average_temperature : int = _player_data.get_average_limb_temperature()
	#
	#for body_part in body_temperatures.keys():
		#Console.print_line(body_part + " is at " + str(body_temperatures[body_part]))
	#Console.print_line("\n[color=GOLD]" + "Average: " + str(average_temperature) + "[/color]")

func c_get_world_seed():
	Console.print_line(str(Global.WORLD_SEED))
	Console.print_line(Steam.getLobbyData(Global.LOBBY_ID, "world_seed"))

func c_set_no_clip() -> void:
	player_data.no_clip = !player_data.no_clip
	
	if (player_data.no_clip == true):
		Console.print_line("no_clip was enabled.")
	else:
		Console.print_line("no_clip was disabled.")
	
	if get_collision_mask_value(1) == player_data.no_clip:
		set_collision_mask_value(1, !player_data.no_clip)

func c_full_heal_self() -> void:
	player_data.set_health(player_data.max_health)
	player_data.set_hunger(player_data.max_hunger)
	player_data.set_temperature(player_data.max_temperature)
	player_data.set_stamina(player_data.max_stamina)
	Console.print_line("[color=Gold]Fully healed self./color]")

func c_kill_self() -> void:
	player_data.kill()
	Console.print_line("[color=RED]Killed self.[/color]")

func c_heal_self(heal : int) -> void:
	var clamped_value = clampi(heal, 0, player_data.max_health)
	player_data.heal_player(clamped_value)
	Console.print_line("Healed self for [color=GOLD]" + str(clamped_value) + "[/color].")

func c_damage_self(damage : int) -> void:
	var clamped_value = clampi(damage, 0, player_data.max_health)
	player_data.damage_player(clamped_value)
	Console.print_line("Damaged self for [color=GOLD]" + str(clamped_value) + "[/color].")

func c_set_health(health : int) -> void:
	var clamped_value = clampi(health, player_data.min_health, player_data.max_health)
	player_data.set_health(clamped_value)
	Console.print_line("Hunger set to [color=GOLD]" + str(clamped_value) + "[/color].")

func c_get_health() -> void:
	Console.print_line("Current health is [color=GOLD]" + str(player_data.health) + "[/color].")

func c_set_hunger(hunger : int) -> void:
	var clamped_value = clampi(hunger, player_data.min_hunger, player_data.max_hunger)
	player_data.set_hunger(clamped_value)
	Console.print_line("Hunger set to [color=GOLD]" + str(clamped_value) + "[/color].")

func c_get_hunger() -> void:
	Console.print_line("Current hunger is [color=GOLD]" + str(player_data.hunger) + "[/color].")

func c_set_fov(fov : int) -> void:
	Global.FIELD_OF_VIEW = fov
	fov = set_fov()
	
	Console.print_line("Field of view set to " + str(fov) + ".")

func c_enable_postp_dither(toggle : bool) -> void:
	enable_postp_dither(toggle)
	
	Console.print_line("Post process 'dither' was toggled " + str(toggle) + ".")

func c_set_postp_color_depth(depth : int) -> void:
	set_postp_color_depth(depth)
	
	Console.print_line("Post process 'color depth' was set to " + str(depth) + ".")

func c_enable_postp_outline(toggle : bool) -> void:
	enable_postp_outline(toggle)
	
	Console.print_line("Post process 'outline' was toggled " + str(toggle) + ".")

func c_get_current_position_self() -> void:
	Console.print_line("[color=GOLD]Your current world position is " + str(position) + ".[/color]")

func c_get_current_position_peer(player_name : String) -> void:
	for player in Global.LOBBY_MEMBERS:
		if player["steam_name"] == player_name:
			var player_id = player["steam_id"]
			if Global.LOBBY_PEER_INSTANCES.has(player_id):
				Console.print_line("[color=GOLD]" + player_name + "'s current world position is " + str(Global.LOBBY_PEER_INSTANCES[player_id].position) + ".[/color]")
			return
	Console.print_line("[color=RED]'" + player_name + "' is not a valid player name.[/color]")
	

func c_teleport_self_to_coordinate(x: float, y: float, z: float) -> void:
	# Teleport self to given objects position
	if (position != null):
		position = Vector3(x, y, z)
	else:
		if (position == null):
			Console.print_line("Failed to find player position")

func c_teleport_self_to_player(des_player_name : String) -> void:
	# Teleport self to given objects position
	if (position != null):
		for player in Global.LOBBY_MEMBERS:
			if player["steam_name"] == des_player_name:
				var des_player_id = player["steam_id"]
				if Global.LOBBY_PEER_INSTANCES.has(des_player_id):
					var des_player_pos : Vector3 = Global.LOBBY_PEER_INSTANCES[des_player_id].position
					position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
					Console.print_line("Teleported to '" + des_player_name + "'.")
				elif Global.STEAM_ID == des_player_id:
					var des_player_pos : Vector3 = position
					position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
					Console.print_line("Teleported to '" + des_player_name + "' (self).")
				return
		Console.print_line("[color=RED]'" + des_player_name + "' is not a valid player name.[/color]")
	else:
		Console.print_line("[color=RED]Failed to find player position[/color]")

func c_create_item_from_id(item_to_create_id : String, number_of_item : int):
	if !StaticData.item_data.has(item_to_create_id):
		Console.print_line("[color=RED]Invalid item ID.[/color]")
		return
	
	var process_step = 0
	for i in range(number_of_item):
		process_step += 1
		if process_step % 10 == 0:
			await get_tree().process_frame
		world.instance_ground_item(StaticData.create_item_from_id(item_to_create_id), 1, drop_position.global_position, Vector3.ZERO)

func c_switch_pov(mode : int):
	if mode == 0:
		CAMERA_CONTROLLER.current = true
		show_player_model_instance(false)
	elif mode == 1:
		third_person_camera.current = true
		show_player_model_instance(true)
	elif mode == 2:
		front_third_person_camera.current = true
		show_player_model_instance(true)
	else:
		CAMERA_CONTROLLER.current = true
		show_player_model_instance(false)

func c_teleport_player_to_player(ori_player_name : String, des_player_name : String) -> void:
	var ori_is_self = false
	var des_is_self = false
	
	var ori_player_id = 0
	var des_player_id = 0
	
	var des_player_pos = Vector3.ZERO
	
	for player in Global.LOBBY_MEMBERS:
		if ori_player_id == 0:
			if player["steam_name"] == ori_player_name:
				ori_player_id = player["steam_id"]
		if des_player_id == 0:
			if player["steam_name"] == des_player_name:
				des_player_id = player["steam_id"]
	
	if Global.STEAM_ID == ori_player_id || ori_player_name == "self" || ori_player_name == "_":
		ori_is_self = true
	if Global.STEAM_ID == des_player_id || des_player_name == "self" || des_player_name == "_":
		des_is_self = true
		
	if ori_player_id == 0 && des_player_id == 0 && !ori_is_self && !des_is_self:
		Console.print_line("[color=RED]'" + ori_player_name + "and" + des_player_name + "' are not a valid player names.[/color]")
	elif ori_player_id == 0 && !ori_is_self:
		Console.print_line("[color=RED]'" + ori_player_name + "' is not a valid player name.[/color]")
	elif des_player_id == 0 && !des_is_self:
		Console.print_line("[color=RED]'" + des_player_name + "' is not a valid player name.[/color]")
	
	if Global.LOBBY_PEER_INSTANCES.has(ori_player_id) || ori_is_self:
		if ori_is_self:
			if Global.LOBBY_PEER_INSTANCES.has(des_player_id) || des_is_self:
				if des_is_self:
					des_player_pos = position
					position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
					Console.print_line("Teleported '" + Global.STEAM_NAME + "' (self) to '" + Global.STEAM_NAME + "' (self).")
					return
				
				des_player_pos = Global.LOBBY_PEER_INSTANCES[des_player_id].position
				position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
				Console.print_line("Teleported '" + Global.STEAM_NAME + "' (self) to '" + des_player_name + "'.")
		
		if Global.LOBBY_PEER_INSTANCES.has(des_player_id) || des_is_self:
			if des_is_self:
				des_player_pos = position
				Global.LOBBY_PEER_INSTANCES[ori_player_id].position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
				Console.print_line("Teleported '" + ori_player_name + "' to '" + Global.STEAM_NAME + "' (self).")
			
			des_player_pos = Global.LOBBY_PEER_INSTANCES[des_player_id].position
			Global.LOBBY_PEER_INSTANCES[ori_player_id].position = Vector3(des_player_pos.x, des_player_pos.y + 4, des_player_pos.z)
			Console.print_line("Teleported '" + ori_player_name + "' to '" + des_player_name + "'.")
