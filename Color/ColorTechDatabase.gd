extends Node

#Stores information used by gradient shaders to know
#how to transform the texture.
#Dict["relative sprite path from container"] : Dict["Gradient Name"] : gradientData "struct"
const ColorTechData = preload("res://Color/ColorTechData.gd")
var gradient_database:Dictionary = {}

func add_gradient_to_database(relative_node_path:NodePath, gradient_name:String, data:ColorTechData):
	pass