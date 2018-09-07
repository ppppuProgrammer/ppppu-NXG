extends "res://UI/Nodes/AnimationGraphNode.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func setOutputNode(output:AnimationNodeOutput):
	animation_node = output

func process_node_names(animPlayer, data):
	if data.has(0):
		return data[0]
	else:
		return []
