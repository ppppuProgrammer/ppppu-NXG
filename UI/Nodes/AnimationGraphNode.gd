extends GraphNode

var animation_node:AnimationNode = null
#Work around for the fact that Godot currently doesn't expose 
#a list of parameters that a type of animation node has.
var has_parameters:bool = false

signal parameter_changed(node_name, parameter_name, value)

#Returns an array of nodes that are being used by the animation node
#that this graph node represents. Subclasses that do some sort of
#modifications to the nodes that are to be animated should override
#this function
func process_node_names(animPlayer, data):
	if data.has(0):
		return data[0]
	else:
		return []