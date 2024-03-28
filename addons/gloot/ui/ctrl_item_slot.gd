@tool
@icon("res://addons/gloot/images/icon_ctrl_item_slot.svg")
class_name CtrlItemSlot
extends Control

const CtrlInventoryRect = preload("res://addons/gloot/ui/ctrl_inventory_item_rect.gd")
const CtrlDropZone = preload("res://addons/gloot/ui/ctrl_drop_zone.gd")
const CtrlDragable = preload("res://addons/gloot/ui/ctrl_dragable.gd")


@export var item_slot_path: NodePath :
    set(new_item_slot_path):
        if item_slot_path == new_item_slot_path:
            return
        item_slot_path = new_item_slot_path
        var node: Node = get_node_or_null(item_slot_path)
        
        if node == null:
            _clear()
            return

        if is_inside_tree():
            assert(node is ItemSlotBase)
            
        item_slot = node
        _refresh()
        update_configuration_warnings()
@export var default_item_icon: Texture2D :
    set(new_default_item_icon):
        if default_item_icon == new_default_item_icon:
            return
        default_item_icon = new_default_item_icon
        _refresh()
@export var item_texture_visible: bool = true :
    set(new_item_texture_visible):
        if item_texture_visible == new_item_texture_visible:
            return
        item_texture_visible = new_item_texture_visible
        if is_instance_valid(_ctrl_inventory_item_rect):
            _ctrl_inventory_item_rect.visible = item_texture_visible
@export var label_visible: bool = true :
    set(new_label_visible):
        if label_visible == new_label_visible:
            return
        label_visible = new_label_visible
        if is_instance_valid(_label):
            _label.visible = label_visible
@export_group("Icon Behavior", "icon_")
@export var icon_stretch_mode: TextureRect.StretchMode = TextureRect.StretchMode.STRETCH_KEEP_CENTERED :
    set(new_icon_stretch_mode):
        if icon_stretch_mode == new_icon_stretch_mode:
            return
        icon_stretch_mode = new_icon_stretch_mode
        if is_instance_valid(_ctrl_inventory_item_rect):
            _ctrl_inventory_item_rect.stretch_mode = icon_stretch_mode
@export_group("Text Behavior", "label_")
@export var label_horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER :
    set(new_label_horizontal_alignment):
        if label_horizontal_alignment == new_label_horizontal_alignment:
            return
        label_horizontal_alignment = new_label_horizontal_alignment
        if is_instance_valid(_label):
            _label.horizontal_alignment = label_horizontal_alignment
@export var label_vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER :
    set(new_label_vertical_alignment):
        if label_vertical_alignment == new_label_vertical_alignment:
            return
        label_vertical_alignment = new_label_vertical_alignment
        if is_instance_valid(_label):
            _label.vertical_alignment = label_vertical_alignment
@export var label_text_overrun_behavior: TextServer.OverrunBehavior :
    set(new_label_text_overrun_behavior):
        if label_text_overrun_behavior == new_label_text_overrun_behavior:
            return
        label_text_overrun_behavior = new_label_text_overrun_behavior
        if is_instance_valid(_label):
            _label.text_overrun_behavior = label_text_overrun_behavior
@export var label_clip_text: bool :
    set(new_label_clip_text):
        if label_clip_text == new_label_clip_text:
            return
        label_clip_text = new_label_clip_text
        if is_instance_valid(_label):
            _label.clip_text = label_clip_text
var item_slot: ItemSlotBase :
    set(new_item_slot):
        if new_item_slot == item_slot:
            return

        _disconnect_item_slot_signals()
        item_slot = new_item_slot
        _connect_item_slot_signals()
        
        _refresh()
var _hbox_container: HBoxContainer
var _ctrl_inventory_item_rect: CtrlInventoryRect
var _label: Label
var _ctrl_drop_zone: CtrlDropZone


func _get_configuration_warnings() -> PackedStringArray:
    if item_slot_path.is_empty():
        return PackedStringArray([
            "This node is not linked to an item slot, so it can't display any content.\n" + \
            "Set the item_slot_path property to point to an ItemSlotBase node."])
    return PackedStringArray()


