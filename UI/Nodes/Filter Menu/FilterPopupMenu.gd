extends PopupPanel

onready var path_list = $VBox/ScrollContainer/NodePathList
onready var search_bar = $VBox/SearchBar
const SUBPATH_CONTAINER = preload("res://UI/Nodes/Filter Menu/NodePathsContainer.tscn")
const CKBOX_PARENT_STR = "ChkBox_%s" 
const VBOX_CHILD_STR = "SubPath_%s" 
const VBOX_X = 10.0
signal filter_path_changed(nodePath, enable)
signal change_enabling_filter(enabled)
func populate_node_path_list(list:Array):
	#Remove all children.
	for child in path_list.get_children():
		child.queue_free()
		path_list.remove_child(child)
		
	var node_names_already_added:Array = []
	for path in list:
		var node_name:String = (path as NodePath).get_name(0)
		var checkbox:CheckBox = null
		if not node_name in node_names_already_added:
			checkbox = CheckBox.new()
			checkbox.name = CKBOX_PARENT_STR % node_name
			checkbox.text = node_name
			checkbox.set_meta("node_name", node_name)
			checkbox.connect("toggled", self, "_on_CheckBox_toggled", [node_name,true])
			path_list.add_child(checkbox)
			var subpathContainer = SUBPATH_CONTAINER.instance()
			subpathContainer.name = VBOX_CHILD_STR % node_name
			subpathContainer.set_meta("node_name", node_name)
			path_list.add_child(subpathContainer)
			node_names_already_added.append(node_name)
			
		checkbox = CheckBox.new()
		checkbox.text = (path as NodePath)
		checkbox.set_meta("node_name", node_name.to_lower())
		checkbox.connect("toggled", self, "_on_CheckBox_toggled", [node_name, false])
		#Don't assume that the paths are given in alphabetical order
		#so always query the container
		var container = path_list.get_node(VBOX_CHILD_STR % path.get_name(0))
		if container:
			container.get_node("VBC").add_child(checkbox)

#extraArgs: idx 0 is for the name of the node being animated
	#idx 1 indicates if the checkbox toggled controls all properties 
	#of the node that are to be animated 
func _on_CheckBox_toggled(toggle:bool, nodePath:NodePath, all_properties:bool):
	if all_properties:
		var container = path_list.get_node(VBOX_CHILD_STR % nodePath.get_name(0))
		for checkbox in container.get_node("VBC").get_children():
			checkbox.pressed = toggle
			emit_signal("filter_path_changed", checkbox.text, toggle)
	else:
		emit_signal("filter_path_changed", nodePath, toggle)

func _on_CloseButton_pressed():
	hide()

func _on_FilterCheckBox_toggled(button_pressed):
	emit_signal("change_enabling_filter", button_pressed)
	
func _on_SearchBar_text_changed(new_text:String):
	var searchText:String = new_text.to_lower()
	if searchText.length() > 0:
		for child in path_list.get_children():
			#print(child.name)
			_search_and_hide_nodes(searchText, child)
			if child is MarginContainer:
				if child.visible:
					var checkbox:CheckBox = path_list.get_node(CKBOX_PARENT_STR % child.get_meta("node_name"))
					if checkbox:
						checkbox.visible = true
	else:
		path_list.propagate_call("show")
		
func _search_and_hide_nodes(matchText:String, node):
	for child in node.get_children():
		_search_and_hide_nodes(matchText, child)
		
	if node.has_meta("node_name"):
		var nodePath:String = node.get_meta("node_name") 
		if nodePath:
			if nodePath.find(matchText) > -1:
				#print("node: %s, match: %d" % [nodePath, nodePath.find(matchText)])
				node.show()
			else:
				node.hide()
				
	#Parent visibility check
	if not node is CheckBox: 
		var showParent:bool = false
		for child in node.get_children():
			#print("%s, %s" % [child.name, child.visible])
			if child.visible:
				showParent = true
				break
		node.visible = showParent
