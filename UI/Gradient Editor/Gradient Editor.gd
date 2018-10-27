tool
extends Control

#onready var _gradientTexNode:TextureRect = $ColorPanel/Margin/CheckerBG/GradientTex

func set_enabled(enabled:bool):
	if not enabled:
		modulate = Color(.71, .72, .73, .27)
	else:
		modulate = Color.white
	$ColorPanel/Margin/GradientTex.set_inputs_enabled(enabled)
	$ColorPanel/Margin/CheckerBG.visible = enabled

func _on_GradientTex_show_color_picker():
	$PopupPanel.popup()
