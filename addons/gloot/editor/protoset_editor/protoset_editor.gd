@tool
extends Control

const GlootUndoRedo = preload("res://addons/gloot/editor/gloot_undo_redo.gd")
const EditorIcons = preload("res://addons/gloot/editor/common/editor_icons.gd")

@onready var prototype_filter = $"%PrototypeFilter"
@onready var property_editor = $"%PropertyEditor"
@onready var txt_prototype_id = $"%TxtPrototypeName"
@onready var btn_add_prototype = $"%BtnAddPrototype"
@onready var btn_duplicate_prototype = $"%BtnDuplicatePrototype"
@onready var btn_remove_prototype = $"%BtnRemovePrototype"
@onready var btn_rename_prototype = $"%BtnRenamePrototype"

var protoset: ItemProtoset :
    set(new_protoset):
        protoset = new_protoset
        if protoset:
            protoset.changed.connect(_on_protoset_changed)
        _refresh()   
var selected_prototype_id: String = ""
        

func _ready() -> void:
    prototype_filter.choice_selected.connect(_on_prototype_selected)
    property_editor.value_changed.connect(_on_property_changed)
    property_editor.value_removed.connect(_on_property_removed)
    txt_prototype_id.text_changed.connect(_on_prototype_id_changed)
    txt_prototype_id.text_submitted.connect(_on_prototype_id_entered)
    btn_add_prototype.pressed.connect(_on_btn_add_prototype)
    btn_duplicate_prototype.pressed.connect(_on_btn_duplicate_prototype)
    btn_rename_prototype.pressed.connect(_on_btn_rename_prototype)
    btn_remove_prototype.pressed.connect(_on_btn_remove_prototype)

    btn_add_prototype.icon = EditorIcons.get_icon("Add")
    btn_duplicate_prototype.icon = EditorIcons.get_icon("Duplicate")
    btn_rename_prototype.icon = EditorIcons.get_icon("Edit")
    btn_remove_prototype.icon = EditorIcons.get_icon("Remove")
    prototype_filter.filter_icon = EditorIcons.get_icon("Search")
    _refresh()


func _refresh() -> void:
    if !visible:
        return

    _clear()
    _populate()
    _refresh_btn_add_prototype()
    _refresh_btn_rename_prototype()
    _refresh_btn_remove_prototype()
    _refresh_btn_duplicate_prototype()
    _inspect_prototype_id(selected_prototype_id)


func _clear() -> void:
    prototype_filter.values.clear()
    property_editor.dictionary.clear()
    property_editor.refresh()


func _populate() -> void:
    if protoset:
        # TODO: Avoid accessing "private" members (_prototypes)
        prototype_filter.set_values(protoset._prototypes.keys().duplicate())


func _refresh_btn_add_prototype() -> void:
    btn_add_prototype.disabled = txt_prototype_id.text.is_empty() ||\
        protoset.has_prototype(txt_prototype_id.text)


func _refresh_btn_rename_prototype() -> void:
    btn_rename_prototype.disabled = txt_prototype_id.text.is_empty() ||\
        protoset.has_prototype(txt_prototype_id.text)


func _refresh_btn_remove_prototype() -> void:
    btn_remove_prototype.disabled = prototype_filter.get_selected_text().is_empty()


func _refresh_btn_duplicate_prototype() -> void:
    btn_duplicate_prototype.disabled = prototype_filter.get_selected_text().is_empty()


func _on_protoset_changed() -> void:
    _refresh()


func _on_prototype_selected(index: int) -> void:
    selected_prototype_id = prototype_filter.values[index]
    _inspect_prototype_id(selected_prototype_id)
    _refresh_btn_remove_prototype()
    _refresh_btn_duplicate_prototype()


func _inspect_prototype_id(prototype_id: String) -> void:
    if !protoset || !protoset.has_prototype(prototype_id):
        return

    var prototype: Dictionary = protoset.get_prototype(prototype_id).duplicate()

    property_editor.dictionary = prototype
    property_editor.immutable_keys = [ItemProtoset.KEY_ID] as Array[String]
    property_editor.remove_button_map = {}

    for property_name in prototype.keys():
        property_editor.set_remove_button_config(property_name, {
            "text": "",
            "disabled": property_name == ItemProtoset.KEY_ID,
            "icon": EditorIcons.get_icon("Remove"),
        })


func _on_property_changed(property_name: String, new_value) -> void:
    if selected_prototype_id.is_empty():
        return
    var new_properties = protoset.get_prototype(selected_prototype_id).duplicate()
    new_properties[property_name] = new_value

    if new_properties.hash() == protoset.get_prototype(selected_prototype_id).hash():
        return

    GlootUndoRedo.set_prototype_properties(protoset, selected_prototype_id, new_properties)


func _on_property_removed(property_name: String) -> void:
    if selected_prototype_id.is_empty():
        return
    var new_properties = protoset.get_prototype(selected_prototype_id).duplicate()
    new_properties.erase(property_name)

    GlootUndoRedo.set_prototype_properties(protoset, selected_prototype_id, new_properties)


func _on_prototype_id_changed(_prototype_id: String) -> void:
    _refresh_btn_add_prototype()
    _refresh_btn_rename_prototype()


func _on_prototype_id_entered(prototype_id: String) -> void:
    _add_prototype_id(prototype_id)


func _on_btn_add_prototype() -> void:
    _add_prototype_id(txt_prototype_id.text)


func _on_btn_duplicate_prototype() -> void:
    GlootUndoRedo.duplicate_prototype(protoset, selected_prototype_id)


func _on_btn_rename_prototype() -> void:
    if selected_prototype_id.is_empty():
        return

    GlootUndoRedo.rename_prototype(protoset,
            selected_prototype_id,
            txt_prototype_id.text)
    txt_prototype_id.text = ""


func _add_prototype_id(prototype_id: String) -> void:
    GlootUndoRedo.add_prototype(protoset, prototype_id)
    txt_prototype_id.text = ""


func _on_btn_remove_prototype() -> void:
    if selected_prototype_id.is_empty():
        return

    var prototype_id = selected_prototype_id
    if !prototype_id.is_empty():
        GlootUndoRedo.remove_prototype(protoset, prototype_id)
