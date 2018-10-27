extends Node

# Houses the color textures that are assigned for a character.
# Depth 0 is char id, depth 1 is group id, depth 2 is an array 
# of 8 gradients
var _palettes:Array = []
var _color_groups_size:int = 0
const _unset_color:Gradient = preload("res://Color/Color Presets/Unset_color.tres")
signal full_group_name_request(color_group_id)
#Adds

#Returns a dictionary (K-V: group name-gradient array)
func get_character_palette(char_id:int, group_names:Array) -> Dictionary:
	var character_palette = {}
	for group_id in range(group_names.size()):
		var group_name = group_names[group_id]
		character_palette[group_name] = _palettes[char_id][group_id]
	return character_palette

func set_character_colors_for_group(character_id:int, group_id:int, gradients:Array):
	if _palettes[character_id][group_id] == null:
		_palettes[character_id][group_id] = _create_group_array()
	
	for x in range(gradients.size()):
		if gradients[x] != null:
			_palettes[character_id][group_id][x] = gradients[x].duplicate()

func _create_group_array():
	var array:Array = []
	for x in range(GameConsts.SECTIONS_IN_COLOR_GROUP):
		array.append(_unset_color.duplicate())
	return array

func get_character_colors_for_group(char_id:int, group_id:int):
	return _palettes[char_id][group_id]
	
func get_character_color_from_group(char_id:int, group_id:int, gradient_idx:int):
	return _palettes[char_id][group_id][gradient_idx]

func _set_character_color(char_id:int, group_id:int, gradient_idx:int, gradient:Gradient):
	_palettes[char_id][group_id][gradient_idx] = gradient
	
func _on_ColorGroups_group_size_changed(new_size:int):
	_color_groups_size = new_size
	for char_palette in _palettes:
		char_palette.resize(new_size)

func _on_Roster_character_added(char_id:int, char_name:String):
	_palettes.insert(char_id, [])#.resize(_color_groups_size))
	_palettes[char_id].resize(_color_groups_size)
	#initialize the group arrays
	for group_array in _palettes[char_id]:
		group_array = _create_group_array()

func _on_Roster_character_removed(char_id:int):
	_palettes.remove(char_id)

func _on_Roster_character_swapped(old_id:int, new_id:int):
	var palette2:Array = _palettes[new_id]
	_palettes[new_id] = _palettes[old_id]
	_palettes[old_id] = palette2



func _on_Game_character_changed(char_id:int):
	for group_id in range(_palettes[char_id].size()):
		emit_signal("full_group_name_request", char_id, group_id)
