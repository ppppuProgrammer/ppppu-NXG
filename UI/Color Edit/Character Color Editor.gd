extends Control

var selected_group:String = ""
var selected_section:int = 0

onready var _group_select:ItemList = $MarginContainer/VBoxContainer/CGroupSelect
onready var _gradient_editor = $"MarginContainer/VBoxContainer/ColorMargin/ColorHBox/Gradient Editor"
signal get_current_character_color_request(group_name, section)

func _ready():
	for node in $MarginContainer/VBoxContainer/SectionHBox.get_children():
		if node is BaseButton:
			node.connect("pressed", self, "_on_CSectionBtn_pressed", [int(node.text)])
	_gradient_editor.set_enabled(false)

func _on_CGroupSelect_item_selected(index:int):
	if index > -1:
		selected_group = _group_select.get_item_text(index)
		_get_color_for_character()

func _on_CSectionBtn_pressed(section_num:int):
	selected_section = section_num
	print(section_num)
	_get_color_for_character()
	
func _get_color_for_character():
	if selected_group != "" and selected_section > 0:
		_gradient_editor.set_enabled(true)
		emit_signal("current_character_color_request", selected_group, selected_section)
	else:
		_gradient_editor.set_enabled(false)
		
func _get_current_character_color_reply():
	pass