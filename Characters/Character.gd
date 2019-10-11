extends Node
class_name Character

var _profile:CharacterProfile

var _standby_char_parts = {}
var _active_char_parts = {}
var _addPartQueue = []

var _addQueueMutex:Mutex = Mutex.new()
onready var _anim_player:AnimationPlayer = $AnimationPlayer #setget ,get_anim_player
onready var _animTree:CharacterAnimationTree = $CharacterAnimationTree #setget ,get_animation_tree

var _send_task_for_parts_creation:FuncRef
const _UNUSED_STR:String = "%s_UNUSED_%d"
onready var _parts_root:Node = $Parts
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
				_parts_root.add_child(char_part)
			_addQueueMutex.unlock()

func add_animation(animation:Animation)->bool:
	if !_anim_player.has_animation(animation.resource_name):
		var add_status:int = _anim_player.add_animation(animation.resource_name, animation)
		if add_status == OK:
			return true
	return false

func update_parts_used():
	var requirements_table:Dictionary = _get_parts_needed_for_current_animation()
	var pending_deactivation_table:Dictionary
	var recycle_candidates:Dictionary
	#Try to recycle as many currently created parts as possible.
	#Go through all currently active parts, checking to see if the type and name match
	#what's in the requirement dictionary. If both type and name match, use it as it is.
	#If only type matches, then rename the part that'd otherwise be unused
	for active_part_type in _active_char_parts.keys():
		if active_part_type in requirements_table:
			var current_type_required_parts:Array = requirements_table[active_part_type]
			var current_type_active_parts:Array = _active_char_parts[active_part_type]
			for active_part in current_type_active_parts:
				if active_part.name in current_type_required_parts:
					requirements_table[active_part_type].erase(active_part.name)
					
				else:
					if not active_part_type in recycle_candidates:
						recycle_candidates[active_part_type] = []
					recycle_candidates[active_part_type].append(active_part)
		else:
			pending_deactivation_table[active_part_type] = _active_char_parts[active_part_type]
		if requirements_table[active_part_type].empty():
			requirements_table.erase(active_part_type)
			
	#Phase 2, handling the recylcables
	for recyclable_part_type in recycle_candidates.keys():
		if requirements_table.has(recyclable_part_type):
			var recyclable_parts:Array = recycle_candidates[recyclable_part_type]
			var current_required_type_names:Array = requirements_table[recyclable_part_type]
			for needed_part_name in current_required_type_names:
				if not recyclable_parts.empty():
					var reuse_candidate:CharacterPart = recyclable_parts.pop_front()
					reuse_candidate.name = requirements_table[recyclable_part_type].pop_front()
				else:
					break
			#Check to make sure that the recyclable_parts array is empty.
			if pending_deactivation_table.has(recyclable_part_type):
				while not recyclable_parts.empty():
					pending_deactivation_table[recyclable_part_type].append(recyclable_parts.pop_front())
			else:
				pending_deactivation_table[recyclable_part_type] = recycle_candidates[recyclable_part_type]
		else:
			var recyclable_parts:Array = recycle_candidates[recyclable_part_type]
			#Can deactivate all parts of this type
			if pending_deactivation_table.has(recyclable_part_type):
				while not recyclable_parts.empty():
					pending_deactivation_table[recyclable_part_type].append(recyclable_parts.pop_front())
			else:
				pending_deactivation_table[recyclable_part_type] = recycle_candidates[recyclable_part_type]
		recycle_candidates.erase(recyclable_part_type)
		if requirements_table[recyclable_part_type].empty():
			requirements_table.erase(recyclable_part_type)
	#It's possible but improbable that by the end of phase 2 that all requirements are met. Still check to see 
	#if we can return early though.
	if requirements_table.empty():
		_deactivate_character_parts(pending_deactivation_table)
		return
		
	#Phase 3, still missing parts. Activate some previously inactive parts
	var parts_to_reactivate:Array = []
	for required_part_type in requirements_table.keys():
		if required_part_type in _standby_char_parts:
			var standby_parts:Array = _standby_char_parts[required_part_type]
			var required_names:Array = requirements_table[required_part_type]
			while not standby_parts.empty() and not required_names.empty():
				var standby_part:CharacterPart = standby_parts.pop_front()
				standby_part.name = required_names.pop_front()
				parts_to_reactivate.append(standby_part)
		if requirements_table[required_part_type].empty():
			requirements_table.erase(required_part_type)
	
	_reactivate_character_parts(parts_to_reactivate)
	
	if requirements_table.empty():
		_deactivate_character_parts(pending_deactivation_table)
		return
		
	#Phase 4, still don't have what's needed. Send a request to the parts factory for any remaining parts to be created.
	var part_create_list:Array = []
	for remaining_required_type in requirements_table.keys():
		part_create_list.append(remaining_required_type)
		for remaining_part_name in requirements_table[remaining_required_type]:
			part_create_list.append(remaining_part_name)
		part_create_list.append(null)
		
	_send_task_for_parts_creation.call_func(part_create_list, self)
	_deactivate_character_parts(pending_deactivation_table)


func _deactivate_character_parts(deactivate_table:Dictionary)->void:
	for deactivate_type in deactivate_table.keys():
		if not deactivate_type in _standby_char_parts.keys():
			_standby_char_parts[deactivate_type] = Array()
		if not deactivate_type in _active_char_parts.keys():
			_active_char_parts[deactivate_type] = Array()
		var standby_type_arr:Array = _standby_char_parts[deactivate_type]
		var active_type_arr:Array = _active_char_parts[deactivate_type]
		for deactivating_part in deactivate_table[deactivate_type]:
			_parts_root.remove_child(deactivating_part)
			deactivating_part.name = _UNUSED_STR % [deactivating_part.part_type, deactivating_part.get_instance_id()]
			standby_type_arr.append(deactivating_part)
			active_type_arr.erase(deactivating_part)

func _reactivate_character_parts(reactivation_list:Array):
	for reactivating_part in reactivation_list:
		var part_type:String = reactivating_part.part_type
		if not part_type in _active_char_parts:
			_active_char_parts[part_type] = Array()
		_standby_char_parts[part_type].erase(reactivating_part)
		_active_char_parts[part_type].append(reactivating_part)
	add_character_parts(reactivation_list)

func get_active_parts_listing()->Dictionary:
	return _active_char_parts

func _get_parts_needed_for_current_animation()->Dictionary:
	return _animTree.get_part_requirments_for_current_animation()

func start_animation_playback():
	if !_animTree.active:
		_animTree.active = true
	update_parts_used()
	
		#var needs = _animTree.get_track_requirements()
		
