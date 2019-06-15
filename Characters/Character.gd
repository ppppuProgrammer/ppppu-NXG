extends Node
class_name Character

var _profile:CharacterProfile

var _standbyCharParts = {}
var _activeCharParts = {}

onready var _anim_player:AnimationPlayer = $AnimationPlayer #setget ,get_anim_player
onready var _animTree:CharacterAnimationTree = $CharacterAnimationTree #setget ,get_animation_tree
var _partFactory:CharacterPartFactory

#func get_animation_tree() -> CharacterAnimationTree:
#	return _animTree