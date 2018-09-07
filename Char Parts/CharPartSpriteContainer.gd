extends Node2D

# Simple class for the sprite holders of a character part
# Overrides Node2D functions to only allow 1 child


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here.
	if get_child_count() > 1:
		for child in get_children():
			.remove_child(child)
	
func add_child(node, legible_unique_name=false):
	if get_child_count() > 0:
		remove_child(node)
	.add_child(node, legible_unique_name)
	
#node parameter is intentionally there despite not being used
func remove_child(node):
	if get_child_count() > 0:
		.remove_child(get_child(0))
		
func get_used_textures_list():
	var texList = []
	if get_child_count() > 0:
		#The child node is expect to be a node2D type
		var textureRootNode = get_child(0)
		for spriteNode in textureRootNode.get_children():
			if spriteNode is Sprite:
				#Lazy, should have data (texture, offsets)
				#and not the node itself.
				texList.append(spriteNode)
	return texList
	
func changeChildLightMask(layer:int):
	for child in get_children():
		child.changeLightMask(layer)
		