extends AnimationTree
class_name CharacterAnimationTree

#user_btree is the blend tree that is actually edited at runtime.
onready var _user_btree:AnimationNodeBlendTree = tree_root.get_node("user_editable_b-tree") as AnimationNodeBlendTree
onready var seeker:AnimationNodeTimeSeek = tree_root.get_node("Seek") as AnimationNodeTimeSeek
onready var _animation_player:AnimationPlayer = get_node(self.anim_player)
var tree_node_paths:Dictionary
var _traversal_current_base_path:String = ""
var _latest_tree_data_map:Dictionary = {}
const _parse_animnode_map:Dictionary = {"Default": "_parse_AnimationNodeDefault","AnimationNodeBlend2": "_parse_AnimationNodeBlend2",
		"AnimationNodeAdd2": "_parse_AnimationNodeAdd2", "AnimationNodeAnimation": "_parse_AnimationNodeAnimation",
		"AnimationNodeBlendTree": "_parse_AnimationNodeBlendTree", "AnimationNodeOutput": "_parse_AnimationNodeOutput"}
		
var part_type_finder:RegEx = RegEx.new()
func _ready():
	part_type_finder.compile("(^\\S+)")
	#Tree root is the "master" blend tree, comprised of a 
	# sub blend tree, a time seek node and the required output node.
	# Connections within it are fixed.

func seek(time:float):
	set("parameters/Seek/seek_position", time)
	#seeker.set_parameter("seek_pos", time)

func get_editable_blendtree() -> AnimationNodeBlendTree:
	return _user_btree

func get_part_requirments_for_current_animation()->Dictionary:
	var tracks_and_nodes:Dictionary = _latest_tree_data_map[tree_root.get_node("output")]
	var animation_requirements:Dictionary = {}
	#Just need node names though. 
	for node_name in tracks_and_nodes.Nodes:
		var regex_result:RegExMatch = part_type_finder.search(node_name)
		if regex_result:
			var inferred_type:String = regex_result.get_string()
			if not inferred_type in animation_requirements:
				animation_requirements[inferred_type] = []
			animation_requirements[inferred_type].append(node_name)
	return animation_requirements

#Warning: The following funcs do not support inner animationrootnode usage within the user btree
func connect_animation_nodes(to:String, to_slot:int, from:String):
	(_user_btree as AnimationNodeBlendTree).connect_node(to, to_slot, from)

func disconnect_animation_nodes(to:String, to_slot:int):
	(_user_btree as AnimationNodeBlendTree).disconnect_node(to, to_slot)
	
func add_animation_node(node_name:String, graph_node:AnimationGraphNode, offset:Vector2):
	var node:AnimationNode = graph_node.animation_node
	(_user_btree as AnimationNodeBlendTree).add_node(node_name, node, offset)
	if graph_node.has_parameters:
		graph_node.connect("parameter_changed", self, "set_node_parameter")
#End warning

func remove_animation_node(graph_node):
	if graph_node.has_parameters:
		graph_node.disconnect("parameter_changed", self, "set_node_parameter")

func set_node_parameter(node_name:String, parameter_name:String, value)->void:
	set("parameters/%s/%s" % [node_name, parameter_name], value)
	
func get_node_parameter(node_name:String, parameter_name:String):
	return get("parameters/%s/%s" % [node_name, parameter_name])
	
func setup_output_graph_node(node:GraphNode):
	node.animation_node = (_user_btree as AnimationNodeBlendTree).get_node("output")

func get_track_requirements():
	print(_user_btree.get_parameter_list())

func traverse_animationtree()->Dictionary:
	tree_node_paths = Dictionary()
	_traversal_current_base_path = ""
	if self.tree_root:
		var start_node:AnimationNodeOutput = self.tree_root.get_node("output")
		var tree_node_data:Dictionary = {}
		_parse_animation_node(start_node, _animation_player, tree_node_data, _get_blendtree_properties(self.tree_root))
		_latest_tree_data_map = tree_node_data
		return tree_node_data
	else:
		_latest_tree_data_map = {}
		return Dictionary()
	
