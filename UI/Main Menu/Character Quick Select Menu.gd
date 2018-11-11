extends Control

onready var _icon_holder:HBoxContainer = $Panel/VBoxContainer/ScrollContainer/IconsHBox
const _image_button_preset = preload("res://UI/Main Menu/Character Image Button.tscn")
const _text_button_preset = preload("res://UI/Main Menu/Character Text Button.tscn")
onready var _current_char_label:Label = $"HBox/Name Limiter/Current Char Label"
onready var _character_bar:Label = $"HBox/Character Select Bar"

func _on_Roster_character_added(char_id:int, char_name:String):
	_character_bar.set_character_button(char_id, char_name)

func _on_Roster_character_removed(char_id:int):
	_character_bar.remove_button(char_id)

func _on_Roster_character_swapped(old_id:int, new_id:int):
	_character_bar.swap_character_buttons(old_id, new_id)
	
func _on_character_changed(char_id:int, char_name:String):
	_current_char_label.text = char_name

func _on_change_character_button(char_id, char_name, icon):
	_character_bar.set_character_button(char_id, char_name, icon)
