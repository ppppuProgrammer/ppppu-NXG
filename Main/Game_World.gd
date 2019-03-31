extends Node

var func_add_gui_scene:FuncRef
var func_remove_gui_scene:FuncRef
var func_remove_all_gui_scenes:FuncRef

var _current_phase:Node = null

func set_world_phase(phase_scene:Node):
	if phase_scene == _current_phase:
		return
	if _current_phase:
		remove_child(_current_phase)
	add_child(phase_scene)
	_current_phase = phase_scene
	# guis should be phase specific in most cases. 
	#Refactor later if needed.
	func_remove_all_gui_scenes.call_func()
		
func add_gui_scene(scene:Control):
	func_add_gui_scene.call_func(scene)
	
