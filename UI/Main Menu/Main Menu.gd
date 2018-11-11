extends Control

onready var _icon_holder:HBoxContainer = $Panel/VBoxContainer/ScrollContainer/IconsHBox
const _image_button_preset = preload("res://UI/Main Menu/Character Image Button.tscn")
const _text_button_preset = preload("res://UI/Main Menu/Character Text Button.tscn")

onready var current_char_label:Label = $"Panel/VBoxContainer/Current Char Label"

signal character_button_pressed(idx)

func set_character_button(char_number:int, name:String, icon:Texture=null):
	var button:BaseButton = null
	if icon == null:
		button = _create_text_button(char_number, name)
	else:
		button = _create_icon_button(char_number, name, icon)

	if button:
		assert(char_number <= _icon_holder.get_child_count())
		button.connect("pressed", self, "_on_Character_button_pressed", [button])
		if char_number == _icon_holder.get_child_count():
			_icon_holder.add_child(button)
		else:
			var old_button:BaseButton = _icon_holder.get_child(char_number)
			_icon_holder.remove_child(old_button)
			old_button.queue_free()
			_icon_holder.add_child(button)
			_icon_holder.move_child(button, char_number)
		
func _create_icon_button(char_number:int, name:String, tex:Texture):	
	var texButton:TextureButton = _image_button_preset.instance()
	texButton.texture_normal = tex
	texButton.hint_tooltip = name
	return texButton

func _create_text_button(char_number:int, text:String):
	var button:Button = _text_button_preset.instance()
	button.text = text
	button.hint_tooltip = text
	return button

func _on_Character_button_pressed(button):
	if button is BaseButton:
		emit_signal("character_button_pressed", button.get_position_in_parent())

func _on_Roster_character_added(char_id:int, char_name:String):
	set_character_button(char_id, char_name)

func _on_Roster_character_removed(char_id:int):
	var button:BaseButton = _icon_holder.get_child(char_id)
	_icon_holder.remove_child(button)
	button.queue_free()

func _on_Roster_character_swapped(old_id:int, new_id:int):
	_icon_holder.move_child(_icon_holder.get_child(new_id), old_id)
	_icon_holder.move_child(_icon_holder.get_child(old_id), new_id)


func _on_AnimationStage_character_changed(char_id:int):
	current_char_label.text = _icon_holder.get_child(
			char_id).hint_tooltip