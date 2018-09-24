extends Node2D

onready var _scene = $Scene
const Character = preload("res://Characters/Character.gd")
#export (Array) var 
func _ready():
	#Might want a title screen here at some point.
	
	add_child(load("res://Scene/AnimationStage.tscn").instance())
	
func _load_characters():
	#Hard coded for now but later this will look to load
	#character data from a resource file or preferrably a pck
	var pchData:Character = load("res://Characters/Peach_Character.tres")
	var rosaData:Character = load("res://Characters/Rosalina_Character.tres")
	
	#Set the character data into the character manager-ish class