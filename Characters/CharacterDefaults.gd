extends Node

#Stores references to the Character resources which have
#the default settings for a specific character.
#const Character = preload("res://Characters/Character.gd")

var _defaults = {}

func add(character_name:String, character:Character):
	if character_name in _defaults and _defaults[character_name] == null:
		_defaults[character_name] = character
		
func get_default_settings(character_name:String) -> Character:
	if character_name in _defaults:
		return _defaults[character_name].duplicate(true)
	else:
		return null
		
func get_default_palette(character_name:String):
	if character_name in _defaults:
		return _defaults[character_name].default_color_settings.duplicate(true)
	else:
		return null

func _on_Roster_character_swapped(old_id, new_id):
	var char2:Character = _defaults[new_id]
	_defaults[new_id] = _defaults[old_id]
	_defaults[old_id] = char2

func _on_Roster_character_added(char_id, char_name):
	_defaults[char_name] = null

func _on_Roster_character_removed(char_id):
	_defaults.remove(char_id)
