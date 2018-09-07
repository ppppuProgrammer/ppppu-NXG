extends GraphEdit

const AnimationGraphNode = preload("res://UI/Nodes/AnimationGraphNode.gd")
var _addNodeData = {"Animation": preload("res://UI/Nodes/AGN_Select.tscn"), 
		"Blend2": preload("res://UI/Nodes/Blend2/AGN_Blend2.tscn")}
var _animations = []
var _animPlayer:AnimationPlayer
var _animTree:AnimationTree = null

signal new_animation_added
signal blend_tree_connection_changed
signal connected_nodes(to, to_slot, from)
signal disconnected_nodes(to, to_slot)
signal added_node(node_name, node, offset)
signal output_graph_node_added(output_graph_node)

# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("output_graph_node_added", $output)
	connect('connection_request', self, '_connect_graph_node')
	connect('disconnection_request', self, '_disconnect_graph_node')
	$AddNodeButton.get_popup().connect("index_pressed", self, "_on_Add_Node_Index_Pressed")
	for nodeName in _addNodeData.keys():
		$AddNodeButton.get_popup().add_item(nodeName)


func _connect_graph_node(from:String, from_slot:int, to:String, to_slot:int):
	connect_node(from, from_slot, to, to_slot)
	emit_signal("connected_nodes", to, to_slot, from)
	emit_signal("blend_tree_connection_changed")


func _disconnect_graph_node(from:String, from_slot:int, to:String, to_slot:int):
	disconnect_node(from, from_slot, to, to_slot)
	emit_signal("disconnected_nodes", to, to_slot)
	emit_signal("blend_tree_connection_changed")
	
func setup(animationPlayer:AnimationPlayer):
	_animPlayer = animationPlayer
	for animationName in _animPlayer.get_animation_list():
		_animations.append(animationName)

func get_currently_loaded_animation_names():
	return _animPlayer.get_animation_list()

func _on_Add_Node_Index_Pressed(index:int):
	var newGraphNode:AnimationGraphNode = _addNodeData[$AddNodeButton.get_popup().get_item_text(index)].instance()
	newGraphNode.offset = Vector2(50, 50)
	add_child(newGraphNode)
	emit_signal("added_node", newGraphNode.name, newGraphNode, newGraphNode.offset)

#Returns the names of all the nodes that have one or more of their properties being animated.
func get_names_of_animated_nodes():
	#Currently Animation Blend Trees do not provide a way to know what
	#animation nodes are connected to another. So instead rely
	#on the graph to traverse through the connections.
	#First construct a more detailed dictionary for the 
	#relationship between the graph nodes.
	var connection_map:Dictionary = {}
	for cdata in get_connection_list():
		var to:String = cdata['to']
		var from:String = cdata['from']
		if not to in connection_map:
			connection_map[to] = {}
		if not from in connection_map[to]:
			connection_map[to][from] = [cdata['to_port'], cdata['from_port']]
	
	var active_names:Array = []
	#Recursively navigate the blend tree to get the names of all
	#the nodes involved with the current animation blend tree.
	active_names = process_animated_node($output, connection_map)
	return active_names
	
func process_animated_node(node, map):
	var processed_data = {}
	#print("Current Node: %s" % node.name)
	var next = null if not node.name in map else map[node.name]
	if next:
		#print("Raw next: %s" % next)
		#print("Next: %s" % str(next.keys()))
		for data in next.keys():
			#print("data: %s" % data)
			#print(next[data][1])
			processed_data[next[data][0]] = process_animated_node(get_node(data), map)
		#print(processed_data)
		var processed = node.process_node_names(_animPlayer, processed_data)
		#print("Returning: %s" % str(processed))
		return processed
		#print("Returning: %s" % str(ret))
	else:
		#print("No next")
		return node.process_node_names(_animPlayer, processed_data)
	#print("%s : %s" % [node.name, node.process_node_names(_animPlayer, {})])