extends Node

# Holds the parameters that are used by the materials

export var _parameters:Dictionary = {} setget parameters_set, parameters_get
#Hardcoded "parameters" that won't count against the Char Part Sprite's limit
#var _reserved_names:Array = ["Colorable", "Mask"]

func parameters_get():
	return null
	
func parameters_set(dict:Dictionary):
	pass
	
#_parameters[mat name]