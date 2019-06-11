extends "res://addons/gut/test.gd"

var _partFactory:CharacterPartFactory
var _headwear:PackedScene = preload("res://Char Parts/Headwear.tscn")
func before_all():
	_partFactory = CharacterPartFactory.new()
	
func after_all():
	_partFactory.free()
	
func test_partRegistration():
	gut.p("Testing that registration will fail when given an invalid packed scene")
	var bad_part:PackedScene = load("res://Testing/unit/test_CharParts/InvalidCharPart.tscn")
	assert_false(_partFactory.registerPart(bad_part))
	gut.p("Registrating valid character part")
	assert_true(_partFactory.registerPart(_headwear))
	gut.p("Testing that an instance of a part can be created")
	assert_not_null(_partFactory.createPart("Headwear"))
	