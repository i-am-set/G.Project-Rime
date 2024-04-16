extends Control

@onready var sub_viewport = $SubViewport
@onready var mesh_container = $SubViewport/MeshContainer
@onready var texture_rect = $TextureRect

var subinventory : Control
var held_item_preview : Control
var mouse_is_over = false
var max_scale : float = 1.25
var old_cells : Array[Vector2]
var new_cells : Array[Vector2]
var tooltip_timer: Timer

var inv_item : InventoryItem : set = set_inv_item
func set_inv_item(value):
	inv_item = value
	if inv_item != null:
		update_item_size()


func _ready():
	define_tooltip_timer()
	sub_viewport.own_world_3d = true
	Global.inv_cell_size_updated.connect(update_item_size)

func _process(delta):
	subinventory = get_parent()
	held_item_preview = subinventory.held_item_preview

func _physics_process(delta):
	hover_item()

func update_item_size():
	size = Vector2(inv_item.item_width, inv_item.item_height) * Global.INV_CELL_SIZE

func update_item_mesh():
	mesh_container.mesh = inv_item.item_mesh.instantiate()

func hover_item():
	if mouse_is_over:
		if texture_rect.texture != null:
			texture_rect.scale = Vector2(max_scale, max_scale)
	else:
		if texture_rect.texture != null:
			texture_rect.scale = Vector2(1, 1)
	#if mouse_is_over:
		#if mesh_container.mesh != null:
			#sub_viewport.render_target_update_mode = 2
			#time_passed += delta
			#var new_scale = lerp(min_scale, max_scale, (sin(time_passed * 2.5) + 1))
			#mesh_container.scale = Vector3(new_scale, new_scale, new_scale)
	#else:
		#if mesh_container.mesh != null:
			#sub_viewport.render_target_update_mode = 1
			#mesh_container.scale = Vector3(1, 1, 1)

func define_tooltip_timer():
	tooltip_timer = Timer.new()
	add_child(tooltip_timer)
	tooltip_timer.wait_time = 0.5
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(DisplayTooltip)

func DisplayTooltip():
	subinventory.inventory.DisplayTooltip()

func _on_mouse_entered():
	subinventory.inventory.HideTooltip()
	tooltip_timer.start()
	mesh_container.scale = Vector3(max_scale, max_scale, max_scale)
	mouse_is_over = true

func _on_mouse_exited():
	tooltip_timer.stop()
	subinventory.inventory.HideTooltip()
	mouse_is_over = false
