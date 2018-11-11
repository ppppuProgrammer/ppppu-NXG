extends VBoxContainer

export (Vector2) var button_size setget _set_button_size

onready var _icon_holder:HBoxContainer = $ScrollContainer/IconsHBox

const _image_button_preset = preload("res://UI/Main Menu/Character Image Button.tscn")
const _text_button_preset = preload("res://UI/Main Menu/Character Text Button.tscn")

signal character_button_pressed(idx)

#func _on_change_character_button(char_id:int):
#	pass

func _set_button_size(size:Vector2):
	if button_size != size:
		button_size = size
		for icon in $ScrollContainer/IconsHBox.get_children():
			icon.rect_min_size = size
			icon.rect_size = size

func set_character_button(char_number:int, name:String, icon:Texture=null):
	var button:BaseButton = null
	if icon == null:
		button = _create_text_button(char_number, name)
	else:
		button = _create_icon_button(char_number, name, icon)

	if button:
		assert(char_number <= _icon_holder.get_child_count())
		button.rect_min_size = button_size
		button.connect("pressed", self, "_on_Character_button_pressed", [button])
		if char_number == _icon_holder.get_child_count():
			_icon_holder.add_child(button)
		else:
			remove_character_button(char_number)
			#var old_button:BaseButton = _icon_holder.get_child(char_number)
			#_icon_holder.remove_child(old_button)
			#old_button.queue_free()
			_icon_holder.add_child(button)
			_icon_holder.move_child(button, char_number)

func remove_character_button(char_id:int):
	var button:BaseButton = _icon_holder.get_child(char_id)
	_icon_holder.remove_child(button)
	button.queue_free()

func swap_character_buttons(old_id:int, new_id:int):
	_icon_holder.move_child(_icon_holder.get_child(new_id), old_id)
	_icon_holder.move_child(_icon_holder.get_child(old_id), new_id)

func get_button_tooltip(char_id:int):
	return _icon_holder.get_child(char_id).hint_tooltip

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