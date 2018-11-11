extends Node

# Holds a list of all the characters currently loaded or created.

var _characters = []
export (int) var character_name_max_length = 20
signal character_added(char_id, char_name)
signal character_removed(char_id)
signal character_swapped(old_id, new_id)
signal character_renamed(char_id, new_name)

func add(character_name:String):
	var id = -1
	if character_name.length() > character_name_max_length:
		#var trimmed_name:String = character_name.substr(0, character_name_max_length)
		Log.append("Could not add character named \"%s\"" % character_name)
		Log.append("\tReason: Names have a limit of 30 characters. Remove %d characters to fix this."
				 % (character_name.length() - character_name_max_length))
		#character_name = trimmed_name
		return -1
		
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

func get_character_name(char_id:int) -> String:
	return _characters[char_id]

func rename(char_id:int, new_name:String):
	if not new_name in _characters and char_id < _characters.size():
		_characters[char_id] = new_name
		emit_signal("character_renamed", char_id, new_name)
#func get_character_name(character_id:int):
#	return _characters[character_id].character_name()