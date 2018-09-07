extends "res://UI/Nodes/AnimationGraphNode.gd"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var animSelect:MenuButton = $SelectList
#var node:AnimationNodeAnimation = AnimationNodeAnimation.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_node = AnimationNodeAnimation.new()
	#print(animation_node)
	#agnType = _gnTypes.ANIMATION
	var animEditor = get_parent()
	var selectPopup = animSelect.get_popup()
	selectPopup.connect("index_pressed", self, "on_anim_select_index_pressed")
	animEditor.connect("new_animation_added", self, "add_animation_name")
	for animName in animEditor.get_currently_loaded_animation_names():
		selectPopup.add_item(animName)

func on_anim_select_index_pressed(index):
	animSelect.text = animSelect.get_popup().get_item_text(index)
	(animation_node as AnimationNodeAnimation).set_animation(animSelect.text)
	#animation_node.set_parameter("animation", animSelect.text)
	#print(animation_node)
	#print(animation_node.get_parameter("animation"))
	
func add_animation_names_from_list(list):
	pass
	
func add_animation_name(name):
	animSelect.add_item(name)
	
func process_node_names(animPlayer:AnimationPlayer, data):
	.process_node_names(animPlayer, data)
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
	#print(nodesUsed)
	#
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