func _connect_item_slot_signals() -> void:
    if !is_instance_valid(item_slot):
        return

    if !item_slot.item_equipped.is_connected(_refresh):
        item_slot.item_equipped.connect(_refresh)
    if !item_slot.cleared.is_connected(_refresh):
        item_slot.cleared.connect(_refresh)


func _disconnect_item_slot_signals() -> void:
    if !is_instance_valid(item_slot):
        return

    if item_slot.item_equipped.is_connected(_refresh):
        item_slot.item_equipped.disconnect(_refresh)
    if item_slot.cleared.is_connected(_refresh):
        item_slot.cleared.disconnect(_refresh)


func _ready():
    if Engine.is_editor_hint():
        # Clean up, in case it is duplicated in the editor
        if is_instance_valid(_hbox_container):
            _hbox_container.queue_free()

    var node: Node = get_node_or_null(item_slot_path)
    if is_inside_tree() && node:
        assert(node is ItemSlotBase)
    item_slot = node

    _hbox_container = HBoxContainer.new()
    _hbox_container.size_flags_horizontal = SIZE_EXPAND_FILL
    _hbox_container.size_flags_vertical = SIZE_EXPAND_FILL
    add_child(_hbox_container)
    _hbox_container.resized.connect(func(): size = _hbox_container.size)

    _ctrl_inventory_item_rect = CtrlInventoryRect.new()
    _ctrl_inventory_item_rect.visible = item_texture_visible
    _ctrl_inventory_item_rect.size_flags_horizontal = SIZE_EXPAND_FILL
    _ctrl_inventory_item_rect.size_flags_vertical = SIZE_EXPAND_FILL
    _ctrl_inventory_item_rect.item_slot = item_slot
    _ctrl_inventory_item_rect.stretch_mode = icon_stretch_mode
    _hbox_container.add_child(_ctrl_inventory_item_rect)

    _ctrl_drop_zone = CtrlDropZone.new()
    _ctrl_drop_zone.dragable_dropped.connect(_on_dragable_dropped)
    _ctrl_drop_zone.size = size
    resized.connect(func(): _ctrl_drop_zone.size = size)
    CtrlDragable.dragable_grabbed.connect(_on_any_dragable_grabbed)
    CtrlDragable.dragable_dropped.connect(_on_any_dragable_dropped)
    add_child(_ctrl_drop_zone)
    _ctrl_drop_zone.deactivate()

    _label = Label.new()
    _label.visible = label_visible
    _label.size_flags_horizontal = SIZE_EXPAND_FILL
    _label.size_flags_vertical = SIZE_EXPAND_FILL
    _label.horizontal_alignment = label_horizontal_alignment
    _label.vertical_alignment = label_vertical_alignment
    _label.text_overrun_behavior = label_text_overrun_behavior
    _label.clip_text = label_clip_text
    _hbox_container.add_child(_label)

    _hbox_container.size = size
    resized.connect(func():
        _hbox_container.size = size
    )

    _refresh()


func _on_dragable_dropped(dragable: CtrlDragable, drop_position: Vector2) -> void:
    var item = (dragable as CtrlInventoryItemRect).item

    if !item:
        return
    if !is_instance_valid(item_slot):
        return
        
    if !item_slot.can_hold_item(item):
        return

    if item == item_slot.get_item():
        return

    item_slot.equip(item)


func _on_any_dragable_grabbed(dragable: CtrlDragable, grab_position: Vector2):
    _ctrl_drop_zone.activate()


func _on_any_dragable_dropped(dragable: CtrlDragable, zone: CtrlDropZone, drop_position: Vector2):
    _ctrl_drop_zone.deactivate()


func _refresh() -> void:
    _clear()

    if !is_instance_valid(item_slot):
        return
    
    if item_slot.get_item() == null:
        return

    var item = item_slot.get_item()
    if is_instance_valid(_label):
        _label.text = item.get_property(CtrlInventory.KEY_NAME, item.prototype_id)
    if is_instance_valid(_ctrl_inventory_item_rect):
        _ctrl_inventory_item_rect.item = item
        if item.get_texture():
            _ctrl_inventory_item_rect.texture = item.get_texture()


func _clear() -> void:
    if is_instance_valid(_label):
        _label.text = ""
    if is_instance_valid(_ctrl_inventory_item_rect):
        _ctrl_inventory_item_rect.item = null
        _ctrl_inventory_item_rect.texture = default_item_icon

