extends Node2D

onready var _scene = $Scene
const Character = preload("res://Characters/Character.gd")
#export (Array) var 
signal character_changed(char_id)

func _ready():
	_load_characters()
	#Might want a title screen here at some point.
	
	add_child(load("res://Scene/AnimationStage.tscn").instance())
	_switch_to_character(0)
	
func _switch_to_character(char_id:int):
	var palette = $Palettes.get_character_palette(char_id, $ColorGroups.get_group_names())
	$PaletteDispatcher.dispatch_character_palette(palette)
	#emit_signal("character_changed", charId)
	
func _process_character(character:Character):
	var char_id:int = $Roster.add(character.character_name)
	if char_id > -1:
		#Store the character resource so the default settings can
		#be restored if needed
		$CharacterDefaults.add(character.character_name, character)
		#Colors
		for color_group in character.default_color_settings:
			#print(color_group)
			$ColorGroups.add(color_group)
			var color_group_id = $ColorGroups.get_id(color_group)
			var colorDict:Dictionary = character.default_color_settings
			var group_gradients:Array = character.default_color_settings[color_group]
			#print(character.default_color_settings[color_group][0].colors[0])
			$Palettes.set_character_colors_for_group(char_id, color_group_id, group_gradients)
			
	
func _load_characters():
	#Hard coded for now but later this will look to load
	#character data from a resource file or preferrably a pck
	var pchData:Character = load("res://Characters/Presets/Peach_Character.tres") as Character
	#var pchData:Character = load("res://Characters/Presets/Peach_Character.tres")
	_process_character(pchData)
	var rosaData:Character = load("res://Characters/Presets/Rosalina_Character.tres")
	_process_character(rosaData)
	
	