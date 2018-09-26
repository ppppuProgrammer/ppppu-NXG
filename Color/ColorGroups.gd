extends Node

#Responsible for maintaing the list of color groups that will
#be used by sprites.

var _groups = []
signal group_added(group_name)
signal group_size_changed(new_size)
#signal full_group_name_reply(char_id, group_id, group_name)


func add(group_name:String):
	var id:int = -1
	if not has_group(group_name):
		id = _groups.size()
		_groups.append(group_name)
		emit_signal("group_added", group_name)
		emit_signal("group_size_changed", _groups.size())
	return id
func get_group_names() -> Array:
	return _groups
	
func get_id(group_name:String):
	return _groups.find(group_name)
	
func has_group(group_name:String):
	return _groups.has(group_name)