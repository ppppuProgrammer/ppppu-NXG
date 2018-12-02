extends PopupPanel

func _on_Close_Button_pressed():
	$"VBoxContainer/Animation Editor".clear_editor()
	if visible:
		hide()

func show_editor():
	if not visible:
		show()