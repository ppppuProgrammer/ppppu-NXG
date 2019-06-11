extends Node

#Holds all settings for a character, from their looks
#to the animations they have.
var char_roster:Object = null
#Hold the default settings for the characters
var char_defaults:Object = null

#const Character = preload("res://Characters/Character.gd")

var char_user_settings = preload("res://Scene/Game Phases/Character Stage/Character user settings.tres")
export (int) var _MAX_NAME_LENGTH = 20
var _characters:Array = []
var _character_id_lookup:Dictionary = {}


func add_character(character:CharacterProfile)->int:
	if character.get_name_length() <= _MAX_NAME_LENGTH:
		var char_id:int = _characters.size()
		_characters.append(character)
		_character_id_lookup[character.get_name()] = char_id
		return char_id
	else:
		return -1

func remove_character(id:int):
	_characters.remove(id)
	#Fix the id lookup table.
	if get_character_count() > 0:
		for char_name in _character_id_lookup.keys():
			var current_id:int = _character_id_lookup[char_name]
			if current_id == id:
				_character_id_lookup.erase(char_name)
			elif current_id > id:
				_character_id_lookup[char_name] = current_id - 1
	else:
		_character_id_lookup.clear()
	#print(_characters)

func get_character_by_id(id:int):
	return _characters[id]

func has_character(char_name:String)->bool:
	var id:int = _character_id_lookup.get(char_name, -1)
	return true if id > -1 else false

func clear_characters():
	_characters.clear()
	_character_id_lookup.clear()

func get_character_count()->int:
	return _characters.size()
	
func get_max_name_length()->int:
	return _MAX_NAME_LENGTH