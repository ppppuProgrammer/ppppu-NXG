extends Node2D

onready var _scene = $Scene

#export (Array) var 
#The list of materials that are built into the game
export (Array) var default_materials
export (Array) var start_characters_resources

func _ready():
	#Load materials
	#for material_path in default_materials:
	#	$MaterialStash.add(load(material_path))
	#Might want a title screen here at some point.
	
	var stage:Node2D = load("res://Scene/AnimationStage.tscn").instance()
	
	add_child(stage)
	stage.load_characters(start_characters_resources)