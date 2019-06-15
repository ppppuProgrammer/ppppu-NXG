extends Control

onready var _icon_holder:HBoxContainer = $"HBox/Character Select Bar/ScrollContainer/IconsHBox"
const _image_button_preset = preload("res://UI/Main Menu/Character Image Button.tscn")
const _text_button_preset = preload("res://UI/Main Menu/Character Text Button.tscn")
onready var _current_char_label:Label = $"HBox/Name Limiter/Current Char Label"
onready var _character_bar:Label = $"HBox/Character Select Bar"

func clear_characters():
	_character_bar.reset()

func _on_Roster_character_added(char_id:int, char_name:String):
	_character_bar.set_character_button(char_id, char_name)

func remove_character_button(char_id:int):
	_character_bar.remove_character_button(char_id)

func _on_Roster_character_swapped(old_id:int, new_id:int):
	_character_bar.swap_character_buttons(old_id, new_id)
	
func _on_character_changed(char_id:int, char_name:String):
	_current_char_label.text = char_name

func set_character_button(char_id, char_name, icon):
	_character_bar.set_character_button(char_id, char_name, icon)

func get_buttons_count()->int:
	return _icon_holder.get_child_count()