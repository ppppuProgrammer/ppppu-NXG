extends Node2D

onready var _scene = $Scene
const Character = preload("res://Characters/Character.gd")
#export (Array) var 
#The list of materials that are built into the game
export (Array) var default_materials

signal character_changed(char_id)
var current_character:int = -1
func _ready():
	#Load materials
	for material_path in default_materials:
		$MaterialStash.add(load(material_path))
	
	_load_characters()
	#Might want a title screen here at some point.
	
	_switch_to_character(0)
	var stage:Node2D = load("res://Scene/AnimationStage.tscn").instance()
	add_child(stage)
	stage.connect("apply_palette_request", self, "_change_character_palette")
	
func _switch_to_character(char_id:int):
	current_character = char_id
	_change_character_palette()
	#emit_signal("character_changed", charId)
	
func _change_character_palette():
	var palette = $Palettes.get_character_palette(current_character, $ColorGroups.get_group_names())
	$PaletteDispatcher.dispatch_character_palette(palette)
	print("Changing palette")

func _process_character(character:Character):
	var char_name:String = character.character_name
	var char_id:int = $Roster.add(char_name)
	if char_id > -1:
		#Store the character resource so the default settings can
		#be restored if needed
		$CharacterDefaults.add(char_name, character)
		#Always work with a duplicate of the character so their default settings aren't 
		#modified
		var temp_char:Character = $CharacterDefaults.get_default_settings(char_name)
		#Colors
		for color_group in temp_char.default_color_settings:
			#print(color_group)
			if not $ColorGroups.has_group(color_group):
				$ColorGroups.add(color_group)
			var color_group_id = $ColorGroups.get_id(color_group)
			var group_gradients:Array = temp_char.default_color_settings[color_group]
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
	
	