#Recursively finds all the track names used by a node. To get all tracks used by a blendtree (or any other AnimationRootNode child)
#have the output node be passed to the initial call of this function.
#tree_data holds various information on the nodes within the tree and is updated
#as parsing happens.
#anim_node_properties is a dictionary that has information on properties of the nodes
#contained in the tree. Only read values from it.
func _parse_animation_node(node:AnimationNode, player:AnimationPlayer, tree_data:Dictionary, anim_nodes_properties:Dictionary):
	var node_class:String = node.get_class()
	var input_count:int = node.get_input_count()
	var node_data:Dictionary = {"RootNodeRef": anim_nodes_properties["BlendTreeRef"]}
	if input_count > 0:
		for input_num in input_count:
			#Use the connection map from _get_blendtree_properties() to find the node that is connecting 
			#to the node currently being parsed
			var connected_anim_node:AnimationNode = anim_nodes_properties[node].Input_Nodes[input_num]
			node_data[input_num] = _parse_animation_node(connected_anim_node, player, tree_data, anim_nodes_properties)
		
		tree_node_paths[node] = _traversal_current_base_path + anim_nodes_properties["BlendTreeRef"].get_node_name(node)
		if node_class in _parse_animnode_map:
			tree_data[node] = call(_parse_animnode_map[node_class], node, player, node_data)
		else:
			#defaultly parsed nodes don't need to have a record kept for them in tree_data
			node_data.erase("RootNodeRef")
			return call(_parse_animnode_map["Default"], node, player, node_data)
		node_data.erase("RootNodeRef")
		return tree_data[node]
	else:
		tree_node_paths[node] = _traversal_current_base_path + anim_nodes_properties["BlendTreeRef"].get_node_name(node)
		if node_class in _parse_animnode_map:
			tree_data[node] = call(_parse_animnode_map[node_class], node, player, node_data)
		else:
			node_data.erase("RootNodeRef")
			return call(_parse_animnode_map["Default"], node, player, node_data)
#		tree_data[node] = node_data
		node_data.erase("RootNodeRef")
		#node_data.erase("Tree Paths Ref")
		return tree_data[node]

func _create_node_requirements_dict(tracks:PoolStringArray, nodes:PoolStringArray)->Dictionary:
	var requirements:Dictionary = {"Tracks": tracks, "Nodes": nodes}
	return requirements
	
func _parse_AnimationNodeAnimation(node:AnimationNodeAnimation, player:AnimationPlayer, data:Dictionary)->Dictionary:
	#var node_requirements:Dictionary = _create_node_requirements_dict()
	var tracks:PoolStringArray
	var nodes:PoolStringArray
	
	var anim_name:String = node.animation
	if player.has_animation(anim_name):
		var anim:Animation = player.get_animation(anim_name)
		if anim:
			for track_idx in anim.get_track_count():
				var node_path:String = anim.track_get_path(track_idx)
				var node_name:String = anim.track_get_path(track_idx).get_name(0)
				if not node_path in tracks:
					tracks.append(node_path)
				if not node_name in nodes:
					nodes.append(node_name)
	return _create_node_requirements_dict(tracks, nodes)

func _parse_AnimationNodeAdd2(node:AnimationNodeAdd2, player:AnimationPlayer, data:Dictionary)->Dictionary:
	return _parse_blending_AnimationNode(node, data, "add_amount")

func _parse_blending_AnimationNode(node:AnimationNode, data:Dictionary, parameter_name:String):
	var tracks:PoolStringArray
	var nodes:PoolStringArray
	var blend_value:float = get_node_parameter(tree_node_paths[node], parameter_name)
	if blend_value == 0.0:
		tracks.append_array(data[0].Tracks)
		nodes.append_array(data[0].Nodes)
	elif blend_value == 1.0:
		tracks.append_array(data[1].Tracks)
		nodes.append_array(data[1].Nodes)
	else:
		tracks.append_array(data[0].Tracks)
		nodes.append_array(data[0].Nodes)
		for tracks2_str in data[1].Tracks:
			if not tracks2_str in tracks:
				tracks.append(tracks2_str)
		for nodes2_str in data[1].Nodes:
			if not nodes2_str in nodes:
				nodes.append(nodes2_str)
	return _create_node_requirements_dict(tracks, nodes)

func _parse_AnimationNodeBlendTree(node:AnimationNodeBlendTree, player:AnimationPlayer, data:Dictionary)->Dictionary:
	var inner_blend_tree_data:Dictionary = {}
	if data["RootNodeRef"] is AnimationNodeBlendTree:
		_traversal_current_base_path = _traversal_current_base_path + data["RootNodeRef"].get_node_name(node) + '/'
		inner_blend_tree_data = {}
		var inner_tree_output:AnimationNodeOutput = node.get_node("output")
		_parse_animation_node(inner_tree_output, player, inner_blend_tree_data, _get_blendtree_properties(node))
		_traversal_current_base_path = _traversal_current_base_path.substr(_traversal_current_base_path.find("/")+1)
	return inner_blend_tree_data

