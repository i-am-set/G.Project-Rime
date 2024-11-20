extends World_Structure
class_name Combined_Items

@onready var mesh_container: Node3D = $MeshContainer
@onready var mesh_0: MeshInstance3D = $MeshContainer/Mesh0
@onready var mesh_1: MeshInstance3D = $MeshContainer/Mesh1
@onready var mesh_2: MeshInstance3D = $MeshContainer/Mesh2
@onready var mesh_3: MeshInstance3D = $MeshContainer/Mesh3
@onready var mesh_4: MeshInstance3D = $MeshContainer/Mesh4
@onready var mesh_5: MeshInstance3D = $MeshContainer/Mesh5
@onready var mesh_6: MeshInstance3D = $MeshContainer/Mesh6
@onready var mesh_7: MeshInstance3D = $MeshContainer/Mesh7
@onready var mesh_8: MeshInstance3D = $MeshContainer/Mesh8
@onready var mesh_9: MeshInstance3D = $MeshContainer/Mesh9
@onready var max_combined_items : int = mesh_container.get_children().size()

var combined_items := []

func _ready() -> void:
	structure_id = "c000001"

func create_combined_items(_ground_inv_item : InventoryItem, _held_inv_item : InventoryItem):
	add_item_to_combined_items(_ground_inv_item)
	add_item_to_combined_items(_held_inv_item)

func add_item_to_combined_items(_inv_item : InventoryItem):
	if _inv_item == null:
		printerr("inv_item was null when 'add_item_to_combined_items(_inv_item : InventoryItem)' called in 'combined_items'")
		return
	combined_items.append(_inv_item)
	
	var empty_meshes := []
	for _mesh in mesh_container.get_children():
		if _mesh is MeshInstance3D && _mesh.mesh == null:
			empty_meshes.append(_mesh)
	if empty_meshes.size() > 0:
		var _mesh_instance = empty_meshes[randi() % empty_meshes.size()]
		set_mesh_of_mesh_instance(_mesh_instance, Global.ITEM_MESHES[_inv_item.item_id])
	else:
		printerr("No meshes in combined_items '", self, "' were null")
		set_mesh_of_mesh_instance(mesh_0, Global.ITEM_MESHES[_inv_item.item_id])

func uncombine_all_combined_items():
	var _world = get_parent().get_parent()
	if !_world.has_method("instance_ground_item"):
		printerr("Doesn't have instance_ground_item()")
	
	for _item in combined_items:
		_world.instance_ground_item(_item, 1, self.position, Vector3.ZERO)
	
	combined_items.clear()
	clear_meshes_in_mech_container()
	queue_free()

func set_mesh_of_mesh_instance(_mesh_instance : MeshInstance3D, _array_mesh):
	_mesh_instance.mesh = _array_mesh

func clear_meshes_in_mech_container():
	for _mesh in mesh_container.get_children():
		if _mesh is MeshInstance3D:
			_mesh.mesh = null

