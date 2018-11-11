extends Control

onready var _color_tex:TextureRect = $ColorTex

func change_color(color_texture:GradientTexture) -> void:
	_color_tex.texture = color_texture