extends Control

@onready var fps_controller = $"../.."
@onready var inventory = $inventory
@onready var sound_manager: Node = $"../../SoundManager"
@onready var item_0: InvItemRect = $HBoxContainer/item_0
@onready var item_1: InvItemRect = $HBoxContainer/item_1
@onready var item_2: InvItemRect = $HBoxContainer/item_2
@onready var item_3: InvItemRect = $HBoxContainer/item_3
@onready var item_4: InvItemRect = $HBoxContainer/item_4
@onready var item_5: InvItemRect = $HBoxContainer/item_5

var selected_index := 0
var inventory_contents := []
var inventory_slots
var filler_slots := []

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_1:
			#if inventory_contents[0] != null:
			select_slot(0)
		elif event.pressed and event.keycode == KEY_2:
			#if inventory_contents[1] != null:
			select_slot(1)
		elif event.pressed and event.keycode == KEY_3:
			#if inventory_contents[2] != null:
			select_slot(2)
		elif event.pressed and event.keycode == KEY_4:
			#if inventory_contents[3] != null:
			select_slot(3)
		elif event.pressed and event.keycode == KEY_5:
			#if inventory_contents[4] != null:
			select_slot(4)
		elif event.pressed and event.keycode == KEY_6:
			#if inventory_contents[5] != null:
			select_slot(5)

func _input(event):
	if event.is_action_pressed("ui_scroll_up"):
		select_previous_slot()
	if event.is_action_pressed("ui_scroll_down"):
		select_next_slot()
	if event.is_action_pressed("drop_selected_item"):
		drop_selected_item()

func _ready():
	for i in range(6):
		inventory_contents.append(null)
		filler_slots.append(false)
	
	inventory_slots = [item_0, item_1, item_2, item_3, item_4, item_5]
	
	update_selection()

func add_item_to_inventory(added_inventory_item):
	var slot_size = added_inventory_item.item_slot_size
	for i in range(6):
		if inventory_contents[i] == null and not filler_slots[i]:
			var can_place = true
			selected_index = i
			for j in range(1, slot_size):
				if i + j >= 6 or inventory_contents[i + j] != null or filler_slots[i + j]:
					can_place = false
					break
			if can_place:
				inventory_contents[i] = added_inventory_item
				for j in range(1, slot_size):
					filler_slots[i + j] = true
				update_selection()
				break

func remove_item_in_inventory_at_index(index: int):
	if index >= 0 and index < 6:
		var slot_size = inventory_contents[index].item_slot_size if inventory_contents[index] != null else 1
		for i in range(index, 5):
			if i + slot_size < 6:
				inventory_contents[i] = inventory_contents[i + slot_size]
				filler_slots[i] = filler_slots[i + slot_size]
			else:
				inventory_contents[i] = null
				filler_slots[i] = false
		for i in range(6 - slot_size, 6):
			inventory_contents[i] = null
			filler_slots[i] = false
		update_selection()

func select_previous_slot():
	selected_index = (selected_index - 1) % 6
	while filler_slots[selected_index]:
		selected_index = (selected_index - 1) % 6
	if selected_index < 0:
		selected_index = 5
	update_selection()

func select_next_slot():
	selected_index = (selected_index + 1) % 6
	while filler_slots[selected_index]:
		selected_index = (selected_index + 1) % 6
	if selected_index > 5:
		selected_index = 0
	update_selection()

func select_slot(index: int):
	if index >= 0 and index < 6 and not filler_slots[index]:
		selected_index = index
		update_selection()
	else:
		printerr("Index is out of range or is a filler slot: ", index)

func update_selection():
	for i in range(6):
		if i == selected_index:
			inventory_slots[i].select_slot()
		else:
			inventory_slots[i].deselect_slot()
		
		if filler_slots[i]:
			inventory_slots[i].filler_slot()
		
		if inventory_contents[i] != null:
			inventory_slots[i].set_item_icon(Global.ITEM_ICONS[inventory_contents[i].item_id])
		else:
			inventory_slots[i].set_item_icon(null)

func has_empty_slots(count: int) -> bool:
	var empty_slots := 0
	for item in inventory_contents:
		if item == null:
			empty_slots += 1
	return empty_slots >= count

func pick_up_item(_picked_up_item : InventoryItem):
	add_item_to_inventory(_picked_up_item)
	print_debug(_picked_up_item.get_item_name())

func drop_selected_item():
	if inventory_contents[selected_index] == null:
		return
	fps_controller.drop_ground_item(inventory_contents[selected_index].item_id, 1)
	remove_item_in_inventory_at_index(selected_index)
	
	if inventory_contents[selected_index] == null:
		for i in range(5, -1, -1):
			if inventory_contents[i] != null:
				selected_index = i
				update_selection()
				break
