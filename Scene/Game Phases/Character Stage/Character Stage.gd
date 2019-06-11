extends Node2D
class_name CharacterStage
# Character stage is the main scene of the game, being
# used to show the animations.

#const Character = preload("res://Characters/Character.gd")
# The scene that is used as the gui for the stage.
# Needed to establish signal connections.
var _gui:Node = preload("res://UI/Character Stage UI/Char Stage UI.tscn").instance()
var _debug_gui:Node = null

var func_add_gui_scene:FuncRef
var func_remove_gui_scene:FuncRef
var func_remove_all_gui_scenes:FuncRef
onready var _characterAgency = $"Character Agency"

#signals
signal set_button_for_character(char_id, char_name, icon)
signal characters_cleared
signal character_removed(char_id)

func _ready():
	#Handle gui connections now
	connect("set_button_for_character", _gui, "_on_set_button_for_character")
	connect("characters_cleared", _gui, "_on_characters_cleared")
	connect("character_removed", _gui, "_on_character_removed")

func preconfigure(phase_change_data:Dictionary):
	func_add_gui_scene.call_func(_gui)
	if OS.is_debug_build():
		_debug_gui = load("res://UI/Debug/Debug Menu.tscn").instance()

func configure(phase_change_data:Dictionary):
	pass

func cleanup():
	if _gui:
		func_remove_gui_scene.call_func(_gui)
		
func add_character(character:CharacterProfile)->int:
	var char_id:int = _characterAgency.add_character(character)
	emit_signal("set_button_for_character", char_id, character.get_name(), character.get_icon())
	return char_id
	
func get_character_count()->int:
	return _characterAgency.get_character_count()
	
func does_character_exist(name:String)->bool:
	return false

func remove_all_characters():
	_characterAgency.clear_characters()
	emit_signal("characters_cleared")

func remove_character(char_id:int):
	_characterAgency.remove_character(char_id)
	emit_signal("character_removed", char_id)
	
func _input(event):
	if Input.is_action_just_pressed("Show Debug Menu") and OS.is_debug_build():
		pass