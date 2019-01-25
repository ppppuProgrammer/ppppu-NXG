extends AnimationTree

const AGN_BASE_CLASS = preload("res://UI/Nodes/AnimationGraphNode.gd")

var _sub_blend_tree:AnimationNodeBlendTree
var seeker:AnimationNodeTimeSeek
func _ready():
	#Tree root is the "master" blend tree, comprised of a 
	# sub blend tree, a time seek node and the required output node.
	# Connections within it are fixed.
	tree_root = AnimationNodeBlendTree.new()
	#Sub blend tree is what users will edit
	_sub_blend_tree = AnimationNodeBlendTree.new()
	seeker = AnimationNodeTimeSeek.new()
	tree_root.add_node("Sub Blend Tree", _sub_blend_tree)
	tree_root.add_node("Time Seeker", seeker)
	#Connect the tree root's nodes
	tree_root.connect_node("Time Seeker", 0, "Sub Blend Tree")
	tree_root.connect_node("output", 0, "Time Seeker")

func seek(time:float):
	set("parameters/Time Seeker/seek_position", time)
	#seeker.set_parameter("seek_pos", time)

func get_sub_tree() -> AnimationNodeBlendTree:
	return _sub_blend_tree

func connect_animation_nodes(to:String, to_slot:int, from:String):
	(_sub_blend_tree as AnimationNodeBlendTree).connect_node(to, to_slot, from)

func disconnect_animation_nodes(to:String, to_slot:int):
	(_sub_blend_tree as AnimationNodeBlendTree).disconnect_node(to, to_slot)
	
func add_animation_node(node_name:String, graph_node:AGN_BASE_CLASS, offset:Vector2):
	var node:AnimationNode = graph_node.animation_node
	(_sub_blend_tree as AnimationNodeBlendTree).add_node(node_name, node, offset)
	if graph_node.has_parameters:
		graph_node.connect("parameter_changed", self, "set_node_parameter")

func remove_animation_node(graph_node):
	if graph_node.has_parameters:
		graph_node.disconnect("parameter_changed", self, "set_node_parameter")

func set_node_parameter(node_name:String, parameter_name:String, value):
	set("parameters/%s/%s" % [node_name, parameter_name], value)
	
func setup_output_graph_node(node:GraphNode):
	node.animation_node = (_sub_blend_tree as AnimationNodeBlendTree).get_node("output")