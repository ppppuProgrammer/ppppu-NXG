extends "res://addons/gut/test.gd"

const gmain_class = preload("res://Main/Game_Main.gd")
var game_main:GameMain
var char_phase:GamePhase = preload("res://Scene/Game Phases/Character Stage Phase.tres")
var char_stage:CharacterStage
var _char_stage_gui
const test_slot_name:String = "test slot"
var anim_repo:AnimationRepository

func before_all():
	gut.p("Starting Animation unit tests", 2)
	anim_repo = AnimationRepository.new()
	

	
func test_basic_functionality():
	var test_anim:CharacterAnimationElement = load("res://Testing/unit/Test animations/1_Cowgirl Large Test.tres")
	gut.p("Testing add animation failure if slot doesn't exist")
	anim_repo.AddChanele(test_anim)
	assert_eq(anim_repo.GetChaneleCountForSlot("test slot"), 0)
	gut.p("Testing slot creation")
	anim_repo.AddAnimationSlot(test_slot_name)
	assert_true(anim_repo.HasAnimationSlot(test_slot_name))
	gut.p("Testing add animation success")
	anim_repo.AddChanele(test_anim)
	assert_true(anim_repo.HasChanele(test_slot_name, "Large"))

func test_overwriting():
	gut.p("Making sure animations can not be overwritten")
	var test_anim:CharacterAnimationElement = load("res://Testing/unit/Test animations/1_Cowgirl Large Test.tres")
	var test_anim_overw:CharacterAnimationElement = load("res://Testing/unit/Test animations/1_Cowgirl Large overwrite Test.tres")
	var track_count:int = test_anim.get_track_count()
	var track_count2:int = test_anim_overw.get_track_count()
	gut.p("Animation track count: test_anim: %d, test_anim_overw: %d" % [track_count, track_count2])
	assert_false(anim_repo.AddChanele(test_anim_overw))
	#assert_eq(anim_repo._repository[test_slot_name][test_anim.animation_name].get_track_count(), track_count)

func after_all():
	anim_repo.free()

func before_each():
	pass
