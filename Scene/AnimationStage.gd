extends Node2D

#Animation Stage is where all the action happens.
#Here is where the Character Parts are placed and animated.
const CHARPART_CLASS = preload("res://Char Parts/CharacterPart.gd")

var maskFactory = preload("res://Utility/MaskingFactory.gd").new()
const CHAR_PART_PATH = "res://Char Parts/"

var _standbyCharParts = {}
var _activeCharParts = {}

onready var _masterPlayer:AnimationPlayer = $AnimationPlayer
onready var _animTree = $AnimationTree
const AnimationEditor = preload("res://UI/Animation Editor.gd")
onready var _graph:AnimationEditor = $GraphLayer/Graph
func _ready():
	Log.append("Initializing Animation Stage")
	#Set up the Animation Editor Graph
	_graph.setup(_masterPlayer)
	_graph.connect("blend_tree_connection_changed", self, "_update_activated_character_parts")
	_graph.connect("update_character_parts", self, "_update_activated_character_parts")
	_graph.connect("connected_nodes", _animTree, "connect_animation_nodes")
	_graph.connect("disconnected_nodes", _animTree, "disconnect_animation_nodes")
	_graph.connect("added_node", _animTree, "add_animation_node")
	_graph.connect("output_graph_node_added", _animTree, "setup_output_graph_node")
	
	#Create character parts for animations currently in the master player
	for animationName in _masterPlayer.get_animation_list():
		var animation:Animation = _masterPlayer.get_animation(animationName)
		Log.append("Adding animation (%s)" % animationName)
		for i in range(0, animation.get_track_count()):
			var partNames = deduceCharPartNames(animation.track_get_path(i))
		
			if not partNames[1] in _standbyCharParts:
				var createdPart:Node2D = createCharacterPart(partNames)
				if createdPart:
					add_child(createdPart)
					deactivate_character_part(partNames[1])

#Returns an array with 2 values, the first is base character part name, which is what the tscn for the part is named. 
#The second is being the full name of the char part as it will be referred to in the animation page or current character page.
func deduceCharPartNames(animTrackNodePath:String):
	var fullPartName:String = animTrackNodePath.split(":", false, 1)[0]
	#Here for future proofing
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_key_pressed(KEY_A):
		_animTree.active = true
	elif Input.is_key_pressed(KEY_D):
		_animTree.active = false
	elif Input.is_action_just_pressed("debug_print_graph"):
		_graph.get_names_of_animated_nodes()
	
func _update_activated_character_parts():
	_animTree.active = false
	deactivate_all_parts()
	for node in _graph.get_names_of_animated_nodes():
		activate_character_part(node)
	_animTree.active = true

func deactivate_all_parts():
	for partName in _activeCharParts.keys():
		deactivate_character_part(partName)

func deactivate_character_part(partName:String):
	var charPart = null
	if partName in _activeCharParts:
		charPart = _activeCharParts[partName]
		_activeCharParts.erase(partName)
	else:
		charPart = get_node(partName)
	if charPart:
		_standbyCharParts[partName] = charPart
		charPart.visible = false
		charPart.set_process(false)

func debug_activate_all():
	for partName in _standbyCharParts.keys():
		activate_character_part(partName)

func activate_character_part(partName:String):
	var charPart = null
	if partName in _standbyCharParts:
		charPart = _standbyCharParts[partName]
		_standbyCharParts.erase(partName)
	else:
		charPart = get_node(partName)
	if charPart:
		_activeCharParts[partName] = charPart
		charPart.set_process(true)

func setDefaultTextures():
	for child in self.get_children():
		if child is CHARPART_CLASS:
			child.mainTexId = 0

func _on_Show_Graph_toggled(button_pressed):
	_graph.visible = button_pressed


func _on_Reset_pressed():
	_animTree.active = !true
	_animTree.active = true
