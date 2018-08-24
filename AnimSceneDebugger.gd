extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var _animStage
var _anmStagePlayer:AnimationPlayer
onready var animSelector = $"Animation Select".get_popup()
# Called when the node enters the scene tree for the first time.
func _ready():
	_animStage = get_parent()
	_anmStagePlayer = _animStage.get_node("AnimationPlayer")
	var animList = _anmStagePlayer.get_animation_list()
	animSelector.connect("index_pressed", self, "_on_Animation_Select_item_selected")
	for animName in animList:
		animSelector.add_item(animName)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$FPS.text = "fps: %.1f" % Engine.get_frames_per_second()


func _on_Animation_Select_item_selected(index):
	var animName = animSelector.get_item_text(index)
	animSelector.get_parent().text = animName
	#_anmStagePlayer.assigned_animation = animName
	_animStage.changeAnimation(animName)
