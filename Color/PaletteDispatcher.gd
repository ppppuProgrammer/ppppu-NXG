extends Node

#Gathers group names and gradients, creates a large texture from them
#and sends them any listeners

#The 8 gradient textures that will be used for the large texture
#var _gradientTextures:Dictionary = {}
#Holds the Large Texture that will be used by the shaders 
var _groupTextures:Dictionary = {}
#Here as a reminder for the "character screen" concept. Every 
#character screen would need it's own copy of a palette dispatcher.
#Don't actually use a variable like this though, have the parent
#of the dispatcher (character screen) pass the value, either during
#construction of the dispatcher or during the dispatch functions
#var character_screen_id
const CGROUP_PREFIX:String = "ColorGrp_%s"

signal color_group_has_changed(group_name, group_color_textures)

func _on_ColorGroups_group_added(group_name):
	var textures_list = []
	#var largeTex:LargeTexture = LargeTexture.new()
	#var largeTexSize:Vector2 = Vector2(1024, 1)
	#largeTex.set_size(largeTexSize)
	_groupTextures[group_name] = textures_list
	for x in range(GameConsts.SECTIONS_IN_COLOR_GROUP):
		var gradientTex:GradientTexture = GradientTexture.new()
		gradientTex.width = 128
		#texture_array.append(gradientTex)
		textures_list.append(gradientTex)
		#largeTex.add_piece(largeTexSize / Vector2(GameConsts.SECTIONS_IN_COLOR_GROUP, 1), gradientTex)
	#_gradientTextures[group_name] = texture_array

func dispatch_character_palette(character_palette:Dictionary):
	#var tex_piece:GradientTexture
	for group in character_palette.keys():
		print(group)
		var textures_list:Array = _groupTextures[group]
		for gradient_idx in range(0, character_palette[group].size()):
			var gradient:Gradient = character_palette[group][gradient_idx]
			var texture:GradientTexture = textures_list[gradient_idx]
			texture.gradient = gradient
		#	tex_piece = (largeTex.get_piece_texture(gradient_idx) as GradientTexture)
		#	tex_piece.gradient = gradient
		#Now emit the changed large texture
		#print(get_tree().has_group(CGROUP_PREFIX % group))
		#print(get_tree().get_nodes_in_group(CGROUP_PREFIX % group))
		get_tree().call_group(CGROUP_PREFIX % group, "set_color_group_texture", -1, textures_list)
		emit_signal("color_group_has_changed", group, textures_list)