extends "res://addons/gut/test.gd"

func test_CharAnimInitializes():
	var charAnim:CharacterAnimationElement = load("res://Characters/Animations/1_Cowgirl-Main.tres")
	assert_gt(charAnim.get_track_count(), 0)