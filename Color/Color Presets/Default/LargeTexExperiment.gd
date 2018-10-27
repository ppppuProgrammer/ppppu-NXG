tool
extends Sprite

#export var largeTex:LargeTexture

func _ready():
	texture = LargeTexture.new()
	texture.set_size(Vector2(256.0, 1))
	var texs:Array = []
	var grads:Array = []
	grads.append(load("res://Color/Color Presets/Default/Female/Accessory-1_color.tres"))
	
	grads.append(load("res://Color/Color Presets/Default/Female/Accessory-2_color.tres"))
	grads.append(load("res://Color/Color Presets/Default/Female/Breast_color.tres"))
	grads.append(load("res://Color/Color Presets/Default/Female/Clit_color.tres"))
	grads.append(load("res://Color/Color Presets/Default/Female/Ear_color.tres"))
	grads.append(load("res://Color/Color Presets/Default/Female/Iris_color.tres"))
	grads.append(load("res://Color/Color Presets/Default/Female/Rosa/Hair/HairFrontAngled_RosaSeg2_color.tres"))
	grads.append(load("res://Color/Color Presets/Unset_color.tres"))

	var p = 256.0 / 8.0
	for x in range(0,8):
		var tex:GradientTexture = GradientTexture.new()
		tex.gradient = grads[x]
		tex.width = 128.0
		#texs.append(tex)
		#texture.add_piece(Vector2(x, 0.0), tex)
		texture.add_piece(Vector2( (x * p), 0), tex)
	
	
	