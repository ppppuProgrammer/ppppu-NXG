class_name AnimationGraphEdit
extends GraphEdit

const AnimationGraphNode = preload("res://UI/Nodes/AnimationGraphNode.gd")
const StageAnimationTree = preload("res://Scene/StageAnimationTree.gd")
var _addNodeData = {"Animation": preload("res://UI/Nodes/AGN_Select.tscn"), 
		"Blend2": preload("res://UI/Nodes/Blend2/AGN_Blend2.tscn")}
var _animations:Array = []
var _animPlayer:AnimationPlayer
var _animTree:AnimationTree = null
var _unremovable_nodes:Array = []

signal new_animation_added
#signal blend_tree_connection_changed
signal connected_nodes(to, to_slot, from)
signal disconnected_nodes(to, to_slot)
signal added_node(node_name, node, offset)
signal output_graph_node_added(output_graph_node)
signal filter_list_sent(filter_list)
#signal update_character_parts
signal blend_tree_has_changed(animated_parts_list)
#signal connection_by_mouse_finished

var _graph_node_translations:Dictionary = {
	"AnimationNodeAnimation": _addNodeData["Animation"],
	"AnimationNodeBlend2": _addNodeData["Blend2"]
}

#idx 0 is for to, 1 is for to slot, 2 is from.
#var _pending_mouse_connection = []
onready var _filter_menu:PopupPanel = $FilterPopupMenu
# Called when the node enters the scene tree for the first time.
func _ready():
	for node in get_children():
		_unremovable_nodes.append(node)
	Log.append("Initializing Animation Editor")
	
	#Set up the Animation Editor Graph
	#_graph.setup(_masterPlayer)
	
	
	emit_signal("output_graph_node_added", $output)
	#$output.connect("connect_by_mouse_request", self, "_on_mouse_connect_request")
	connect('connection_request', self, '_connect_graph_node')
	connect('disconnection_request', self, '_disconnect_graph_node')
	$AddNodeButton.get_popup().connect("index_pressed", self, "_on_Add_Node_Index_Pressed")
	for nodeName in _addNodeData.keys():
		$AddNodeButton.get_popup().add_item(nodeName)
	remove_child(_filter_menu)
	_filter_menu.connect("popup_hide", self, "_filter_popup_menu_hidden")

func clear_editor() -> void:
	if _animTree:
		disconnect("connected_nodes", _animTree, "connect_animation_nodes")
		disconnect("disconnected_nodes", _animTree, "disconnect_animation_nodes")
		disconnect("added_node", _animTree, "add_animation_node")
		disconnect("output_graph_node_added", _animTree, "setup_output_graph_node")
	_animTree = null
	clear_connections()
	for node in get_children():
		if not node in _unremovable_nodes:
			node.disconnect("activate_char_parts_request", self, "_on_activate_char_parts_request")
			if node.has_filter:
				node.disconnect("show_filter_menu", self, "_show_filter_popup_menu")
			remove_child(node)
			node.queue_free()
	
