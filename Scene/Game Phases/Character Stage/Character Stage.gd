extends Node2D

# Character stage is the main scene of the game, being
# used to show the animations.

# The scene that is used as the gui for the stage.
# Needed to establish signal connections.
var _gui:Node = preload("res://UI/Character Stage UI/Char Stage UI.tscn").instance()

var func_add_gui_scene:FuncRef
var func_remove_gui_scene:FuncRef
var func_remove_all_gui_scenes:FuncRef

func _ready():
	pass