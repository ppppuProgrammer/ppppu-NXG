extends PanelContainer

onready var _tab:Tabs = $VBox0/VBox1/Tabs

signal character_for_screen_changed(screen_num, char_id)
func _ready():
	$"VBox0/VBox1/Panel/VBox2/Char List".get_popup().connect(
			"index_pressed", self, "_character_selected")
			
func add_screen(screen_name:String):
	_tab.add_tab(screen_name)
	
func _character_selected(index:int):
	var screen_id:int = $VBox0/VBox1/Tabs.current_tab
	var char_list_popup = $"VBox0/VBox1/Panel/VBox2/Char List".get_popup()
	var char_name:String = char_list_popup.get_item_text(index)
	$"VBox0/VBox1/Panel/VBox2/Char List".text = char_name
	emit_signal("character_for_screen_changed", screen_id, index)