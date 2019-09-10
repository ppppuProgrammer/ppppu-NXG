extends AnimationTree
class_name CharacterAnimationTree

#user_btree is the blend tree that is actually edited at runtime.
onready var _user_btree:AnimationNodeBlendTree = tree_root.get_node("user_editable_b-tree") as AnimationNodeBlendTree
onready var seeker:AnimationNodeTimeSeek = tree_root.get_node("Seek") as AnimationNodeTimeSeek
#func _ready():
	#Tree root is the "master" blend tree, comprised of a 
	# sub blend tree, a time seek node and the required output node.
	# Connections within it are fixed.

func seek(time:float):
	set("parameters/Seek/seek_position", time)
	#seeker.set_parameter("seek_pos", time)

func get_sub_tree() -> AnimationNodeBlendTree:
	return _user_btree

func connect_animation_nodes(to:String, to_slot:int, from:String):
	(_user_btree as AnimationNodeBlendTree).connect_node(to, to_slot, from)

func disconnect_animation_nodes(to:String, to_slot:int):
	(_user_btree as AnimationNodeBlendTree).disconnect_node(to, to_slot)
	
func add_animation_node(node_name:String, graph_node:AnimationGraphNode, offset:Vector2):
	var node:AnimationNode = graph_node.animation_node
	(_user_btree as AnimationNodeBlendTree).add_node(node_name, node, offset)
	if graph_node.has_parameters:
		graph_node.connect("parameter_changed", self, "set_node_parameter")

func remove_animation_node(graph_node):
	if graph_node.has_parameters:
		graph_node.disconnect("parameter_changed", self, "set_node_parameter")

func set_node_parameter(node_name:String, parameter_name:String, value):
	set("parameters/%s/%s" % [node_name, parameter_name], value)
	
func setup_output_graph_node(node:GraphNode):
	node.animation_node = (_user_btree as AnimationNodeBlendTree).get_node("output")

func get_track_requirements():
	print(_user_btree.get_parameter_list())
