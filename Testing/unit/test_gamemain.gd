extends "res://addons/gut/test.gd"

#const gmain_class = preload("res://Main/Game_Main.gd")
var game_main:GameMain

func before_all():
	gut.p("Starting Game Main unit tests", 2)
	game_main = load("res://Main/Game_Main.tscn").instance()
	add_child(game_main)
	#Force game phase change, which happens during game main's _process()
	game_main.set_game_phase(null)
	simulate(game_main, 1, 1.0/60.0)
#	yield(game_main.world, "world_phase_changed")
	
func test_set_game_world_phase():
	gut.p("Setting phase for game world", 1)
	var phase:GamePhase = load("res://Testing/unit/Test Phase.tres")
	game_main.set_game_phase(phase)
	simulate(game_main, 1, 1.0/60.0)
#	yield(game_main.world, "world_phase_changed")
	gut.p("Testing that phase was added to world scene", 1)
	assert_eq(phase.get_scene(), game_main.world.get_child(0))
	gut.p("Testing that game world has 1 phase", 1)
	assert_eq(game_main.world.get_child_count(), 1)
	gut.p("Testing that world has cached current phase", 1)
	assert_not_null(game_main.world._current_phase)
	
func test_game_cleanup():
	game_main.add_scene_to_gui(Control.new())
	gut.p("Resetting game to a blank state", 1)
	game_main.clear_world_and_gui()
	simulate(game_main, 1, 1.0/60.0)
#	yield(game_main.world, "world_phase_changed")
	gut.p("Testing that current phase is null", 1)
	assert_eq("NULL", game_main.world.get_current_phase_name())
	gut.p("Testing that gui is empty", 1)
	assert_eq(game_main.gui.get_child_count(), 0)
	
func test_set_game_gui():
	gut.p("Setting gui for game", 1)
	var phase:GamePhase = load("res://Testing/unit/Test Phase.tres")
	game_main.set_game_phase(phase)
	
func after_all():
	gut.p("Finished testing Game Main", 2)
	remove_child(game_main)
	game_main.queue_free()
	gut.p("Removed game_main node", 1)
	