extends Node

#Gathers group names and gradients, creates a large texture from them
#and sends them to the sprites that need those textures for their 
#color shaders 

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

func _on_ColorGroups_group_added(group_name):
	#var texture_array = []
	var largeTex:LargeTexture = LargeTexture.new()
	var largeTexSize:Vector2 = Vector2(1024, 1)
	largeTex.set_size(largeTexSize)
	_groupTextures[group_name] = largeTex
	for x in range(GameConsts.SECTIONS_IN_COLOR_GROUP):
		var gradientTex:GradientTexture = GradientTexture.new()
		gradientTex.width = 128
		#texture_array.append(gradientTex)
		largeTex.add_piece(largeTexSize / Vector2(GameConsts.SECTIONS_IN_COLOR_GROUP, 1), gradientTex)
	#_gradientTextures[group_name] = texture_array

func dispatch_character_palette(character_palette:Dictionary):
	var tex_piece:GradientTexture
	for group in character_palette.keys():
		var largeTex:LargeTexture = _groupTextures[group]
		for gradient_idx in range(0, character_palette[group].size()):
			var gradient:Gradient = character_palette[group][gradient_idx]
			tex_piece = (largeTex.get_piece_texture(gradient_idx) as GradientTexture)
			tex_piece.gradient = gradient
		#Now emit the changed large texture
		get_tree().call_group(CGROUP_PREFIX % group, "set_color_texture", -1, largeTex)