tool
extends Node2D

#Extended Node2D
#Allows finer control over the matrix used to transform nodes.
#Do not use a Node2D's rotation, position and scale properties
export var exnSkew = Vector2(0,0) setget _setSkew#:Vector2
# x scale and y skew
var workX= Vector2(0,0)#:Vector2
#x skew and y scale
var workY= Vector2(0,0)#:Vector2
export var exnScale = Vector2(1,1) setget _setScale
export var exnPos = Vector2(0,0) setget _setPos
#export var RotDeg = 0 setget _setRot
export var tr = Transform2D()#:Transform2D
# Called when the node enters the scene tree for the first time.
var recalcTransform = false
func _ready():
	tr = self.transform
	#$AnimationPlayer.play("hand")

func _setPos(posVector2):
	exnPos = posVector2
	position = posVector2
	recalcTransform = true
	
#func _setRot(degrees):
#	RotDeg = degrees
#	_setSkew(Vector2(degrees, degrees))
	
func _setSkew(skewVector2):
	exnSkew = skewVector2
	recalcTransform = true

func _setScale(scaleVector2):
	exnScale = scaleVector2
	scale = scaleVector2
	recalcTransform = true

func _process(delta):
	tr = self.transform
	if recalcTransform:
		var oldPos = tr.get_origin()
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
	#workY = 
	
	#print(tr)
	#print(Transform2D(tr))
	#self.transform = Transform2D(tr)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
