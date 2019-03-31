extends "res://addons/gut/test.gd"

var char_stage = preload("res://Scene/Game Phases/Character Stage/Character Stage.tscn").instance()

func before_all():
	gut.p("Starting Character Stage unit tests", 2)
	
func test_ensure_gui_exists():
	assert_not_null(char_stage._gui)