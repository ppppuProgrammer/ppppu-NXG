extends Node

#onready var _scene = $Scene
onready var world:Node = $Game_World
onready var gui:Control = $Game_GUI
#export (Array) var 
#The list of materials that are built into the game
export (int) var start_game_phase
export (Array) var default_materials
export (Array) var start_characters_resources
export (Array) var start_animations
const scenes_list:Resource = preload("res://Scene/Scene_list.tres")


func _ready():
	#Set up the world and gui function references
	world.func_add_gui_scene = funcref(self, "add_scene_to_gui")
	world.func_remove_all_gui_scenes = funcref(self, "clear_gui")
	world.func_remove_gui_scene = funcref(self, "remove_scene_from_gui")
	#Load materials
	#for material_path in default_materials:
	#	$MaterialStash.add(load(material_path))
	#Might want a title screen here at some point.
	
	var initial_scene:Node = scenes_list.game_phases[start_game_phase].instance()
	
	set_game_phase(initial_scene)
	#add_child(stage)
	#stage.load_characters(start_characters_resources)
	#stage.load_animations(start_animations)
	
# A world phase refers to a breakdown of the
# game into significant segments. The startup splash screen, title screen, 
# main menu, and gameplay are some examples of various phases a
# game can have. Only 1 phase can be active at a time.
func set_game_phase(phase:Node):
	world.set_world_phase(phase)
	if phase.is_in_group("Game_Phase"):
		phase.func_add_gui_scene
		phase.func_remove_all_gui_scenes
		phase.func_remove_gui_scene
	
func add_scene_to_gui(scene:Node):
	gui.add_gui_scene(scene)

func remove_scene_from_gui(scene:Node):
	gui.remove_gui_scene(scene)
	
func clear_gui():
	gui.remove_all_gui_scenes()