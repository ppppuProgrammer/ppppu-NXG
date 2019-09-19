extends Node
class_name Character

var _profile:CharacterProfile

var _standbyCharParts = {}
var _activeCharParts = {}
var _activePartListing = {}
var _addPartQueue = []

var _addQueueMutex:Mutex = Mutex.new()
onready var _anim_player:AnimationPlayer = $AnimationPlayer #setget ,get_anim_player
onready var _animTree:CharacterAnimationTree = $CharacterAnimationTree #setget ,get_animation_tree

var _send_task_for_parts_creation:FuncRef

onready var parts_root:Node = $Parts
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

func _ready() -> void:
	_animTree.traverse_animationtree()

func setup(part_create_func:FuncRef) -> void:
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
				parts_root.add_child(char_part)
			_addQueueMutex.unlock()

func add_animation(animation:Animation)->bool:
	if !_anim_player.has_animation(animation.resource_name):
		var add_status:int = _anim_player.add_animation(animation.resource_name, animation)
		if add_status == OK:
			return true
	return false

func update_parts_used():
	var parts_requirements:Dictionary = _get_parts_needed_for_current_animation()
	var deactivate_queue:Array
	var recycle_candidates:Dictionary
	#Try to recycle as many currently created parts as possible.
	#Go through all currently active parts, checking to see if the type and name match
	#what's in the requirement dictionary. If both type and name match, use it as it is.
	#If only type matches, then rename the part that'd otherwise be unused
	for active_part_type in _activeCharParts.keys():
		if not active_part_type in parts_requirements.keys():
			for part_to_deactive in _activeCharParts[active_part_type]:
				deactivate_queue.append(part_to_deactive)
		else:
			for part_to_evaluate in _activeCharParts[active_part_type]:
				if part_to_evaluate.name in parts_requirements[active_part_type]:
					#Can use the active part as is, remove from the requirements
					parts_requirements[active_part_type].remove(parts_requirements[active_part_type].find(part_to_evaluate.name))
				else:
					pass
			
	deactivate_character_parts(deactivate_queue)

func deactivate_character_parts(parts:Array)->void:
	pass

func get_active_parts_listing()->Dictionary:
	return _activePartListing

func _get_parts_needed_for_current_animation()->Dictionary:
	return _animTree.get_part_requirments_for_current_animation()

func start_animation_playback():
	if !_animTree.active:
		_animTree.active = true
	update_parts_used()
	
		#var needs = _animTree.get_track_requirements()
		
