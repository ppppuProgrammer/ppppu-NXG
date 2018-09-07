extends "res://UI/Nodes/AnimationGraphNode.gd"

onready var blendSlider:HSlider = $blend_amount/VBoxContainer/HSlider 

func _ready():
	animation_node = AnimationNodeBlend2.new()
	has_parameters = true

func process_node_names(animPlayer, data:Dictionary):
	.process_node_names(animPlayer, data)
	var activeNodes:Array = []
	
	if blendSlider.value == 0.0:
		#Use animation connected to "in" only
		if data.has(0):
			activeNodes = data[0]
	elif blendSlider.value == 1.0:
		#Use animation connected to "blend" only
		if data.has(1):
			activeNodes = data[1]
	else:
		#Use a mix of both the "in" and "blend" animations
		if data.has(1) and data.has(0):
			for node in data[0]:
				if not node in activeNodes:
					activeNodes.append(node)
			for node in data[1]:
				if not node in activeNodes:
					activeNodes.append(node)
	return activeNodes

func _on_HSlider_value_changed(value):
	emit_signal("parameter_changed", self.name, "blend_amount", value)
	#animation_node.set_parameter("blend_amount", value)  