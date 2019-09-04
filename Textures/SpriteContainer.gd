extends Node2D
class_name CharacterSpriteContainer
# A node that will hold various sprite nodes to complete a variant
# of a character part.
export var variantName:String = "Default" setget , _getVariantName
#Due to how packed scenes are stored, the target layer default value must be something other
#than values that are intended to be used. This is important because the character part factory
#looks at packed scenes for this class and default values are not stored within packed scenes states.
#Also don't want to assume that the target_layer property exists, it must be verified that it exists.
export (CharacterPart.layers) var target_layer
#export var gradientData:Dictionary
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
