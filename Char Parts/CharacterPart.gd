tool
extends Node2D
class_name CharacterPart

export var initLoadTextures = PoolStringArray()
export var initLoadDecalTextures = PoolStringArray()
#export var initLoadUnderTextures = PoolStringArray()
#export var initLoadDecalTextures = PoolStringArray()
var _mainTextures = []
var _decalTextures = []
#var _overTextures = []
#var _underTextures = []
export var mainTexId:int = -1 setget _setMainTex
export var decalTexId:int = -1 setget _setDecalTex
#export var underTexId:int = -1 setget _setUnderTex
#Dictionaries to find the id of a variant's name
var _variantLookup_main:Dictionary = {}
#var _variantLookup_over:Dictionary = {}
#var _variantLookup_under:Dictionary = {}
var _variantLookup_decal:Dictionary = {}
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
#export var exnRot = 0.0 setget _setRot
export var _tr = Transform2D() setget _setTr#:Transform2D
### Extended Node2D (EXN) properties END ###
onready var _mainSprite = $Main
onready var _decalSprite = $Decal
#onready var _underSprite = $Underlay
#var _spritesInUse = Array().resize(3)
#enum layers {UNDER = -1, MAIN, OVER }
enum layers {MAIN, OVER }
### Masking properties START ###

### Masking properties END ###
#onready var AnimPlayer = $AnimationPlayer
#Flag to indicate if the transform needs to be recalculated
var recalcTransform = false
var _validateOK = false
signal sig_spriteSceneChanged(emitter, layer, spriteNode)


func _ready():
	_variantLookup_main["None"] = -1
	_variantLookup_decal["None"] = -1
#	_variantLookup_over["None"] = -1
#	_variantLookup_under["None"] = -1
	_tr = self.transform
	_loadTextures(initLoadTextures, _mainTextures)
	_loadTextures(initLoadDecalTextures, _decalTextures)
	#_loadTextures(initLoadDecalTextures, _overTextures, _variantLookup_over)
	#_loadTextures(initLoadUnderTextures, _underTextures, _variantLookup_under)
	_validateOK = true
	_setMainTex(mainTexId)
	_setDecalTex(decalTexId)
	#_setUnderTex(underTexId)

### Animation related START ###

### Animation related END ###

### Texture related START ###
func _loadTextures(texPathList:Array, layer:int):
	for texPath in texPathList:
		var tex = load(texPath)
		if tex:
			var charSprite = tex.instance()
			add_texture(layer, charSprite)

func add_texture(layer:int, charSprite)->int:
	var textureList:Array = []
	var lookupDict:Dictionary = {}
	if layer == layers.MAIN:
		textureList = _mainTextures
		lookupDict = _variantLookup_main
	if layer == layers.OVER:
		textureList = _decalTextures
		lookupDict = _variantLookup_decal
	if not charSprite.variantName in lookupDict.keys():
		var spriteId:int = textureList.size()
		lookupDict[charSprite.variantName] = spriteId
		textureList.append(charSprite)
		return spriteId
	return -1
	
		

# To be called by animations to control what variant to use.
func setVariantByName(layer, variantName):
	if layer == layers.MAIN:
		_setMainTexByVariant(variantName)
	elif layer == layers.OVER:
		_setDecalTexByVariant(variantName)
	#elif layer == layers.UNDER:
#		_setUnderTexByVariant(variantName)

func _setMainTexByVariant(variantName):
	if _variantLookup_main.has(variantName):
		mainTexId = _variantLookup_main[variantName]
		_setTexture(mainTexId, _mainTextures, _mainSprite)
	else:
		# Instead of using -1 should have another value used to 
		# indicate that the texture couldn't be loaded
		mainTexId = -1
	emit_signal("sig_spriteSceneChanged", self, layers.MAIN, _mainSprite)

func _setMainTex(texId):
	#if mainTexId != texId:
	mainTexId = _validateTexId(texId, _mainTextures)
	_setTexture(mainTexId, _mainTextures, _mainSprite)
	emit_signal("sig_spriteSceneChanged", self, layers.MAIN, _mainSprite)

func _setDecalTexByVariant(variantName):
	if _variantLookup_decal.has(variantName):
		decalTexId = _variantLookup_decal[variantName]
		_setTexture(decalTexId, _decalTextures, _decalSprite)
	else:
		decalTexId = -1
	emit_signal("sig_spriteSceneChanged", self, layers.OVER, _decalSprite)

func _setDecalTex(texId):
	#if decalTexId != texId:
	decalTexId = _validateTexId(texId, _decalTextures)
	_setTexture(decalTexId, _decalTextures, _decalSprite)
	emit_signal("sig_spriteSceneChanged", self, layers.OVER, _decalSprite)
	
#func _setUnderTexByVariant(variantName):
#	if _variantLookup_decal.has(variantName):
#		underTexId = _variantLookup_decal[variantName]
#		_setTexture(underTexId, _decalTextures, _decalSprite)
#	else:
#		underTexId = -1
#	emit_signal("sig_spriteSceneChanged", self, layers.UNDER, _underSprite)	
#
#func _setUnderTex(texId):
#	#vv is commented due to conflicts with node ready order
#	#if underTexId != texId:
#	underTexId = _validateTexId(texId, _decalTextures)
#	_setTexture(underTexId, _decalTextures, _underSprite)
#	emit_signal("sig_spriteSceneChanged", self, layers.UNDER, _underSprite)
	
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
	if layer == layers.MAIN and _mainSprite:
		textures = _mainSprite.get_used_textures_list()
	elif layer == layers.OVER and _decalSprite:
		textures = _decalSprite.get_used_textures_list()
#	elif layer == layers.UNDER and _underSprite:
#		textures = _underSprite.get_used_textures_list()
	return textures
	
### Texture related END ###

func setAnimPlayPosition(time):
	$AnimationPlayer.seek(time, true)

### Transform related START ###
func _setPos(posVector2):
	exnPos = posVector2
	position = posVector2
	recalcTransform = true
	
func _setSkew(skewVector2):
	exnSkew = skewVector2
	#rotation = skewVector2.x
	#exnRot = exnSkew.x
	recalcTransform = true

func _setScale(scaleVector2):
	exnScale = scaleVector2
	scale = scaleVector2
	recalcTransform = true
	
#func _setRot(rotDegrees):
#	exnRot = rotDegrees
#	exnSkew = Vector2(rotDegrees, rotDegrees)
#	#rotation = rotDegrees
#	recalcTransform = true
### Transform Related END ###

func setVisibility(visibility):
#	if _underSprite:
#		_underSprite.visible = visibility
	if _decalSprite:
		_decalSprite.visible = visibility
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