extends Node2D

# A node that will hold various sprite nodes to complete a variant
# of a character part.
export var variantName:String = "Default" setget , _getVariantName
export var gradientData:Dictionary
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _getVariantName():
	return variantName

func changeLightMask(layer:int):
	for child in get_children():
		child.light_mask = 1 << layer
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
