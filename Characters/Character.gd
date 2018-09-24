extends Resource

#const ERROR_GRADIENT:Resource = preload("res://Characters/Color Presets/unset_gradient.tres")

export var character_name:String = ""
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
export var default_color_settings:Dictionary = {}
#How many times a sound effect for the character should be played.
#Silent is never, rarely is once per loop, occasionally is every 2 seconds
#frequently is every second, excessive is every 1/2 second
enum Frequency {SILENT, RARELY, OCCASIONALLY, FREQUENTLY, EXCESSIVE}
export (Frequency) var talkative_frequency
