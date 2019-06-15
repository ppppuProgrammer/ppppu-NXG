extends GraphNode
class_name AnimationGraphNode
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
signal activate_char_parts_request
signal connect_by_mouse_request(connect_param_list)



func set_initial_settings(initialSettings:Dictionary = {}):
	if not initialSettings.empty():
		animation_node = initialSettings["animation_node"]
		initialSettings.erase("animation_node")
		for property in initialSettings:
			animation_node.set(property, initialSettings[property])

func _on_node_moved():
	animation_node.set_meta("offset", self.offset)

#func _gui_input(event):
#	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed:
#		print("R mouse button pressed")
#		var mouse_local:Vector2 = self.get_local_mouse_position()
#		for idx in range(self.get_child_count()):
#			var child = self.get_child(idx)
#			var rect:Rect2 = child.get_rect()
#			if rect.has_point(mouse_local):
#				if mouse_local.x <= get_rect().size.x / 2.0:
#					if is_slot_enabled_left(idx):
#						set_slot(idx, true, 
#						get_slot_type_left(idx),
#						Color.orange, is_slot_enabled_right(idx),
#						get_slot_type_right(idx), get_slot_color_right(idx))
#						emit_signal("connect_by_mouse_request", [null, null, self.name, idx])
#				else:
#					if is_slot_enabled_right(idx):
#						set_slot(idx, is_slot_enabled_left(idx), 
#						get_slot_type_left(idx),
#						get_slot_color_left(idx), true,
#						get_slot_type_right(idx), Color.orange)
#						emit_signal("connect_by_mouse_request", [self.name, idx, null, null])

#func _on_mouse_connection_finished(param_list):
#	for x in range(0, param_list.size(), 2):
#		if param_list[x] == self.name:
#			var idx = param_list[x+1]
#			if x == 0:
#				set_slot(idx, is_slot_enabled_left(idx), 
#						get_slot_type_left(idx),
#						get_slot_color_left(idx), true,
#						get_slot_type_right(idx), Color.white)
#			else:
#				set_slot(idx, true, 
#						get_slot_type_left(idx),
#						Color.white, is_slot_enabled_right(idx),
#						get_slot_type_right(idx), get_slot_color_right(idx))
#			#emit_signal("connect_by_mouse_request", [self.name, idx, null, null])

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