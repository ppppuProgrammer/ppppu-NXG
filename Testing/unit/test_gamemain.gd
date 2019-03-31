extends "res://addons/gut/test.gd"

func before_all():
	gut.p("Starting Game Main unit tests", 2)
	
func test_set_game_world_phase():
	gut.p("Setting phase for game world", 1)
	var game_main:Node = load("res://Main/Game_Main.tscn").instance()
	add_child(game_main)
	var phase:Node2D = Node2D.new()
	phase.name = "New Phase"
	game_main.set_game_phase(phase)
	gut.p("Testing that phase was added to world scene", 1)
	assert_eq(phase, game_main.world.get_child(0))
	gut.p("Testing that game world has 1 phase", 1)
	assert_eq(game_main.world.get_child_count(), 1)
	gut.p("Testing that world cached current phase", 1)
	assert_not_null(game_main.world._current_phase)
	
	