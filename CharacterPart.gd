tool
extends Node2D

export var initLoadTextures = PoolStringArray()
export var initLoadOverTextures = PoolStringArray()
export var initLoadUnderTextures = PoolStringArray()
var _mainTextures = []
var _overTextures = []
var _underTextures = []
export var mainTexId:int = -1 setget _setMainTex
export var overTexId:int = -1 setget _setOverTex
export var underTexId:int = -1 setget _setUnderTex

### Extended Node2D (EXN) properties START ###
#Allows finer control (skewing) of the matrix used to transform nodes.
#Do not use a Node2D's rotation, position and scale properties
export var exnSkew = Vector2(0,0) setget _setSkew#:Vector2
# x scale and y skew
var workX= Vector2(0,0)#:Vector2
#x skew and y scale
var workY= Vector2(0,0)#:Vector2
export var exnScale = Vector2(1,1) setget _setScale
export var exnPos = Vector2(0,0) setget _setPos
export var _tr = Transform2D() setget _setTr#:Transform2D
### Extended Node2D (EXN) properties END ###
onready var _mainSprite = $Main
onready var _overSprite = $Overlay
onready var _underSprite = $Underlay
#var _spritesInUse = Array().resize(3)
enum layers {MAIN = 0, OVER = 1, UNDER = -1}

### Masking properties START ###
#For quick setup. Later remove this from this file
var _maskFactory = null
var maskTypes

#The Mask type node that is being used to mask another Char Part
var _mask:Light2D = null
#The Masked type node that indicates that this Char Part is to be masked
var _masked:Node = null
### Masking properties END ###
#onready var AnimPlayer = $AnimationPlayer
#Flag to indicate if the transform needs to be recalculated
var recalcTransform = false
var _validateOK = false
signal sig_spriteSceneChanged(emitter, layer, spriteNode)
signal sig_removeMasking

func registerMaskingFactory(maskingFactory):
	_maskFactory = maskingFactory
	maskTypes = _maskFactory.maskTypes

func _ready():
	_tr = self.transform
	_validateOK = true
	_loadTextures(initLoadTextures, _mainTextures)
	_loadTextures(initLoadOverTextures, _overTextures)
	_loadTextures(initLoadUnderTextures, _underTextures)
	_setMainTex(mainTexId)
	_setOverTex(overTexId)
	_setUnderTex(underTexId)

### Animation related START ###
#Used to make the character part a mask, have it be masked, 
#or disable anything to do with masking.
func setupMasking(type:int, layer:int):
	if type == maskTypes.MASKED:
		if not _masked:
			_masked = _maskFactory.createMasking(type, layer)
			add_child(_masked)
		else:
			_masked.changeMaskingLayer(layer)
	elif type == maskTypes.MASK:
		if not _mask:
			_mask = _maskFactory.createMasking(type, layer)
			add_child(_mask)
		else:
			_mask.changeMaskingLayer(layer)
	elif type == maskTypes.NONE:
		emit_signal("sig_removeMasking")
### Animation related END ###

### Texture related START ###
func _loadTextures(texPathList, textureList):
	for texPath in texPathList:
		var tex = load(texPath)
		if tex:
			textureList.append(tex.instance())

func _setMainTex(texId):
	#if mainTexId != texId:
	mainTexId = _validateTexId(texId, _mainTextures)
	_setTexture(mainTexId, _mainTextures, _mainSprite)
	emit_signal("sig_spriteSceneChanged", self, MAIN, _mainSprite)
	
func _setOverTex(texId):
	#if overTexId != texId:
	overTexId = _validateTexId(texId, _overTextures)
	_setTexture(overTexId, _overTextures, _overSprite)
	emit_signal("sig_spriteSceneChanged", self, OVER, _overSprite)
	
func _setUnderTex(texId):
	#vv is commented due to conflicts with node ready order
	#if underTexId != texId:
	underTexId = _validateTexId(texId, _underTextures)
	_setTexture(underTexId, _underTextures, _underSprite)
	emit_signal("sig_spriteSceneChanged", self, UNDER, _underSprite)
	
func _validateTexId(texId, textureList):
	if !_validateOK:
		return texId
	if texId < -1:
		texId = -1
	elif texId >= textureList.size():
		texId = textureList.size() - 1
	return texId;
	
func _setTexture(texId, textureList, sprite):
	if sprite:
		#for x in range(sprite.get_child_count()-1, -1, -1):
		#	sprite.remove_child(sprite.get_child(x))
		
		#For post-May 3.1 git builds
		for child in sprite.get_children():
			sprite.remove_child(child)
		
		if texId > -1:
			sprite.add_child(textureList[texId])

func get_textures_in_use(layer):
	var textures = null
	if layer == MAIN and _mainSprite:
		textures = _mainSprite.get_used_textures_list()
	elif layer == OVER and _overSprite:
		textures = _overSprite.get_used_textures_list()
	elif layer == UNDER and _underSprite:
		textures = _underSprite.get_used_textures_list()
	return textures
### Texture related END ###

func changeLightMaskLayerForSprites(layer:int):
	_mainSprite.changeChildLightMask(layer)
	_overSprite.changeChildLightMask(layer)
	_underSprite.changeChildLightMask(layer)
	
func setAnimPlayPosition(time):
	$AnimationPlayer.seek(time, true)

### Transform related START ###
func _setPos(posVector2):
	exnPos = posVector2
	position = posVector2
	recalcTransform = true
	
func _setSkew(skewVector2):
	exnSkew = skewVector2
	recalcTransform = true

func _setScale(scaleVector2):
	exnScale = scaleVector2
	scale = scaleVector2
	recalcTransform = true
### Transform Related END ###

func setVisibility(visibility):
	if _underSprite:
		_underSprite.visible = visibility
	if _overSprite:
		_overSprite.visible = visibility
	if _mainSprite:
		_mainSprite.visible = visibility

func _process(delta):
	#_tr = self.transform
	if recalcTransform:
		#var oldPos = _tr.get_origin()
		var skewX_rad =  deg2rad(exnSkew.x)
		var skewY_rad =  deg2rad(exnSkew.y)
		#a
		workX.x = cos(skewY_rad) * exnScale.x
		#b
		workX.y = sin(skewY_rad) * exnScale.x
		#c
		workY.x = -sin(skewX_rad) * exnScale.y
		#d
		workY.y = cos(skewX_rad) * exnScale.y
		self.transform = Transform2D(workX, workY, exnPos)
		recalcTransform = false


func _setTr(tr):
	transform = tr