#tool
extends Node

#Node that sets its parent properties so it can be properly masked
const CHARPART_CLASS = preload("res://CharacterPart.gd")
const MASK_MAT = preload("res://Materials/Mask.tres")
var _parent = null
var _rawLayer = 0
func changeMaskingLayer(layer:int):
	var _parent = get_parent()
	if _parent:
		_parent.changeLightMaskLayerForSprites(layer)
	#self.light_mask = 1 << layer
	_rawLayer = layer

#var _masker
func _ready():
	_parent = get_parent()
	if _parent is CHARPART_CLASS:
		_parent.connect("sig_removeMasking", self, "_handleRemoval")
		_parent.material = MASK_MAT
		_parent.changeLightMaskLayerForSprites(1 << _rawLayer)
		

func _handleRemoval():
	var _parent = get_parent()
	_parent.disconnect("sig_removeMasking", self, "_handleRemoval")
	queue_free()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
