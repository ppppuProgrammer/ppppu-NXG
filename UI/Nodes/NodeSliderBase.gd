extends Control



func _on_HSlider_value_changed(value):
	$VBoxContainer/Label.text = str(value)
