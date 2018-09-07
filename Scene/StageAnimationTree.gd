extends AnimationTree

const AGN_BASE_CLASS = preload("res://UI/Nodes/AnimationGraphNode.gd")

func connect_animation_nodes(to:String, to_slot:int, from:String):
	(tree_root as AnimationNodeBlendTree).connect_node(to, to_slot, from)

func disconnect_animation_nodes(to:String, to_slot:int):
	(tree_root as AnimationNodeBlendTree).disconnect_node(to, to_slot)
	
func add_animation_node(node_name:String, graph_node:AGN_BASE_CLASS, offset:Vector2):
	var node:AnimationNode = graph_node.animation_node
	(tree_root as AnimationNodeBlendTree).add_node(node_name, node, offset)
	if graph_node.has_parameters:
		graph_node.connect("parameter_changed", self, "set_node_parameter")

func remove_animation_node(graph_node):
	if graph_node.has_parameters:
		graph_node.disconnect("parameter_changed", self, "set_node_parameter")

func set_node_parameter(node_name:String, parameter_name:String, value):
	set("parameters/%s/%s" % [node_name, parameter_name], value)
	
func setup_output_graph_node(node:GraphNode):
	node.animation_node = (tree_root as AnimationNodeBlendTree).get_node("output")