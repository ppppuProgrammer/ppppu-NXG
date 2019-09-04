extends Sprite

#var color_group_texture:LargeTexture
export (String) var material_group = null
#export (Array) var _defaultMaterialList 
func _ready():
	var groups:Array = get_groups()
	if groups.size() > 0:
		pass
	#print("%s: %s" % [self.name, self.get_groups()])

func change_color_mat_type(matType:int):
	pass
	
func set_color_group_texture(char_screen_id:int, color_textures:Array):
	#TODO: Properly check the character screen id for a match.
	if char_screen_id == -1:
		#color_group_texture = colorTex
		#print(colorTex)
		if material:
			for x in range(color_textures.size()):
				var section_num:int = x + 1
				material.set_shader_param("section%d" % section_num, color_textures[x])
			#set_default_texture_param("section%d" % x, texture.get_piece_texture(x))
