extends Node2D

#Animation Stage is where all the action happens.
#Here is where the Character Parts are placed and animated.
const CHARPART_CLASS = preload("res://CharacterPart.gd")

var maskFactory = preload("res://MaskingFactory.gd").new()
const CHAR_PART_PATH = "res://Char Parts/"
# Called when the node enters the scene tree for the first time.
var _standbyCharParts = {}
var _activeCharParts = {}
#var _animationPartsCache = {}
onready var _masterPlayer:AnimationPlayer = $AnimationPlayer
func _ready():
	#_masterPlayer.connect("animation_changed", self, "_animation_was_changed")
	#Create character parts for animations currently in the master player
	for animationName in _masterPlayer.get_animation_list():
		#if not animationName in _animationPartsCache:
		#	_animationPartsCache[animationName] = []
		var animation:Animation = _masterPlayer.get_animation(animationName)
		for i in range(0, animation.get_track_count()):
			var partNames = deduceCharPartNames(animation.track_get_path(i))
			#if not partNames[1] in _animationPartsCache[animationName]:
			#	_animationPartsCache[animationName].append(partNames[1])
			if not partNames[1] in _standbyCharParts:
				var createdPart:Node2D = createCharacterPart(partNames)
				if createdPart:
					_standbyCharParts[partNames[1]] = createdPart

#Returns an array with 2 values, the first is base character part name, which is what the tscn for the part is named. 
#The second is being the full name of the char part as it will be referred to in the animation page or current character page.
func deduceCharPartNames(animTrackNodePath:String):
	var fullPartName:String = animTrackNodePath.split(":", false, 1)[0]
	#Here just in case
	#fullPartName = fullPartName.lstrip("./")
	#Check for left parenthesis "(" since that means that the current node path is for a variant.
	var variantStartIdx = fullPartName.rfind(" (")
	
	var basePartName:String = fullPartName.substr(0, variantStartIdx if variantStartIdx > -1 else fullPartName.length())
	return [basePartName, fullPartName]

func createCharacterPart(charPartNamePair:Array):
	var charClass = load(CHAR_PART_PATH + charPartNamePair[0] +  ".tscn")
	var charPart = null
	if charClass:
		charPart = charClass.instance()
		charPart.registerMaskingFactory(maskFactory)
		charPart.name = charPartNamePair[1]
	return charPart


func changeAnimation(newName:String):
	#_animationPartsCache[newName]
	#Do this the long (unoptimized) way until it is ensured that 
	#Animation Trees modify the Animation Player
	for activeNodeName in _activeCharParts.keys():
		var activeNode = get_node(activeNodeName)
		remove_child(activeNode)
		_standbyCharParts[activeNodeName] = activeNode
		_activeCharParts.erase(activeNodeName)
	var animation:Animation = _masterPlayer.get_animation(newName)
	for i in range(0, animation.get_track_count()):
		var partNames = deduceCharPartNames(animation.track_get_path(i))
		var fullName = partNames[1]
		if fullName in _standbyCharParts:
			add_child(_standbyCharParts[fullName])
			_activeCharParts[fullName] = _standbyCharParts[fullName]
			_standbyCharParts.erase(fullName)
	
	setDefaultTextures()
	_masterPlayer.assigned_animation = newName
	_masterPlayer.play(newName)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_key_pressed(KEY_T):
		setDefaultTextures()

func setDefaultTextures():
	for child in self.get_children():
		if child is CHARPART_CLASS:
			child.mainTexId = 0