func set_animation_tree(anim_tree:StageAnimationTree, animation_player:AnimationPlayer) -> void:
	_animTree = anim_tree
	_animPlayer = animation_player
	connect("connected_nodes", _animTree, "connect_animation_nodes")
	connect("disconnected_nodes", _animTree, "disconnect_animation_nodes")
	connect("added_node", _animTree, "add_animation_node")
	connect("output_graph_node_added", _animTree, "setup_output_graph_node")
	#Reconstruct the node layout based on the animation tree
	var _sub_tree:AnimationNodeBlendTree = _animTree.get_sub_tree()
	var tree_properties = _sub_tree.get_property_list()
	#var tree_properties = _animTree.tree_root.get
	print("tree properties:")
	for entry in tree_properties:
		print(entry)
		var tree_property_name:String = entry.name
		if tree_property_name.begins_with("nodes/"):
			#print("\tWill use entry %s" % tree_property_name)
			var node_name:String = tree_property_name.split('/')[1]
			var base_class = entry["class_name"]
			var node_class:String = ""
			var record_properties_as_relevant:bool = false
			if tree_property_name.ends_with("/node"):
				#print("Node properties:")
				var relevant_properties:Dictionary = {"animation_node": _sub_tree.get_node(node_name)}
				#print(relevant_properties["animation_node"])
				var current_animation_node:AnimationNode = _sub_tree.get_node(node_name)
				for node_prop in current_animation_node.get_property_list():
					var prop_name:String = node_prop["name"]
					#print(node_prop)
					if node_prop["usage"] == 256:
						node_class = prop_name
						if node_class == base_class:
							record_properties_as_relevant = true
					elif record_properties_as_relevant:
						var property_value = current_animation_node.get(prop_name)
						if property_value:
							relevant_properties[prop_name] = property_value
						
				#print("End of Node properties")
				if node_class in _graph_node_translations.keys():
					var graph_node = _graph_node_translations[node_class].instance()
					graph_node.name = node_name
					#graph_node.call_deferred("set_initial_settings", relevant_properties)
					add_child(graph_node)
					graph_node.set_initial_settings(relevant_properties)
			elif tree_property_name.ends_with("/position"):
				#Don't actually use this property's value
				print("position: %s" % _sub_tree.get(tree_property_name))
				var graph_node = get_node(node_name)
				if graph_node:
					if graph_node.animation_node and graph_node.animation_node.has_meta("offset"):
						graph_node.offset = graph_node.animation_node.get_meta("offset")
					#graph_node.offset = _sub_tree.get(entry.name)
					print("offset: %s" % graph_node.offset)
				#print(entry)
		elif tree_property_name == "graph_offset":
			print(_sub_tree.get(entry.name))
		elif tree_property_name == "node_connections":
			var connections_map:Array = _sub_tree.get(entry.name)
			#Need to find the to port number for the graph node. Since AnimationNode can only have 1 from/output,
			#it's just a matter of finding the index of the first right enabled slot.
			if not connections_map.empty():
				for connect_set in range(0, connections_map.size(), 3):
					connect_node(connections_map[connect_set+2], 0, connections_map[connect_set], connections_map[connect_set+1])
					print("%s, %d, %s, %d" % [connections_map[connect_set+2], 0, connections_map[connect_set], connections_map[connect_set+1]])
				#connect_node(from, from_slot, to, to_slot)
			print(connections_map)
			
		

#func _on_mouse_connect_request(connect_param_list:Array):
#	if _pending_mouse_connection.size() == 0:
#		_pending_mouse_connection = connect_param_list
#		if _pending_mouse_connection[0] != null:
#			connect("connection_by_mouse_finished", get_node(_pending_mouse_connection[0]), "_on_mouse_connection_finished")
#		elif _pending_mouse_connection[2] != null:
#			connect("connection_by_mouse_finished", get_node(_pending_mouse_connection[2]), "_on_mouse_connection_finished")
#		return
#	for idx in range(connect_param_list.size()):
#		if _pending_mouse_connection[idx] == null and connect_param_list[idx] != null:
#			_pending_mouse_connection[idx] = connect_param_list[idx]
#			if _pending_mouse_connection[idx] is String:
#				connect("connection_by_mouse_finished", get_node(_pending_mouse_connection[idx]), "_on_mouse_connection_finished")
#
#		elif _pending_mouse_connection[idx] == null:
#			emit_signal("connection_by_mouse_finished", _pending_mouse_connection)
#			if _pending_mouse_connection[0] != null and is_connected("connection_by_mouse_finished", get_node(_pending_mouse_connection[0]), "_on_mouse_connection_finished"):
#				disconnect("connection_by_mouse_finished", get_node(_pending_mouse_connection[0]), "_on_mouse_connection_finished")
#			if _pending_mouse_connection[2] != null and is_connected("connection_by_mouse_finished", get_node(_pending_mouse_connection[2]), "_on_mouse_connection_finished"):	
#				disconnect("connection_by_mouse_finished", get_node(_pending_mouse_connection[2]), "_on_mouse_connection_finished")
#			_pending_mouse_connection = []
#			return
#	_connect_graph_node(_pending_mouse_connection[0], 
#			_pending_mouse_connection[1], _pending_mouse_connection[2], 
#			_pending_mouse_connection[3])
#	emit_signal("connection_by_mouse_finished", _pending_mouse_connection)
#	disconnect("connection_by_mouse_finished", get_node(_pending_mouse_connection[0]), "_on_mouse_connection_finished")
#	disconnect("connection_by_mouse_finished", get_node(_pending_mouse_connection[2]), "_on_mouse_connection_finished")
#	_pending_mouse_connection = []
	
func _connect_graph_node(from:String, from_slot:int, to:String, to_slot:int):
	connect_node(from, from_slot, to, to_slot)
	emit_signal("connected_nodes", to, to_slot, from)
	#emit_signal("blend_tree_connection_changed")
	emit_signal("blend_tree_has_changed", get_names_of_animated_nodes())


