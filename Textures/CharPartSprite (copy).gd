extends Sprite

var color_group_texture:LargeTexture

func change_color_mat_type(matType:int):
	pass
	
func set_color_group_texture(char_screen_id:int, texture:LargeTexture):
	#TODO: Properly check the character screen id for a match.
	if char_screen_id == -1:
		color_group_texture = texture
		for x in range(texture.get_piece_count()):
			#set_default_texture_param("section%d" % x+1, texture.get_piece_texture(x))
			pass