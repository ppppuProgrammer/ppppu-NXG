extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var _animStage
var _anmStagePlayer:AnimationPlayer
onready var animSelector = $"Animation Select".get_popup()
onready var blendAnimSelector = $"Blend+ Animation Select".get_popup()
onready var blend2AnimSelector = $"Blend- Animation Select".get_popup()
# Called when the node enters the scene tree for the first time.
func _ready():
	_animStage = get_parent()
	_anmStagePlayer = _animStage.get_node("AnimationPlayer")
	var animList = _anmStagePlayer.get_animation_list()
	animSelector.connect("index_pressed", self, "_on_Animation_Select_item_selected")
	blendAnimSelector.connect("index_pressed", self, "_on_Blend_Animation_Select_item_selected")
	blend2AnimSelector.connect("index_pressed", self, "_on_Blend2_Animation_Select_item_selected")
	for animName in animList:
		animSelector.add_item(animName)
		blendAnimSelector.add_item(animName)
		blend2AnimSelector.add_item(animName)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$FPS.text = "fps: %.1f" % Engine.get_frames_per_second()


func _on_Animation_Select_item_selected(index):
	var animName = animSelector.get_item_text(index)
	animSelector.get_parent().text = "Main: %s" % animName
	#_anmStagePlayer.assigned_animation = animName
	_animStage.changeAnimation(0, animName)
	
func _on_Blend_Animation_Select_item_selected(index):
	var animName = blendAnimSelector.get_item_text(index)
	blendAnimSelector.get_parent().text = "Blend+: %s" % animName
	_animStage.changeAnimation(1, animName)
	
func _on_Blend2_Animation_Select_item_selected(index):
	var animName = blend2AnimSelector.get_item_text(index)
	blend2AnimSelector.get_parent().text = "Blend-: %s" % animName
	_animStage.changeAnimation(-1, animName)

func _on_HSlider_value_changed(value:float):
	Engine.time_scale = value
	$Label.text = "Game Speed: x%.2f" % value
