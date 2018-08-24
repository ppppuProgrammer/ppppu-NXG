tool
extends Node2D

const CHARPART_CLASS = preload("res://CharacterPart.gd")
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here.
	pass

func _process(delta):
	pass
	if Input.is_key_pressed(KEY_P):
		#syncAnimationPlayers(0.0)
		$AnimationPlayer.play("1_Cowgirl-animation")
	#elif Input.is_key_pressed(KEY_R):
		#syncAnimationPlayers(0.0)
	#	$AnimationPlayer.play("1_Cowgirl Ros-animation")
	#if Input.is_key_pressed(KEY_T):
	#	setDefaultTextures()

func setDefaultTextures():
	for child in self.get_children():
		if child is CHARPART_CLASS:
			child.mainTexId = 0

func syncAnimationPlayers(time):
	for child in self.get_children():
		if child is CHARPART_CLASS:
			child.setAnimPlayPosition(0)
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
