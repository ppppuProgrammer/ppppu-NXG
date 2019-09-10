extends "res://UI/Nodes/AnimationGraphNode.gd"

onready var animSelect:MenuButton = $SelectList

func _ready():
	#Create the animation node if it one wasn't set during creation
	if not animation_node:
		animation_node = AnimationNodeAnimation.new()
		
	#Check to see if an animation has already set and
	#needs to be selected
	if not animation_node.animation.empty():
		var idx:int = animSelect.get_popup().items.find(animation_node.animation)
		if idx > -1:
			animSelect.get_popup()
	var animEditor = get_parent()
	var selectPopup = animSelect.get_popup()
	selectPopup.connect("index_pressed", self, "on_anim_select_index_pressed")
	animEditor.connect("new_animation_added", self, "add_animation_name")
	for animName in animEditor.get_animation_names_list():
		selectPopup.add_item(animName)

func set_initial_settings(initialSettings:Dictionary = {}):
	if not initialSettings.empty():
		animation_node = initialSettings["animation_node"]
		initialSettings.erase("animation_node")
		for property in initialSettings:
			var property_value = initialSettings[property]
			animation_node.set(property, property_value)
			if property == "animation":
				var selectPopup = animSelect.get_popup()
				for itemIdx in range(selectPopup.get_item_count()):
					if property_value == selectPopup.get_item_text(itemIdx):
						animSelect.text = property_value
						break
				

func on_anim_select_index_pressed(index):
	animSelect.text = animSelect.get_popup().get_item_text(index)
	(animation_node as AnimationNodeAnimation).set_animation(animSelect.text)
	emit_signal("activate_char_parts_request")
	
func add_animation_names_from_list(list):
	pass
	
func add_animation_name(name):
	animSelect.add_item(name)

func process_node_names(animPlayer:AnimationPlayer, data):
	#.process_node_names(animPlayer, data)
	var nodesUsed:Array = []
	var animName:String = animation_node.animation
	if animPlayer.has_animation(animName):
		var anim:Animation = animPlayer.get_animation(animName)
		if anim:
			for trackIdx in anim.get_track_count():
				var nodeName:String = anim.track_get_path(trackIdx).get_name(0)
				if not nodeName in nodesUsed:
					nodesUsed.append(nodeName)
	return nodesUsed

func process_node_paths(animPlayer:AnimationPlayer, data, baseNameOnly:bool):
	var nodesUsed:Array = []
	var animName:String = animation_node.animation
	if animPlayer.has_animation(animName):
		var anim:Animation = animPlayer.get_animation(animName)
		if anim:
			for trackIdx in anim.get_track_count():
				var nodePath:String = anim.track_get_path(trackIdx).get_name(0) if baseNameOnly else anim.track_get_path(trackIdx)
				if not nodePath in nodesUsed:
					nodesUsed.append(nodePath)
	return nodesUsed
