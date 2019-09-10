extends "res://addons/gut/test.gd"

var _character_agency = preload("res://Scene/Game Phases/Character Stage/CharacterAgency.gd").new()

func before_all():
	gut.p("Starting Character Agency unit tests", 2)

func before_each():
	_character_agency.clear_characters()

var char_list:Array = [load("res://Testing/unit/test characters profiles/Princess Nectarine.tres"),
	load("res://Testing/unit/test characters profiles/Rozalin.tres"),
	load("res://Testing/unit/test characters profiles/Princess Rose.tres")]

func test_character_added():
	gut.p("Adding characters: ", 2)
	for character in char_list:
		_character_agency.add_character(character)
		var char_name:String = character.get_name()
		gut.p("%s" % char_name, 0)
		assert_true(_character_agency.has_character(char_name))
	assert_eq(_character_agency.get_character_count(), 3)

func test_get_character_by_id():
	for character in char_list:
		_character_agency.add_character(character)
	assert_eq(_character_agency.get_character_by_id(0), char_list[0])
	assert_eq(_character_agency.get_character_by_id(1), char_list[1])
	assert_eq(_character_agency.get_character_by_id(2), char_list[2])

func test_characters_removed():
	gut.p("Removing characters", 2)
	_character_agency.add_character(char_list[0])
	_character_agency.clear_characters()
	assert_eq(_character_agency.get_character_count(), 0)

func test_remove_character():
	_character_agency.clear_characters()
	_character_agency.add_character(char_list[0])
	_character_agency.add_character(char_list[1])
	_character_agency.add_character(char_list[2])
	_character_agency.remove_character(1)
	gut.p("Checking that the id lookup was updated", 1)
	assert_true(_character_agency.has_character(char_list[0].get_name()))
	assert_false(_character_agency.has_character(char_list[1].get_name()))
	assert_true(_character_agency.has_character(char_list[2].get_name()))
	assert_eq(_character_agency.get_character_by_id(0).get_name(), char_list[0].get_name())
	assert_eq(_character_agency.get_character_by_id(1).get_name(), char_list[2].get_name())

var char_list2:Array = [preload("res://Testing/unit/test characters profiles/Princess Nectarine.tres"),
	load("res://Testing/unit/test characters profiles/Rozalin.tres"),
	load("res://Testing/unit/test characters profiles/Princess Rose.tres"),
	load("res://Testing/unit/test characters profiles/Stupid character.tres")]

func test_character_name_limit():
	gut.p("Testing name limit, currently at %d characters" % _character_agency.get_max_name_length())
	for character in char_list2:
		_character_agency.add_character(character)
		gut.p("%s, length %d" % [character.get_name(), character.get_name_length()], 0)
	assert_eq(_character_agency.get_character_count(), 3)
