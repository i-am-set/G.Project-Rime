@tool
extends Node3D
 # todo - see if you can get the location of all of these multimeshes so you can 'harvest' them in runtime
# opt - strip this script of everything unused; didn't fully skim it or use the collision part
var _is_initialized : bool = false
@export var player_node: Node3D
@export var instance_amount : int = 100  # Number of instances to generate
@export var generate_colliders: bool = false
@export var collider_coverage_dist : float = 50
@export var pos_randomize : float = 0  # Amount of randomization for x and z positions
@export_range(0,50) var instance_min_scale: float = 1
@export var instance_height: float = 1
@export var instance_width: float = 1
@export var instance_spacing: int = 10
@export_range(0,10) var scale_randomize : float = 0.0  # Amount of randomization for uniform scale
@export_range(0,PI) var instance_Y_rot : float = 0.0  # Amount of randomization for X rotation
@export_range(0,PI) var instance_X_rot : float = 0.0  # Amount of randomization for Y rotation 
@export_range(0,PI) var instance_Z_rot : float = 0.0  # Amount of randomization for Z rotation 
@export var rot_y_randomize : float = 0.0  # Amount of randomization for Y rotation 
@export var rot_x_randomize : float = 0.0  # Amount of randomization for X rotation 
@export var rot_z_randomize : float = 0.0  # Amount of randomization for Z rotation 
@export var instance_mesh : Mesh   # Mesh resource for each instance
@export var instance_mesh_material : Material   # Mesh material for each mesh
@export var instance_collision : Shape3D
@onready var instance_rows: int 
@onready var offset: float 
@onready var rand_x : float
@onready var rand_z : float
@onready var multi_mesh_instance
@onready var multi_mesh
var h_scale: float = 1
var v_scale: float = 1
@onready var collision_parent
@onready var colliders: Array
@onready var colliders_to_spawn: Array
@onready var last_pos: Vector3
@onready var first_update= true
 
func _ready():
	_is_initialized = false
	create_multimesh()
	
func create_multimesh():
	# Create a MultiMeshInstance3D and set its MultiMesh
	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.top_level = true
	multi_mesh_instance.cast_shadow = false
	multi_mesh_instance.material_override = instance_mesh_material
	multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = instance_amount
	multi_mesh.mesh = instance_mesh 
	instance_rows = sqrt(instance_amount) #rounded down to integer
	offset = round(instance_amount/instance_rows) #rounded up/down to nearest integer
	
	# Add the MultiMeshInstance3D as a child of the instancer
	add_child(multi_mesh_instance)
	
	_is_initialized = true
 
func _process(delta):
	#on each update, move the center to player
	if player_node != null && _is_initialized:
		self.global_position = Vector3(player_node.global_position.x,0.0,player_node.global_position.z).snapped(Vector3(1,0,1));
		multi_mesh_instance.multimesh = distribute_meshes()
 
func distribute_meshes():
	randomize()
	for i in range(instance_amount):
		# Generate positions on X and Z axes    
		var pos = global_position
		pos.z = i;
		pos.x = (int(pos.z) % instance_rows);
		pos.z = int((pos.z - pos.x) / instance_rows);
 
		#center this
		pos.x -= offset/2
		pos.z -= offset/2
 
		#apply spacing (snap to integer to keep instances in place)
		pos *= instance_spacing;
		pos.x += int(global_position.x) - (int(global_position.x) % instance_spacing);
		pos.z += int(global_position.z) - (int(global_position.z) % instance_spacing);
		
		#add randomization  
		var x
		var z
		pos.x += random(pos.x,pos.z) * pos_randomize
		pos.z += random(pos.x,pos.z) * pos_randomize
		pos.x -= pos_randomize * random(pos.x,pos.z)
		pos.z -= pos_randomize * random(pos.x,pos.z)
		
		x = pos.x 
		z = pos.z 
		
		# Sample the heightmap texture to determine the Y position
		var y = Heightmap.get_height(x, z)-0.1
 
		var ori = Vector3(x, y, z)
		var sc = Vector3(   instance_min_scale+scale_randomize * random(x,z) + instance_width,
							instance_min_scale+scale_randomize * random(x,z) + instance_height,
							instance_min_scale+scale_randomize * random(x,z)+ instance_width
							)
 
		# Randomize rotations
		var rot = Vector3(0,0,0)
		rot.x += instance_X_rot + (random(x,z) * rot_x_randomize)
		rot.y += instance_Y_rot + (random(x,z) * rot_y_randomize)
		rot.z += instance_Z_rot + (random(x,z) * rot_z_randomize)
 
		var t
		t = Transform3D()
		t.origin = ori
		
		t = t.rotated_local(t.basis.x.normalized(),rot.x)
		t = t.rotated_local(t.basis.y.normalized(),rot.y)
		t = t.rotated_local(t.basis.z.normalized(),rot.z)
 
		# Set the instance data
		multi_mesh.set_instance_transform(i, t.scaled_local(sc))
 
		#Collisions
		if generate_colliders:
			if first_update:
				if i == instance_amount-1:
					first_update = false
					generate_subset()
			else:   
				if !colliders[i] == null:
					colliders[i].global_transform = t.scaled_local(sc)  
 
	last_pos = global_position
	return multi_mesh
 
func random(x,z):
	var r = fposmod(sin(Vector2(x,z).dot(Vector2(12.9898,78.233)) * 43758.5453123),1.0)
	return r
	
func spawn_colliders():
	collision_parent = StaticBody3D.new()
	add_child(collision_parent)
	collision_parent.set_as_top_level(true)
	var c_shape = instance_collision
	
	for i in range(instance_amount):
		if colliders_to_spawn.has(i):
			var collider = CollisionShape3D.new()
			collision_parent.add_child(collider)
			collider.set_shape(instance_collision)
			colliders.append(collider)
		else:
			colliders.append(null)      
	
func generate_subset():
	for i in range(instance_amount):
		var t = multi_mesh.get_instance_transform(i)
		if t.origin.distance_squared_to(player_node.global_position) < pow(collider_coverage_dist,2):
			colliders_to_spawn.append(i)        
		if i==instance_amount-1:
			spawn_colliders()
