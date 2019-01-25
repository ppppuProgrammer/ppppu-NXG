extends Node2D

#Animation Stage is where all the action happens.
#Here is where the Characters Screens are placed.
const CharacterScreenNode = preload("res://Scene/Character Screen/Character Screen.tscn")
const CharacterScreen = preload("res://Scene/Character Screen/Character Screen.gd")
const Character = preload("res://Characters/Character.gd")
var _character_screens = []
var _screen_names:Array = []
var current_character:int = -1
var _animations:Array = []

signal character_changed(char_id, char_name)
signal created_character_screen(screen_name)
signal renamed_character_screen(idx, name)
signal change_character_button(char_id, char_name, icon)
signal animation_added(animation)
signal character_screen_start_edit_reply(anim_tree)
signal character_screen_placement_data_reply(screen_placement)
signal sync_screen_animations(time)

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

func load_animations(animation_resource_list:Array):
	for anim_res in animation_resource_list:
		var animation:Animation = load(anim_res) as Animation
		if animation:
			_animations.append(animation)
			emit_signal("animation_added", animation)

func create_new_screen(name:String = ""):
	if name != "" and not name in _screen_names:
		return
	var _idx:int = _character_screens.size()
	var screen:CharacterScreen = CharacterScreen.new(_animations.duplicate(false))
	
	_character_screens.append(screen)
	var screen_name:String = "Ex %d" % (_idx)
	if _idx == 0:
		screen_name = "main"
	_screen_names.append(screen_name)
	connect("animation_added", screen, "add_animation_to_player")
	connect("sync_screen_animations", screen, "play_animation")
	$Screens.add_child(screen)
	emit_signal("created_character_screen", screen_name)


	
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
	#var free_idx:int = _character_screens.size()
	create_new_screen()
#	yield(screen, "ready")
	#_character_screens.append(screen)
	#screen.add_animations_to_player(_animations.duplicate(false))
#	screen.connect("animation_added", self, "add_animation_to_player")


func _on_character_screen_anim_tree_request(screen_num:int):
	var screen_tree = null
	var screen_player = null
	if screen_num < _character_screens.size():
		var screen:CharacterScreen = _character_screens[screen_num]
		screen_tree = screen.get_animation_tree()
		screen_player = screen.get_animation_player()
	emit_signal("character_screen_start_edit_reply", screen_tree, screen_player)

func _on_start_screen_animation(screen_num:int):
	var screen:CharacterScreen = $Screens.get_child(screen_num)
	if screen:
		screen.play_animation()


func _on_update_parts_for_character_screen(screen_num:int, animated_parts_list:Array):
	var screen:CharacterScreen = $Screens.get_child(screen_num)
	if screen:
		screen.update_parts(animated_parts_list)
		emit_signal("sync_screen_animations", 0.0)


func _on_character_screen_placement_data_request(screen_num:int):
	var screen:CharacterScreen = $Screens.get_child(screen_num)
	if screen:
		emit_signal("character_screen_placement_data_reply", Rect2(screen.position, screen.scale))
	else:
		emit_signal("character_screen_placement_data_reply", Rect2(Vector2(0, 0), Vector2(0, 0)))


func _on_character_screen_placement_changed(screen_num:int, screen_placement:Rect2):
	var screen:CharacterScreen = $Screens.get_child(screen_num)
	if screen:
		screen.position = screen_placement.position
		screen.scale = screen_placement.size


func _on_Animation_Seek(time:float):
	emit_signal("sync_screen_animations", time)
	
