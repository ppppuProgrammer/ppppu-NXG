extends Node2D

#Animation Stage is where all the action happens.
#Here is where the Characters Screens are placed.
const _CHAR_SCREEN_CLASS = preload("res://Scene/Character Screen/Character Screen.gd")
const Character = preload("res://Characters/Character.gd")
var _character_screens = []
var _screen_names:Array = []
var current_character:int = -1

signal character_changed(char_id, char_name)
signal created_character_screen(screen_name)
signal renamed_character_screen(idx, name)
signal change_character_button(char_id, char_name, icon)

func _ready():
	#Screen.connect("apply_palette_request", self, "_change_character_palette")
	Log.append("Initializing Animation Stage")
	#Create 2 character screens initially.
	#create_new_screen("Male")
	#create_new_screen("Character1")
	#create_new_screen()

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
		#Icon
		#if temp_char.character_icon != null:
			#$"Main Menu".set_character_button(char_id, char_name, temp_char.character_icon)
		emit_signal("change_character_button", char_id, char_name, temp_char.character_icon)
		
		
		#Colors
		for color_group in temp_char.default_color_settings:
			#print(color_group)
			if not $ColorGroups.has_group(color_group):
				$ColorGroups.add(color_group)
			var color_group_id = $ColorGroups.get_id(color_group)
			var group_gradients:Array = temp_char.default_color_settings[color_group]
			#print(character.default_color_settings[color_group][0].colors[0])
			$Palettes.set_character_colors_for_group(char_id, color_group_id, group_gradients)
	
func load_characters(character_resource_list:Array):
	for char_res in character_resource_list:
		var character:Character = load(char_res) as Character
		_process_character(character)
	#Hard coded for now but later this will look to load
	#character data from a resource file or preferrably a pck
	#var pchData:Character = load("res://Characters/Presets/Peach_Character.tres") as Character
	#var pchData:Character = load("res://Characters/Presets/Peach_Character.tres")
	#_process_character(pchData)
	#var rosaData:Character = load("res://Characters/Presets/Rosalina_Character.tres")

func create_new_screen(name:String = ""):
	if name != "" and not name in _screen_names:
		return
	var _idx:int = _character_screens.size()
	_character_screens.append(_CHAR_SCREEN_CLASS.new())
	if name == "":
		name = "Unnamed %d" % _idx
	_screen_names.insert(_idx, name)
	emit_signal("created_character_screen", name)


	
func rename_screen(screen_num:int, new_name:String):
	emit_signal("renamed_character_screen", screen_num, new_name)

func _switch_to_character(char_id:int):
	current_character = char_id
	_change_character_palette()
	
	emit_signal("character_changed", current_character, $Roster.get_character_name(current_character))
	
func _change_character_palette():
	var palette = $Palettes.get_character_palette(current_character, $ColorGroups.get_group_names())
	$PaletteDispatcher.dispatch_character_palette(palette)
	#print("Changing palette")

func _on_Character_Select_Bar_character_button_pressed(idx:int):
	_switch_to_character(idx)


func _on_Add_Character_Screen_request():
	var free_idx:int = _character_screens.size()
	_character_screens.append(_CHAR_SCREEN_CLASS.new())
	var screen_name:String = "Screen %d" % (free_idx + 1)
	_screen_names.append(screen_name)
	emit_signal("created_character_screen", screen_name)
