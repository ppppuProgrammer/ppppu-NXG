extends Node

# Holds a list of all the characters currently loaded or created.

var _characters = []

signal character_added(char_id, char_name)
signal character_removed(char_id)
signal character_swapped(old_id, new_id)

func add(character_name:String):
	var id = -1
	if not character_name in _characters:
		id = _characters.size()
		_characters.append(character_name)
		emit_signal("character_added", id, character_name)
	return id
	
func remove(id:int):
	if id < _characters.size() and id >= 0:
		_characters.remove(id)
		emit_signal("character_removed", id)
	
func swap(old_id:int, new_id:int):
	if min(old_id, new_id) >= 0 and max(old_id, new_id) < _characters.size():
		var name2:String = _characters[new_id]
		_characters[new_id] = _characters[old_id]
		_characters[old_id] = name2
		emit_signal("characters_swapped", old_id, new_id)
	
func get_id(character_name:String):
	if character_name in _characters:
		return _characters.find(character_name)
	else:
		return -1