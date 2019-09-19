extends "res://addons/gut/test.gd"

var BTT_scene:Node = preload("res://Testing/unit/test Blend Tree Traversal/BTT Scene 1.tscn").instance()
var animation_player:AnimationPlayer = BTT_scene.get_node("AnimationPlayer")
var animNode_process_func_lookup:Dictionary = {"AnimationNodeAnimation": "_parse_AnimationNodeAnimation"}

func before_all():
	add_child(BTT_scene)
	
func after_all():
	remove_child(BTT_scene)
	BTT_scene.queue_free()
	
#func test_AnimTest():
#	var tree:CharacterAnimationTree = BTT_scene.get_node("AnimTest")
#
#	#var prop = tree.tree_root.get_property_list()
#	#print(prop)
#	#print(_get_blendtree_properties(tree.tree_root))
#	var tree_traversal_data:Dictionary = traverse_animationtree(tree)
#	#print(tree_traversal_data)
#	var anim:AnimationNodeAnimation = tree.tree_root.get_node("Animation")
#	gut.p("Testing that node \"Animation\" has traversal data")
#	assert_gt(tree_traversal_data[anim].size(), 1)
#	var output:AnimationNodeOutput = tree.tree_root.get_node("output")
#	gut.p("Testing that node \"Output\" has traversal data")
#	assert_gt(tree_traversal_data[output].size(), 1)
func test_InnerTreeTest():
	var tree_inner:CharacterAnimationTree = BTT_scene.get_node("InnerTreeTest")
	tree_inner.traverse_animationtree()
	gut.p("Testing that the traversal base path is empty on completion")
	assert_eq(tree_inner._traversal_current_base_path, "")
	

func test_Blend2Test():
	var tree_mixed:CharacterAnimationTree = BTT_scene.get_node("Blend2Test-Mixed")
#	print("Printing tree")
#	print(tree_mixed.print_tree())
#	print("Printing tree's property list")
#	print(tree_mixed.get_property_list())
	var tree_zero:CharacterAnimationTree = BTT_scene.get_node("Blend2Test-0")
	var tree_one:CharacterAnimationTree = BTT_scene.get_node("Blend2Test-1")
	
	print(tree_mixed.tree_root.get_parameter("Blend2/blend_amount"))
	#var prop = tree.tree_root.get_property_list()
	#print(prop)
	gut.p("(Blend2Test-0) Testing Blend2 at 0")
	
	gut.p("(Blend2Test-Mixed) Testing Blend2 at 0.5")
	#print(_get_blendtree_properties(tree_mixed.tree_root))
	var tree_traversal_data:Dictionary = tree_mixed.traverse_animationtree()
	#print(tree_traversal_data)
	var output:AnimationNodeOutput = tree_mixed.tree_root.get_node("output")
	#assert_gt(tree_traversal_data[output].size(), 1)
	
	gut.p("(Blend2Test-1) Testing Blend2 at 1")
	
