extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var _animStage
#var _anmStagePlayer:AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	_animStage = get_parent()
	#_anmStagePlayer = _animStage.get_node("AnimationPlayer")
	#var animList = _anmStagePlayer.get_animation_list()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Margin/BottomHBox/FPS.text = "fps: %.1f" % Engine.get_frames_per_second()

func _on_HSlider_value_changed(value:float):
	Engine.time_scale = value
	$Margin/BottomHBox/GSpeed.text = "Game Speed: x%.2f" % value
