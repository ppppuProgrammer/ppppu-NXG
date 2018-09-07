extends Node2D


export var variantName:String = "Default" setget , _getVariantName

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
