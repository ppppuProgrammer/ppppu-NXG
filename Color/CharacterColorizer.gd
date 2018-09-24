extends Node

#Handles colors for character parts

export var initialColorGroups:PoolStringArray = PoolStringArray()
var _charColors = {}

func setup(character_list:Array):
	for char_name in character_list:
		_charColors[char_name] = {}
		var currentCharColors = _charColors[char_name]
		for group in initialColorGroups:
			currentCharColors[group] = []
			var combinedTex:LargeTexture = LargeTexture.new()
			#combinedTex.