extends Node2D

#Animation Stage is where all the action happens.
#Here is where the Characters Screens are placed.
const _CHAR_SCREEN_CLASS = preload("res://Scene/Character Screen/Character Screen.gd")
var _character_screens = []
func _ready():
	Log.append("Initializing Animation Stage")
	#Create 2 character screens initially.
	_character_screens.append(_CHAR_SCREEN_CLASS.new())
	_character_screens.append(_CHAR_SCREEN_CLASS.new())
	
