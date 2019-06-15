extends Resource
class_name CharacterProfile

#Class that holds data for character settings. CharacterProfile is to be used by modders
#for their character presets. CustomCharacterProfile is to be used whenever data for a character
#needs to be changed. 

#Increment whenever a breaking change is done
const PROFILE_VERSION:int = 1
var _saved_profile_version:int = -1

#const ERROR_GRADIENT:Resource = preload("res://Characters/Color Presets/unset_gradient.tres")

export var character_name:String = "" setget set_name, get_name

export var character_icon:Texture = null setget set_icon, get_icon
#A list of animation node blend trees that the character uses.
#var animation_trees:Array = []
#Array of strings containing the names of the animation trees the character has
#var animation_names:Array
#Array of bools telling if a particular animation tree can not be switched to
#var animation_locks:Array

#The name of the default song to use for the character.
export var character_music_name:String = ""
#var current_music_name:String = ""
#var pick_random_animation_on_finish:bool = true
#Settings for how color groups should be set for the character.
#Key is color group name and value is an 8 length array containing
#Gradient objects.
#color_settings should contain a reference to a Character Colors Set resource.
export var color_settings:Resource = null
#How many times a sound effect for the character should be played.
#Silent is never, rarely is once per loop, occasionally is every 2 seconds
#frequently is every second, excessive is every 1/2 second
enum Frequency {SILENT, RARELY, OCCASIONALLY, FREQUENTLY, EXCESSIVE}
export (Frequency) var talkative_frequency

#var _voice_bank:Resource

func set_icon(new_icon:Texture):
	pass

func get_icon()->Texture:
	return character_icon

func set_name(new_name:String):
	if character_name == "":
		character_name = new_name

func get_name()->String:
	return character_name

func get_name_length()->int:
	return character_name.length()
	