func _disconnect_graph_node(from:String, from_slot:int, to:String, to_slot:int):
	disconnect_node(from, from_slot, to, to_slot)
	emit_signal("disconnected_nodes", to, to_slot)
	#emit_signal("blend_tree_connection_changed")
	emit_signal("blend_tree_has_changed", get_names_of_animated_nodes())

func get_animation_names_list() -> Array:
	var animation_names:Array = []
	for anim in _animations:
		animation_names.append(anim.resource_name)
	return animation_names

func add_animation(animation:Animation) -> void:
	_animations.append(animation)

func _on_Add_Node_Index_Pressed(index:int):
	var newGraphNode:AnimationGraphNode = _addNodeData[$AddNodeButton.get_popup().get_item_text(index)].instance()
	newGraphNode.offset = Vector2(50, 50)
	add_child(newGraphNode, true)
	newGraphNode.connect("offset_changed", newGraphNode, "_on_node_moved")
	newGraphNode.connect("activate_char_parts_request", self, "_on_activate_char_parts_request")
	#newGraphNode.connect("connect_by_mouse_request", self, "_on_mouse_connect_request")
	if newGraphNode.has_filter:
		newGraphNode.connect("show_filter_menu", self, "_show_filter_popup_menu")
		#newGraphNode.connect("filter_list_request", self, "_get_filterable_nodes_list")
	emit_signal("added_node", newGraphNode.name, newGraphNode, newGraphNode.offset)
	
#func _on_Node_Removal():
	#graphNode.disconnect("connect_by_mouse_request", self, "_on_mouse_connect_request")
	
func _show_filter_popup_menu(graphNode:GraphNode):
	if _filter_menu.get_parent() != self:
		add_child(_filter_menu)
		var connection_map:Dictionary = create_node_connection_map()
		var filterables = process_animated_node(graphNode, connection_map, false)
		_filter_menu.populate_node_path_list(filterables)
		_filter_menu.set_meta("caller", graphNode)
		_filter_menu.connect("filter_path_changed", graphNode, "_set_path_filter")
		_filter_menu.connect("change_enabling_filter", graphNode, "_set_filter_enabled")
		_filter_menu.popup()

func _filter_popup_menu_hidden():
	var caller = _filter_menu.get_meta("caller")
	_filter_menu.disconnect("filter_path_changed", caller, "_set_path_filter")
	_filter_menu.disconnect("change_enabling_filter", caller, "_set_filter_enabled")
	set_meta("caller", null)
	remove_child(_filter_menu)

func _get_filterable_nodes_list(animation_node:AnimationNode):
	#var list = []
	var connection_map:Dictionary = create_node_connection_map()
	emit_signal("filter_list_sent", process_animated_node(animation_node, connection_map, false))

func _on_activate_char_parts_request():
	#emit_signal("update_character_parts")
	emit_signal("blend_tree_has_changed", get_names_of_animated_nodes())

func create_node_connection_map():
	var connection_map:Dictionary = {}
	for cdata in get_connection_list():
		var to:String = cdata['to']
		var from:String = cdata['from']
		if not to in connection_map:
			connection_map[to] = {}
		if not from in connection_map[to]:
			connection_map[to][from] = [cdata['to_port'], cdata['from_port']]
	return connection_map

#Returns the names of all the nodes that have one or more of their properties being animated.
func get_names_of_animated_nodes():
	#Currently Animation Blend Trees do not provide a way to know what
	#animation nodes are connected to another. So instead rely
	#on the graph to traverse through the connections.
	#First construct a more detailed dictionary for the 
	#relationship between the graph nodes.
	var connection_map:Dictionary = create_node_connection_map()
	
	var active_names:Array = []
	#Recursively navigate the blend tree to get the names of all
	#the nodes involved with the current animation blend tree.
	active_names = process_animated_node($output, connection_map)
	return active_names
	
func process_animated_node(node, map, node_names_only:bool=true):
	var processed_data = {}
	#print("Current Node: %s" % node.name)
	var next = null if not node.name in map else map[node.name]
	if next:
		#print("Raw next: %s" % next)
		#print("Next: %s" % str(next.keys()))
		for data in next.keys():
			#print("data: %s" % data)
			#print(next[data][1])
			processed_data[next[data][0]] = process_animated_node(get_node(data), map, node_names_only)

		#print(processed_data)
		var processed = node.process_node_paths(_animPlayer, processed_data, node_names_only)
		#print("Returning: %s" % str(processed))
		return processed
		#print("Returning: %s" % str(ret))
	else:
		#print("No next")
		return node.process_node_paths(_animPlayer, processed_data, node_names_only)
	#print("%s : %s" % [node.name, node.process_node_names(_animPlayer, {})])
