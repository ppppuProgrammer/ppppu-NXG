extends Node

#Stores references to the Character resources which have
#the default settings for a specific character.
const Character = preload("res://Characters/Character.gd")

var _defaults = {}

func add(character_name:String, character:Character):
	if not character_name in _defaults:
		_defaults[character_name] = character
		
func get_default_settings(character_name:String):
	if character_name in _defaults:
		return _defaults[character_name]
	else:
		return null