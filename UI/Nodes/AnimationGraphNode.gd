extends GraphNode


#var agnType:int = -1
#var _gnTypes = preload("res://GraphNodeInfo.gd").GraphTypes
var animation_node:AnimationNode = null
#Work around for the fact that Godot currently doesn't expose 
#a list of parameters that an animation node has.
var has_parameters:bool = false

signal parameter_changed(node_name, parameter_name, value)
#Returns an array of nodes that are being used by the animation node
#that this graph node represents.
func process_node_names(animPlayer, data):
	print(name)