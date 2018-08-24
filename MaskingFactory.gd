extends Node

const MASK_CLASS = preload("res://Mask.tscn")
const MASKED_CLASS = preload("res://Masked.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

enum maskTypes {NONE = -1, MASK, MASKED}

func createMasking(maskType:int, layer:int):
	var node = null
	if maskType == maskTypes.MASK:
		node = MASK_CLASS.instance()
	elif maskType == maskTypes.MASKED:
		node = MASKED_CLASS.instance()
	if node:
		node.changeMaskingLayer(layer)
	return node

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
