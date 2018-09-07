#tool
extends Light2D

#Node that setups its parent so it can be a masking object.

const CHARPART_CLASS = preload("res://Char Parts/CharacterPart.gd")
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	var parent = get_parent()
	if parent is CHARPART_CLASS:
		parent.connect("sig_spriteSceneChanged", self, "_setMaskTexture")
		parent.connect("sig_removeMasking", self, "_handleRemoval")
		#parent.setVisibility(false)
		var texList = parent.get_textures_in_use(CHARPART_CLASS.MAIN)
		if texList and texList.size() > 0:
			var maskSprite = texList[0]
			texture = maskSprite.texture

func changeMaskingLayer(layer:int):
	range_item_cull_mask = 1 << layer

func _setMaskTexture(caller, layer, node):
	#Masks must be in the main layer.
	if layer == CHARPART_CLASS.MAIN:
		var texList = caller.get_textures_in_use(layer)
		if texList and texList.size() > 0:
			var maskSprite = texList[0]
			texture = maskSprite.texture
			offset = maskSprite.offset * maskSprite.scale
			texture_scale = maskSprite.scale.x
			caller.setVisibility(false)
		else:
			texture = null
			caller.setVisibility(true)

func _handleRemoval():
	var parent = get_parent()
	parent.disconnect("sig_spriteSceneChanged", self, "_setMaskTexture")
	parent.disconnect("sig_removeMasking", self, "_handleRemoval")
	
	queue_free()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
