extends Node3D

func _ready():
	printerr("Nullified: Disable this script")
	pass

#@onready var _csharp_caller = $CSharpCaller
## opt - move this to the .cs script
##-------------------- Trees ---------------------------#
#var birch_tree = preload("res://scenes/resourceobjects/nature/trees/birch_tree_controller.tscn")
#
#var pine_tree = preload("res://scenes/resourceobjects/nature/trees/pine_tree_controller.tscn")
#
#var tall_pine_tree = preload("res://scenes/resourceobjects/nature/trees/tall_pine_tree_controller.tscn")
#
#var trees = [
	#birch_tree,
	#pine_tree,
	#tall_pine_tree
#]
#
##-------------------- Nodes ---------------------#
## todo - make stone nodes and think of other types of nodes, maybe metal of some sort if that would make sense
#var flint_node = preload("res://scenes/resourceobjects/nature/nodes/flint_node_controller.tscn")
#
#var stone_node = preload("res://scenes/resourceobjects/nature/nodes/stone_node_controller.tscn")
#
#var nodes = [
	#flint_node,
	#stone_node
#]
#
##-------------------- Shrubs ---------------------#
#var twig_shrub = preload("res://scenes/resourceobjects/nature/shrub/twig_shrub_1.tscn")
#
#var shrubs = [
	#twig_shrub
#]
#
##------------------------------------------------------#
#
#var weights : Dictionary = {
	#birch_tree : 3,
	#pine_tree : 0.5,
	#tall_pine_tree : 10,
	#stone_node : 0.2,
	#flint_node : 0.1,
	#twig_shrub : 0.1
#}
#
#var _is_initialized : bool = false
#var _total_weight : float = 0
#var _rng_base = RandomNumberGenerator.new()
#
#func _ready():
	#initiate_weight_system()
#
#func initiate_weight_system():
	#if !_is_initialized:
		#for resource in weights:
			#_total_weight += weights[resource]
		#_is_initialized = true