func _condense_parsed_data(node:AnimationNode, player:AnimationPlayer, data:Dictionary)->Dictionary:
	var in_data:Dictionary = data[0]
	if in_data.has_all(["Tracks", "Nodes"]):
		return data[0]
	else:
		var tracks:PoolStringArray
		var nodes:PoolStringArray
		for key in in_data:
			var single_node_data:Dictionary = in_data[key]
			if tracks.size() == 0:
				tracks.append_array(single_node_data.Tracks)
			else:
				for track_name in single_node_data.Tracks:
					if not track_name in tracks:
						tracks.append(track_name)
			if nodes.size() == 0:
				nodes.append_array(single_node_data.Nodes)
			else:
				for node_name in single_node_data.Nodes:
					if not node_name in nodes:
						nodes.append(node_name)
		return _create_node_requirements_dict(tracks, nodes)
		
func _parse_AnimationNodeDefault(node:AnimationNode, player:AnimationPlayer, data:Dictionary)->Dictionary:
	#Nodes that have this called shouldn't contain any data that modifies how an animation is played,
	#so just condense the data dictionary
	return _condense_parsed_data(node, player, data)
	
func _parse_AnimationNodeOutput(node:AnimationNodeOutput, player:AnimationPlayer, data:Dictionary)->Dictionary:
	return _condense_parsed_data(node, player, data)

func _parse_AnimationNodeBlend2(node:AnimationNodeBlend2, player:AnimationPlayer, data:Dictionary)->Dictionary:
	return _parse_blending_AnimationNode(node, data, "blend_amount")
	
func _get_blendtree_properties(tree:AnimationNodeBlendTree)->Dictionary:
	var tree_properties = tree.get_property_list()
	
	#var tree_properties = _animTree.tree_root.get
	var out_properties:Dictionary = {"BlendTreeRef": tree}
	#print("tree properties:")
	for entry in tree_properties:
		#print(entry)
		var tree_property_name:String = entry.name
		if tree_property_name.begins_with("nodes/"):
			#print("\tWill use entry %s" % tree_property_name)
			var node_name:String = tree_property_name.split('/')[1]
			var base_class = entry["class_name"]
			var node_class:String = ""
			var anim_node:AnimationNode = tree.get_node(node_name)
			if not anim_node in out_properties:
				out_properties[anim_node] = {"Input_Nodes": [], "Input_Names": [], "Properties":{}}
			var record_properties_as_relevant:bool = false
			if tree_property_name.ends_with("/node"):
				#print("Node properties:")
				var relevant_properties:Dictionary = out_properties[anim_node].Properties
				#print(relevant_properties["animation_node"])
				for node_prop in anim_node.get_property_list():
					var prop_name:String = node_prop["name"]
					#print(node_prop)
					if node_prop["usage"] == 256:
						node_class = prop_name
						if node_class == base_class:
							record_properties_as_relevant = true
					elif record_properties_as_relevant:
						var property_value = anim_node.get(prop_name)
						if property_value:
							relevant_properties[prop_name] = property_value
						
				#print("End of Node properties")
				
			elif tree_property_name.ends_with("/position"):
				#Don't actually use this property's value
				print("position: %s" % tree.get(tree_property_name))
				
#				var graph_node = get_node(node_name)
#				if graph_node:
#					if graph_node.animation_node and graph_node.animation_node.has_meta("offset"):
#						graph_node.offset = graph_node.animation_node.get_meta("offset")
#					print("offset: %s" % graph_node.offset)
				#print(entry)
#		elif tree_property_name == "graph_offset":
#			print(tree.get(entry.name))
		elif tree_property_name == "node_connections":
			var connections_map:Array = tree.get(entry.name)
			#out_properties[anim_node].Input_Connections = connections_map
			#Need to find the to port number for the graph node. Since AnimationNode can only have 1 from/output,
			#it's just a matter of finding the index of the first right enabled slot.
			if not connections_map.empty():
				for connect_set in range(0, connections_map.size(), 3):
					var input_connection_node:AnimationNode = tree.get_node(connections_map[connect_set])
					var output_connection_node_name:String = connections_map[connect_set+2]
					var output_connection_node:AnimationNode = tree.get_node(output_connection_node_name)
					out_properties[input_connection_node].Input_Nodes.append(output_connection_node)
					out_properties[input_connection_node].Input_Names.append(output_connection_node_name)
					#connect_node(connections_map[connect_set+2], 0, connections_map[connect_set], connections_map[connect_set+1])
					#print("%s, %d, %s, %d" % [connections_map[connect_set+2], 0, connections_map[connect_set], connections_map[connect_set+1]])
				#connect_node(from, from_slot, to, to_slot)
			#print(connections_map)
	return out_properties
