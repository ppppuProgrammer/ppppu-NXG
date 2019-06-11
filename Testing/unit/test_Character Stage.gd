extends "res://addons/gut/test.gd"

const gmain_class = preload("res://Main/Game_Main.gd")
var game_main:GameMain
var char_phase:GamePhase = preload("res://Scene/Game Phases/Character Stage Phase.tres")
var char_stage:CharacterStage
var _char_stage_gui

func before_all():
	gut.p("Starting Character Stage unit tests", 2)
	game_main = load("res://Main/Game_Main.tscn").instance()
	add_child(game_main)
	game_main.set_game_phase(char_phase)
	#Force game phase change, which happens during game main's _process()
	simulate(game_main, 1, 1.0/60.0)
#	yield(game_main.world, "world_phase_changed")
	char_stage = char_phase.get_scene()
	_char_stage_gui = char_stage._gui
	char_stage.visible = false

func after_all():
	remove_child(game_main)
	game_main.queue_free()

func before_each():
	pass

var char_list:Array = [preload("res://Testing/unit/test characters/Princess Nectarine.tres"),
	preload("res://Testing/unit/test characters/Rozalin.tres"),
	preload("res://Testing/unit/test characters/Princess Rose.tres")]
func test_add_character():
#	yield(game_main.world, "world_phase_changed")
	assert_gt(
		char_stage.add_character(char_list[0]),
		-1)

func test_all_characters_removal():
	gut.p("Removing all characters", 1)
	char_stage.remove_all_characters()
	gut.p("Testing that character select bar has no buttons", 1)
	assert_eq(_char_stage_gui.get_character_buttons_count(), 0)

func test_gui_update_on_character_add():
	char_stage.remove_all_characters()
	char_stage.add_character(char_list[0])
	assert_eq(_char_stage_gui.get_character_buttons_count(), 1)

func test_character_removal():
	char_stage.remove_all_characters()
	char_stage.add_character(char_list[0])
	char_stage.add_character(char_list[1])
	char_stage.add_character(char_list[2])
	assert_eq(char_stage.get_character_count(), 3)
	assert_eq(_char_stage_gui.get_character_buttons_count(), 3)
	gut.p("Removing %s" % char_list[1].get_name())
	char_stage.remove_character(1)
	gut.p("Testing character count", 1)
#	assert_eq(char_stage.get_character_count(), 2)
	gut.p("Testing character buttons count", 1)
	assert_eq(_char_stage_gui.get_character_buttons_count(), 2)
#func test_ensure_gui_exists():
#	assert_not_null(char_stage._gui)