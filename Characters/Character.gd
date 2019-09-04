extends Node
class_name Character

var _profile:CharacterProfile

var _standbyCharParts = {}
var _activeCharParts = {}
var _addPartQueue = []

var _addQueueMutex:Mutex = Mutex.new()
onready var _anim_player:AnimationPlayer = $AnimationPlayer #setget ,get_anim_player
onready var _animTree:CharacterAnimationTree = $CharacterAnimationTree #setget ,get_animation_tree

var _send_task_for_parts_creation:FuncRef

###
#Used for the algorithm of keeping character parts from stalling
#the program when many of them are added to the scene tree on the
#same frame.
###

const minimum_parts_added_on_update:int = 2
const max_time_tolerance_for_adding_parts:float = (1.0/60.0) * 0.85
const part_increment_amount:int = 2
const stall_prevention_factor:float = 0.4
var parts_to_add_on_update:int = 5
var time_for_last_part_add:float = 0
#func get_animation_tree() -> CharacterAnimationTree:
#	return _animTree

func _init(part_create_func:FuncRef) -> void:
	_send_task_for_parts_creation = part_create_func

func add_character_parts(char_parts:Array)->void:
	_addQueueMutex.lock()
	for char_part in char_parts:
		if char_part is CharacterPart:
			_addPartQueue.append(char_part)
	_addQueueMutex.unlock()
	
func _process(delta:float)->void:
	if _addPartQueue.size() > 0:
		if _addQueueMutex.try_lock() == OK:
			if delta < max_time_tolerance_for_adding_parts:
				parts_to_add_on_update += part_increment_amount
			else:
				parts_to_add_on_update = int(max(minimum_parts_added_on_update,
						parts_to_add_on_update * stall_prevention_factor))
			for i in range(0, parts_to_add_on_update):
				var char_part:CharacterPart = _addPartQueue.pop_front()
				self.add_child(char_part)
			_addQueueMutex.unlock()
