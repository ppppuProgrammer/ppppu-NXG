extends "res://UI/Nodes/AnimationGraphNode.gd"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#var 
#var node:AnimationNodeOutput = AnimationNodeOutput.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func setOutputNode(output:AnimationNodeOutput):
	animation_node = output
	#var blend_tree:AnimationNodeBlendTree = get_parent().get_blend_tree()
	#animation_node = blend_tree.get_node("output")
	#agnType = _gnTypes.OUTPUT
	#node.connect
func process_node_names(animPlayer, data):
	if data.has(0):
		return data[0]
	else:
		return []
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#node.process()
