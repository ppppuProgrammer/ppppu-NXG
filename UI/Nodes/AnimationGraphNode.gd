extends GraphNode

var animation_node:AnimationNode = null
#Work around for the fact that Godot currently doesn't expose 
#a list of parameters that a type of animation node has.
var has_parameters:bool = false
#Work around for an actual bug. Virtual methods that are binded
#don't actually exist when called in a program even though 
#it's shown to exist when using get_method_list.
var has_filter:bool = false

signal parameter_changed(node_name, parameter_name, value)
signal show_filter_menu(animNode)
signal filter_list_request(node)
#Returns an array of nodes that are being used by the animation node
#that this graph node represents. Subclasses that do some sort of
#modifications to the nodes that are to be animated should override
#this function
func process_node_names(animPlayer, data):
	if data.has(0):
		return data[0]
	else:
		return []

func _set_path_filter(nodePath:NodePath, enable:bool):
	animation_node.set_filter_path(nodePath, enable)
	
func _set_filter_enabled(enable:bool):
	animation_node.filter_enabled = enable
	

func process_node_paths(animPlayer, data, baseNameOnly:bool):
	if data.has(0):
		return data[0]
	else:
		return []