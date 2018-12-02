extends Node2D

#Character screen is a node that can hold all parts necessary
#to display a character and animate them. 
#The primary purpose for handling characters like this
#is for animations that make use of multiple characters.

const CHARPART_CLASS = preload("res://Char Parts/CharacterPart.gd")

#var maskFactory = preload("res://Utility/MaskingFactory.gd").new()
const CHAR_PART_PATH = "res://Char Parts/"

var _standbyCharParts = {}
var _activeCharParts = {}

var _anim_player:AnimationPlayer = null# setget ,get_anim_player
const StageAnimationTree = preload("res://Scene/StageAnimationTree.gd")
var _animTree:StageAnimationTree = null setget ,get_animation_tree

#const AnimationEditor = preload("res://UI/Animation Editor.gd")
#onready var _graph:AnimationEditor = $GraphLayer/Graph

signal apply_palette_request

func _init(animation_list:Array) -> void:
	_anim_player = AnimationPlayer.new()
	_animTree = StageAnimationTree.new()
	_animTree.tree_root = AnimationNodeBlendTree.new()
	#_animTree.tree_root.connect("tree_changed", self, "_update_activated_character_parts")
	if _anim_player.get_animation_list().size() == 0:
		for anim in animation_list:
			_anim_player.add_animation(anim.resource_name, anim)
	_anim_player.name = "AnimationPlayer"
	add_child(_anim_player)
	add_child(_animTree)
	_animTree.anim_player = _animTree.get_path_to(_anim_player)

func _ready():
	#
	#Log.append("Initializing Animation Stage")
	#connect("blend_tree_connection_changed", self, "_update_activated_character_parts")
	#connect("update_character_parts", self, "_update_activated_character_parts")
	
	#Create character parts for animations currently in the master player
	for animationName in _anim_player.get_animation_list():
		var animation:Animation = _anim_player.get_animation(animationName)
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
		#charPart.registerMaskingFactory(maskFactory)
		charPart.name = charPartNamePair[1]
	return charPart

func update_parts(animated_parts_list:Array):
	_animTree.active = false
	deactivate_all_parts()
	for node in animated_parts_list:
		activate_character_part(node)
	_animTree.active = true
	emit_signal("apply_palette_request")
	
func _update_activated_character_parts(parts_list:Array):
	_animTree.active = false
	deactivate_all_parts()
#	for node in _graph.get_names_of_animated_nodes():
#	for node in parts_list:
#		activate_character_part(node)
	_animTree.active = true
	emit_signal("apply_palette_request")

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

func add_animation_to_player(animation:Animation) -> void:
	_anim_player.add_animation(animation.resource_name, animation)

#func add_animations_to_player(anim_list:Array) -> void:
	

#func _on_Show_Graph_toggled(button_pressed):
#	_graph.visible = button_pressed

func get_animation_player() -> AnimationPlayer:
	return _anim_player

func play_animation(start_time:float = 0.0):
	_animTree.active = true
	emit_signal("apply_palette_request")

func get_animation_tree() -> StageAnimationTree:
	return _animTree

func _on_Reset_pressed():
	_animTree.active = !true
	_animTree.active = true
	emit_signal("apply_palette_request")
