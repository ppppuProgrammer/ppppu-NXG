extends Node

var func_add_gui_scene:FuncRef
var func_remove_gui_scene:FuncRef
var func_remove_all_gui_scenes:FuncRef

var _current_phase:GamePhase = null
var _phase_change_pending:bool = false
var _next_phase:GamePhase = null
var _next_phase_data:Dictionary = {}
#signal world_phase_changed

func is_next_phase_queued()->bool:
	return (_phase_change_pending)

func set_world_phase(game_phase:GamePhase, phase_change_data:Dictionary={}):
	if _next_phase:
		if _next_phase == game_phase:
			printerr("Warning: %s is already queued to be switched to." % game_phase)
		else:
			printerr("Warning: phase \"%s could not be queued. phase %s is currently queued."
				% [game_phase, _next_phase])
		return
	if game_phase != _current_phase:
		_next_phase = game_phase
		_next_phase_data = phase_change_data
		_phase_change_pending = true
#		call_deferred("_deferred_set_world_phase", game_phase, phase_change_data)
	
func switch_phase():
	if _current_phase:
		remove_child(_current_phase.get_scene())
		_current_phase.cleanup()
	if _next_phase:
		var phase_scene = _next_phase.get_scene()
		_next_phase.setup_scene_funcrefs(func_add_gui_scene, func_remove_gui_scene, func_remove_all_gui_scenes)
		_next_phase.preconfigure_phase(_next_phase_data)
		add_child(phase_scene)
		_next_phase.configure_phase(_next_phase_data)
	_current_phase = _next_phase
	_next_phase = null
	_next_phase_data = {}
	_phase_change_pending = false
	
func get_current_phase_name():
	if not _current_phase:
		return "NULL"
	else:
		return _current_phase.get_name()
		
func add_gui_scene(scene:Control):
	func_add_gui_scene.call_func(scene)
	
