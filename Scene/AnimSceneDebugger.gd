extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var _animStage
#var _anmStagePlayer:AnimationPlayer
const _COLOR_GROUP_PREFAB = preload("res://Scene/Debug Color Group Container.tscn")
onready var _color_grid:GridContainer = $"Margin/Color Panel/VBox/Scroll/Margin/Grid"
var _color_group_containers:Dictionary = {}
onready var _char_palette_label:Label = $"Margin/Color Panel/VBox/Char Palette Label" 
#onready var _char_palette_label:Label = $"Color Panel/VBox/Char Palette Label" 
const _DEFAULT_CHAR_PALETTE_STR:String = "Main Character Palette"
const _CHAR_PALETTE_STR:String = "%s's Palette"
const ColorDisplayBar = preload("res://UI/Common/Color Display Bar.gd")
# Called when the node enters the scene tree for the first time.
func _ready():
	_animStage = get_parent()
	_char_palette_label.text = _DEFAULT_CHAR_PALETTE_STR
	#_anmStagePlayer = _animStage.get_node("AnimationPlayer")
	#var animList = _anmStagePlayer.get_animation_list()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Margin/TopHBox/FPS.text = "fps: %.1f" % Engine.get_frames_per_second()

func _on_HSlider_value_changed(value:float):
	Engine.time_scale = value
	$Margin/TopHBox/GSpeed.text = "Game Speed: x%.2f" % value


func _on_AnimationStage_created_character_screen(screen_name:String):
	$"Char Screens Panel".add_screen(screen_name)


func _on_AnimationStage_renamed_character_screen(idx:int, screen_name:String):
	pass # Replace with function body.


func _on_PaletteDispatcher_color_group_has_changed(group_name:String, group_color_textures:Array):
	var group_container = _color_group_containers[group_name]
	if group_container:
		var sections:GridContainer = group_container.get_node("S Grid")
		for idx in range(group_color_textures.size()):
			var sectionTexture:ColorDisplayBar = sections.get_child(idx)
			var texture:GradientTexture = group_color_textures[idx]
			#sectionTexture.texture.gradient = 
			if texture:
				sectionTexture.change_color(texture)


func _on_ColorGroups_group_added(group_name:String):
	var group_container = _COLOR_GROUP_PREFAB.instance()
	group_container.get_node("Color Group Label").text = group_name
	_color_grid.add_child(group_container)
	_color_group_containers[group_name] = group_container


func _on_character_changed(char_id:int, char_name:String):
	_char_palette_label.text = _CHAR_PALETTE_STR % char_name

func _on_HideShow_Debugger_toggled(button_pressed:bool):
	if button_pressed:
		$"Debug Buttons/Hide-Show Debugger".text = "Hide Debug Menu"
	else:
		$"Debug Buttons/Hide-Show Debugger".text = "Show Debug Menu"
	$Margin.visible = button_pressed
	$"Debug Buttons/Other D Buttons".visible = button_pressed


func _on_Roster_character_added(char_id:int, char_name:String):
	$"Char Screens Panel/VBox0/VBox1/Panel/VBox2/Char List".get_popup().add_item(char_name)
	
