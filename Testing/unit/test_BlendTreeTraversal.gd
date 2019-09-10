extends "res://addons/gut/test.gd"

var BTT_scene:Node = preload("res://Testing/unit/test Blend Tree Traversal/BTT Scene 1.tscn").instance()
var animation_player:AnimationPlayer = BTT_scene.get_node("AnimationPlayer")
var animNode_process_func_lookup:Dictionary = {"AnimationNodeAnimation": "parse_AnimationNodeAnimation"}
func test_AnimTest():
	var tree:AnimationTree = BTT_scene.get_node("Blend2Test")
	#var prop = tree.tree_root.get_property_list()
	#print(prop)
	print(get_blendtree_properties(tree.tree_root))
	var tree_traversal_data:Dictionary = traverse_blendtree(tree.tree_root)
	print(tree_traversal_data)
	
func traverse_blendtree(tree:AnimationNodeBlendTree)->Dictionary:
	var start:AnimationNodeOutput = tree.get_node("output")
	var tree_node_data:Dictionary = {}
	
	parse_animation_node(start, animation_player, tree_node_data, get_blendtree_properties(tree))
	return tree_node_data
	
#Recursively finds all the track names used by a node. To get all tracks used by a blendtree (or any other AnimationRootNode child)
#have the output node be passed to the initial call of this function.
#tree_data holds various information on the nodes within the tree and is updated
#as parsing happens.
#anim_node_properties is a read only dictionary that has information on properties of the nodes
#contained in the tree.
func parse_animation_node(node:AnimationNode, player:AnimationPlayer, tree_data:Dictionary, anim_node_properties:Dictionary):
	var node_class:String = node.get_class()
	var input_count:int = node.get_input_count()
	var node_data:Dictionary = {}
	if input_count > 0:
		for input_num in input_count:
			#Use the connection map from get_blendtree_properties() to find the node that is connecting 
			#to the node currently being parsed
			var connected_anim_node:AnimationNode = anim_node_properties[node].Input_Nodes[input_num]
			node_data[input_num] = parse_animation_node(connected_anim_node, player, tree_data, anim_node_properties)
			if self.has_method("parse_"+node_class):
				tree_data[node] = call("parse_"+node_class, node, player, node_data)
			else:
				tree_data[node] = "Missing parse function for " + node_class
		return tree_data[node]
	else:
		node_data = call(animNode_process_func_lookup[node_class], node, player, {})
		tree_data[node] = node_data
		return node_data
	
func parse_AnimationNodeAnimation(node:AnimationNodeAnimation, player:AnimationPlayer, data:Dictionary)->Dictionary:
	return {}
	
func parse_AnimationNodeOutput(node:AnimationNodeOutput, player:AnimationPlayer, data:Dictionary)->Dictionary:
	return {}
	
func parse_AnimationNodeBlend2(node:AnimationNodeBlend2, player:AnimationPlayer, data:Dictionary)->Dictionary:
	return {}

func get_blendtree_properties(tree:AnimationNodeBlendTree)->Dictionary:
	var tree_properties = tree.get_property_list()
	#var tree_properties = _animTree.tree_root.get
	var out_properties:Dictionary = {}
	print("tree properties:")
	for entry in tree_properties:
		print(entry)
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
					print("%s, %d, %s, %d" % [connections_map[connect_set+2], 0, connections_map[connect_set], connections_map[connect_set+1]])
				#connect_node(from, from_slot, to, to_slot)
			#print(connections_map)
	return out_properties
